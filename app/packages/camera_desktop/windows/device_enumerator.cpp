#include "device_enumerator.h"

#include <mfapi.h>
#include <mfidl.h>
#include <wrl/client.h>

// After the Media Foundation headers, so only the property keys are defined here.
#include <cfgmgr32.h>
#include <initguid.h>
#include <devpkey.h>

#include <codecvt>
#include <locale>
#include <string>

#include "fake_camera_source.h"
#include "logging.h"

using Microsoft::WRL::ComPtr;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(),
                                 nullptr, 0);
  std::wstring w(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(),
                      w.data(), size);
  return w;
}

// The panel the device sits on, from the ACPI _PLD buffer in
// DEVPKEY_Device_PhysicalDeviceLocation: bits 67..69, 4 front, 5 back. -1 when
// the firmware does not say (USB cameras).
static int PanelFor(const std::wstring& symbolic_link) {
  WCHAR instance_id[MAX_DEVICE_ID_LEN] = {};
  ULONG size = sizeof(instance_id);
  DEVPROPTYPE type = 0;
  if (CM_Get_Device_Interface_PropertyW(symbolic_link.c_str(), &DEVPKEY_Device_InstanceId, &type,
                                        reinterpret_cast<PBYTE>(instance_id), &size, 0) != CR_SUCCESS ||
      type != DEVPROP_TYPE_STRING) {
    return -1;
  }
  DEVINST devinst = 0;
  if (CM_Locate_DevNodeW(&devinst, instance_id, CM_LOCATE_DEVNODE_NORMAL) != CR_SUCCESS) return -1;
  BYTE pld[64] = {};
  size = sizeof(pld);
  if (CM_Get_DevNode_PropertyW(devinst, &DEVPKEY_Device_PhysicalDeviceLocation, &type, pld, &size, 0) !=
          CR_SUCCESS ||
      type != DEVPROP_TYPE_BINARY || size < 9) {
    return -1;
  }
  return (pld[8] >> 3) & 0x7;
}

static bool ConsentDenied(HKEY root, const wchar_t* path) {
  wchar_t value[16] = {};
  DWORD size = sizeof(value);
  if (RegGetValueW(root, path, L"Value", RRF_RT_REG_SZ, nullptr, value, &size) != ERROR_SUCCESS) {
    return false;
  }
  return wcscmp(value, L"Deny") == 0;
}

// ---------------------------------------------------------------------------
// DeviceEnumerator
// ---------------------------------------------------------------------------

bool DeviceEnumerator::CameraAccessDenied() {
  static const wchar_t kWebcam[] =
      L"Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam";
  static const wchar_t kNonPackaged[] =
      L"Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam\\NonPackaged";
  return ConsentDenied(HKEY_LOCAL_MACHINE, kWebcam) || ConsentDenied(HKEY_CURRENT_USER, kWebcam) ||
         ConsentDenied(HKEY_CURRENT_USER, kNonPackaged);
}

std::vector<DeviceInfo> DeviceEnumerator::EnumerateVideoDevices() {
  DebugLog("DeviceEnumerator::EnumerateVideoDevices start");
  std::vector<DeviceInfo> result;

#ifdef CAMERA_DESKTOP_FAKE_CAMERA
  result.push_back({kFakeCameraFriendlyName, kFakeCameraSymbolicLink});
#endif

  ComPtr<IMFAttributes> attrs;
  if (FAILED(MFCreateAttributes(&attrs, 1))) {
    DebugLog("DeviceEnumerator::EnumerateVideoDevices MFCreateAttributes failed");
    return result;
  }
  if (FAILED(attrs->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID))) {
    DebugLog("DeviceEnumerator::EnumerateVideoDevices SetGUID failed");
    return result;
  }

  IMFActivate** devices = nullptr;
  UINT32 count = 0;
  if (FAILED(MFEnumDeviceSources(attrs.Get(), &devices, &count))) {
    DebugLog("DeviceEnumerator::EnumerateVideoDevices MFEnumDeviceSources failed");
    return result;
  }

  DebugLog("DeviceEnumerator::EnumerateVideoDevices found " +
           std::to_string(count) + " device(s)");

  for (UINT32 i = 0; i < count; ++i) {
    WCHAR* friendly_name = nullptr;
    UINT32 fn_len = 0;
    WCHAR* symbolic_link = nullptr;
    UINT32 sl_len = 0;

    devices[i]->GetAllocatedString(MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME,
                                   &friendly_name, &fn_len);
    devices[i]->GetAllocatedString(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
        &symbolic_link, &sl_len);

    if (friendly_name && symbolic_link) {
      DeviceInfo info{friendly_name, symbolic_link};
      const int panel = PanelFor(info.symbolic_link);
      if (panel == 4) {
        info.lens_direction = 0;
        info.built_in = true;
      } else if (panel == 5) {
        info.lens_direction = 1;
      }
      result.push_back(info);
      DebugLog("DeviceEnumerator: device[" + std::to_string(i) + "] name=" +
               WideToUtf8(friendly_name) +
               " symlink=" + WideToUtf8(symbolic_link));
    } else {
      DebugLog("DeviceEnumerator: device[" + std::to_string(i) +
               "] skipped (missing friendly_name=" +
               std::string(friendly_name ? "ok" : "null") +
               " or symbolic_link=" +
               std::string(symbolic_link ? "ok" : "null") + ")");
    }

    if (friendly_name) CoTaskMemFree(friendly_name);
    if (symbolic_link) CoTaskMemFree(symbolic_link);
    devices[i]->Release();
  }

  CoTaskMemFree(devices);
  DebugLog("DeviceEnumerator::EnumerateVideoDevices returning " +
           std::to_string(result.size()) + " valid device(s)");
  return result;
}

std::wstring DeviceEnumerator::FindSymbolicLink(const std::string& name) {
  // Name format: "Friendly Name (symbolic_link)"
  // Extract the part inside the last pair of parentheses.
  auto last_open = name.rfind('(');
  auto last_close = name.rfind(')');
  if (last_open == std::string::npos || last_close == std::string::npos ||
      last_close < last_open) {
    return {};
  }
  std::string sym_utf8 = name.substr(last_open + 1, last_close - last_open - 1);
  return Utf8ToWide(sym_utf8);
}

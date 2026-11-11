#pragma once

#include <string>
#include <vector>

struct DeviceInfo {
  std::wstring friendly_name;
  std::wstring symbolic_link;
  // 0 front, 1 back, 2 external, from the panel the firmware reports.
  int lens_direction = 2;
  // On the front panel: the laptop's own camera.
  bool built_in = false;
};

class DeviceEnumerator {
 public:
  /// Returns all connected video capture devices.
  static std::vector<DeviceInfo> EnumerateVideoDevices();

  /// Whether Windows privacy settings deny desktop apps the camera
  /// (Settings > Privacy > Camera). Reads the consent store; opens nothing.
  static bool CameraAccessDenied();

  /// Finds the symbolic link for a camera whose dart-side name is |name|.
  /// The name format is "Friendly Name (symbolic_link)".
  /// Returns empty string if not found.
  static std::wstring FindSymbolicLink(const std::string& name);
};

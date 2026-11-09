#include "tray.h"

#include <shellapi.h>
#include <windowsx.h>

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstring>
#include <memory>

namespace {
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayId = 1;
constexpr DWORD kEndSessionWaitMs = 20000;
constexpr size_t kTooltipChars = 127;

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(std::string(key)));
  if (it == map.end() || it->second.IsNull()) return nullptr;
  return &it->second;
}

std::string GetString(const EncodableMap& map, const char* key) {
  const EncodableValue* v = Find(map, key);
  const auto* s = v ? std::get_if<std::string>(v) : nullptr;
  return s ? *s : std::string();
}

int GetInt(const EncodableMap& map, const char* key) {
  const EncodableValue* v = Find(map, key);
  if (v == nullptr) return 0;
  if (const auto* i = std::get_if<int32_t>(v)) return *i;
  if (const auto* l = std::get_if<int64_t>(v)) return static_cast<int>(*l);
  return 0;
}

// A missing or null value is |fallback|.
bool GetBool(const EncodableMap& map, const char* key, bool fallback) {
  const EncodableValue* v = Find(map, key);
  const auto* b = v ? std::get_if<bool>(v) : nullptr;
  return b ? *b : fallback;
}

std::wstring Widen(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int n = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
  if (n <= 0) return std::wstring();
  std::wstring out(static_cast<size_t>(n), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), out.data(), n);
  return out;
}

// The RGBA of an Img map as a top-down 32bpp DIB section, BGRA. Premultiplied for a menu
// bitmap; straight for an icon, whose alpha the shell blends itself.
HBITMAP BitmapFromImg(const EncodableMap& img, bool premultiply) {
  const int width = GetInt(img, "width");
  const int height = GetInt(img, "height");
  const EncodableValue* rgba_value = Find(img, "rgba");
  const auto* rgba = rgba_value ? std::get_if<std::vector<uint8_t>>(rgba_value) : nullptr;
  if (!rgba || width <= 0 || height <= 0 || width > 512 || height > 512 ||
      rgba->size() != static_cast<size_t>(width) * static_cast<size_t>(height) * 4) {
    return nullptr;
  }
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;  // top-down
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  info.bmiHeader.biCompression = BI_RGB;
  void* bits = nullptr;
  HBITMAP bitmap = ::CreateDIBSection(nullptr, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (bitmap == nullptr || bits == nullptr) return nullptr;
  auto* dst = static_cast<uint8_t*>(bits);
  const uint8_t* src = rgba->data();
  for (size_t i = 0, n = rgba->size(); i < n; i += 4) {
    uint32_t a = src[i + 3];
    uint32_t r = src[i], g = src[i + 1], b = src[i + 2];
    if (premultiply) {
      r = (r * a + 127) / 255;
      g = (g * a + 127) / 255;
      b = (b * a + 127) / 255;
    }
    dst[i] = static_cast<uint8_t>(b);
    dst[i + 1] = static_cast<uint8_t>(g);
    dst[i + 2] = static_cast<uint8_t>(r);
    dst[i + 3] = static_cast<uint8_t>(a);
  }
  return bitmap;
}

HICON IconFromImg(const EncodableMap& img) {
  HBITMAP color = BitmapFromImg(img, false);
  if (color == nullptr) return nullptr;
  BITMAP bm{};
  ::GetObjectW(color, sizeof(bm), &bm);
  // The mask is ignored for a 32bpp colour bitmap with alpha, but must exist.
  std::vector<uint8_t> zeros(static_cast<size_t>((bm.bmWidth + 15) / 16 * 2) * bm.bmHeight, 0);
  HBITMAP mask = ::CreateBitmap(bm.bmWidth, bm.bmHeight, 1, 1, zeros.data());
  HICON icon = nullptr;
  if (mask != nullptr) {
    ICONINFO info{};
    info.fIcon = TRUE;
    info.hbmColor = color;
    info.hbmMask = mask;
    icon = ::CreateIconIndirect(&info);
    ::DeleteObject(mask);
  }
  ::DeleteObject(color);
  return icon;
}

// Dark menus when the system theme is dark: best effort, only from Windows 10 1903 (build
// 18362) where uxtheme's ordinal 135 is SetPreferredAppMode. Anything else falls back silently.
void AllowDarkMenus() {
  static bool done = false;
  if (done) return;
  done = true;
  using RtlGetVersionFn = LONG(WINAPI*)(OSVERSIONINFOW*);
  HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  auto rtl = ntdll ? reinterpret_cast<RtlGetVersionFn>(::GetProcAddress(ntdll, "RtlGetVersion"))
                   : nullptr;
  OSVERSIONINFOW version{};
  version.dwOSVersionInfoSize = sizeof(version);
  if (rtl == nullptr || rtl(&version) != 0 || version.dwBuildNumber < 18362) return;
  HMODULE uxtheme = ::LoadLibraryExW(L"uxtheme.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  if (uxtheme == nullptr) return;
  using SetPreferredAppModeFn = int(WINAPI*)(int);
  auto set_mode = reinterpret_cast<SetPreferredAppModeFn>(
      ::GetProcAddress(uxtheme, MAKEINTRESOURCEA(135)));
  if (set_mode != nullptr) set_mode(1);  // AllowDark
}
}  // namespace

Tray::~Tray() { Shutdown(); }

void Tray::Init(HWND window, flutter::BinaryMessenger* messenger) {
  window_ = window;
  taskbar_created_ = ::RegisterWindowMessageW(L"TaskbarCreated");
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "epic_wallet/tray", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        HandleCall(call, result.get());
      });
}

void Tray::Shutdown() {
  Remove();
  FreeItems(&items_);
  FreeItems(&pending_);
  if (icon_ != nullptr) {
    ::DestroyIcon(icon_);
    icon_ = nullptr;
  }
  channel_ = nullptr;
}

void Tray::HandleCall(const flutter::MethodCall<EncodableValue>& call,
                      flutter::MethodResult<EncodableValue>* result) {
  const std::string& method = call.method_name();
  if (method == "metrics") {
    UINT dpi = window_ ? ::GetDpiForWindow(window_) : 96;
    int px = ::GetSystemMetricsForDpi(SM_CXSMICON, dpi == 0 ? 96 : dpi);
    result->Success(EncodableValue(EncodableMap{{EncodableValue("icon"), EncodableValue(px)},
                                                {EncodableValue("menuIcon"), EncodableValue(px)}}));
  } else if (method == "set") {
    const auto* args = call.arguments() ? std::get_if<EncodableMap>(call.arguments()) : nullptr;
    if (args == nullptr || !Set(*args)) {
      result->Error("bad_args", "set needs an icon, a tooltip and items");
      return;
    }
    // No notification area took the icon (no Explorer in this session): the window must not
    // hide without a way back.
    if (!shown_) {
      result->Error("no_tray", "the notification area did not take the icon");
      return;
    }
    result->Success();
  } else if (method == "remove") {
    Remove();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

bool Tray::Set(const EncodableMap& args) {
  const EncodableValue* icon_value = Find(args, "icon");
  const auto* icon_map = icon_value ? std::get_if<EncodableMap>(icon_value) : nullptr;
  if (icon_map == nullptr) return false;
  HICON icon = IconFromImg(*icon_map);
  if (icon == nullptr) return false;

  std::wstring tip = Widen(GetString(args, "tooltip"));
  if (tip.size() > kTooltipChars) tip.resize(kTooltipChars);

  std::vector<Item> parsed;
  const EncodableValue* items_value = Find(args, "items");
  const auto* list = items_value ? std::get_if<EncodableList>(items_value) : nullptr;
  if (list != nullptr) {
    for (const EncodableValue& entry : *list) {
      const auto* map = std::get_if<EncodableMap>(&entry);
      if (map == nullptr) continue;
      Item item;
      std::string kind = GetString(*map, "kind");
      if (kind == "separator") {
        item.kind = Item::Kind::kSeparator;
      } else if (kind == "header") {
        item.kind = Item::Kind::kHeader;
      } else if (kind == "status") {
        item.kind = Item::Kind::kStatus;
      }
      item.id = GetString(*map, "id");
      item.label = Widen(GetString(*map, "label"));
      item.enabled = GetBool(*map, "enabled", true);
      if (Find(*map, "checked") != nullptr) {
        item.has_check = true;
        item.checked = GetBool(*map, "checked", false);
      }
      item.bold = GetBool(*map, "bold", false);
      const EncodableValue* img = Find(*map, "icon");
      const auto* img_map = img ? std::get_if<EncodableMap>(img) : nullptr;
      if (img_map != nullptr) item.icon = BitmapFromImg(*img_map, true);
      parsed.push_back(std::move(item));
    }
  }
  // A menu is open on the old items: the new ones wait for it to close.
  if (in_menu_) {
    FreeItems(&pending_);
    pending_ = std::move(parsed);
  } else {
    FreeItems(&items_);
    items_ = std::move(parsed);
  }

  HICON old = icon_;
  icon_ = icon;
  tooltip_ = tip;
  if (shown_) {
    NOTIFYICONDATAW data{sizeof(data)};
    data.hWnd = window_;
    data.uID = kTrayId;
    data.uFlags = NIF_ICON | NIF_TIP | NIF_SHOWTIP;
    data.hIcon = icon_;
    wcsncpy_s(data.szTip, tooltip_.c_str(), _TRUNCATE);
    ::Shell_NotifyIconW(NIM_MODIFY, &data);
  } else {
    AddIcon();
  }
  if (old != nullptr) ::DestroyIcon(old);
  return true;
}

void Tray::AddIcon() {
  if (window_ == nullptr || icon_ == nullptr) return;
  NOTIFYICONDATAW data{sizeof(data)};
  data.hWnd = window_;
  data.uID = kTrayId;
  data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
  data.uCallbackMessage = kTrayMessage;
  data.hIcon = icon_;
  wcsncpy_s(data.szTip, tooltip_.c_str(), _TRUNCATE);
  shown_ = ::Shell_NotifyIconW(NIM_ADD, &data) != FALSE;
  if (shown_) {
    data.uVersion = NOTIFYICON_VERSION_4;
    ::Shell_NotifyIconW(NIM_SETVERSION, &data);
  }
}

void Tray::Remove() {
  if (!shown_) return;
  NOTIFYICONDATAW data{sizeof(data)};
  data.hWnd = window_;
  data.uID = kTrayId;
  ::Shell_NotifyIconW(NIM_DELETE, &data);
  shown_ = false;
}

void Tray::FreeItems(std::vector<Item>* items) {
  for (Item& item : *items) {
    if (item.icon != nullptr) ::DeleteObject(item.icon);
  }
  items->clear();
}

void Tray::ShowMenu() {
  // A second right click while the menu runs, or a menu rebuilt under it, is not shown.
  if (in_menu_ || items_.empty()) return;
  in_menu_ = true;
  AllowDarkMenus();

  // |set| may arrive while the menu runs (TrackPopupMenuEx pumps messages): it lands in
  // |pending_|, so the bitmaps the menu shows stay alive.
  const std::vector<Item>& items = items_;

  HMENU menu = ::CreatePopupMenu();
  if (menu != nullptr) {
    for (size_t i = 0; i < items.size(); i++) {
      const Item& item = items[i];
      MENUITEMINFOW info{sizeof(info)};
      if (item.kind == Item::Kind::kSeparator) {
        info.fMask = MIIM_FTYPE;
        info.fType = MFT_SEPARATOR;
      } else {
        info.fMask = MIIM_ID | MIIM_STRING | MIIM_STATE;
        info.wID = static_cast<UINT>(i + 1);
        info.dwTypeData = const_cast<wchar_t*>(item.label.c_str());
        bool disabled = !item.enabled || item.kind == Item::Kind::kHeader ||
                        item.kind == Item::Kind::kStatus;
        info.fState = (disabled ? MFS_DISABLED : MFS_ENABLED) |
                      (item.checked ? MFS_CHECKED : MFS_UNCHECKED) |
                      (item.bold ? MFS_DEFAULT : 0);
        if (item.icon != nullptr) {
          info.fMask |= MIIM_BITMAP;
          info.hbmpItem = item.icon;
        }
      }
      ::InsertMenuItemW(menu, static_cast<UINT>(i), TRUE, &info);
    }

    POINT at{};
    ::GetCursorPos(&at);
    // Without the foreground the menu would not close on a click elsewhere.
    ::SetForegroundWindow(window_);
    UINT command = static_cast<UINT>(::TrackPopupMenuEx(
        menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, at.x, at.y, window_, nullptr));
    ::PostMessageW(window_, WM_NULL, 0, 0);
    ::DestroyMenu(menu);

    if (command >= 1 && command <= items.size() && !items[command - 1].id.empty() &&
        channel_ != nullptr) {
      channel_->InvokeMethod("activate",
                             std::make_unique<EncodableValue>(items[command - 1].id));
    }
  }
  in_menu_ = false;
  if (!pending_.empty()) {
    FreeItems(&items_);
    items_ = std::move(pending_);
    pending_.clear();
  }
}

void Tray::EndSession() {
  if (channel_ == nullptr) return;
  auto done = std::make_shared<bool>(false);
  auto finish = [done]() { *done = true; };
  channel_->InvokeMethod(
      "endSession", nullptr,
      std::make_unique<flutter::MethodResultFunctions<EncodableValue>>(
          [finish](const EncodableValue*) { finish(); },
          [finish](const std::string&, const std::string&, const EncodableValue*) { finish(); },
          [finish]() { finish(); }));

  // Dart's answer arrives through this thread's message loop.
  const ULONGLONG deadline = ::GetTickCount64() + kEndSessionWaitMs;
  while (!*done) {
    ULONGLONG now = ::GetTickCount64();
    if (now >= deadline) break;
    ::MsgWaitForMultipleObjects(0, nullptr, FALSE, static_cast<DWORD>(deadline - now),
                                QS_ALLINPUT);
    MSG msg;
    while (!*done && ::PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
      if (msg.message == WM_QUIT) {
        ::PostQuitMessage(static_cast<int>(msg.wParam));
        return;
      }
      ::TranslateMessage(&msg);
      ::DispatchMessageW(&msg);
    }
  }
}

std::optional<LRESULT> Tray::HandleMessage(HWND window, UINT message, WPARAM wparam,
                                           LPARAM lparam) {
  if (taskbar_created_ != 0 && message == taskbar_created_) {
    // Explorer restarted: its icons are gone. An icon removed (the window shown) stays gone.
    if (shown_) {
      shown_ = false;
      AddIcon();
    }
    return 0;
  }
  switch (message) {
    case kTrayMessage:
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          if (channel_ != nullptr) {
            channel_->InvokeMethod("click", nullptr);
          }
          break;
        case WM_CONTEXTMENU:
          ShowMenu();
          break;
      }
      return 0;
    case WM_QUERYENDSESSION:
      ::ShutdownBlockReasonCreate(window, L"Stopping the node");
      return TRUE;
    case WM_ENDSESSION:
      if (wparam != FALSE) {
        EndSession();
      }
      ::ShutdownBlockReasonDestroy(window);
      return 0;
  }
  return std::nullopt;
}

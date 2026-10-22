#include "window_placement.h"

#include <flutter_windows.h>

#include <algorithm>

namespace {

// Next to the data folder's name (%APPDATA%\com.blacktyger\EpicWallet). The registry, not a file
// there: the runner needs no file or JSON code, the data folder stays the wallet's alone, and a
// value is written whole.
constexpr const wchar_t kKey[] = L"Software\\com.blacktyger\\EpicWallet";
constexpr const wchar_t kValue[] = L"WindowPlacement";

// The first window, in logical px.
constexpr int kStartWidth = 1280;
constexpr int kStartHeight = 820;
// The smallest: the sidebar stays a rail (Bp.phone is 600 px, 750 at 125% interface scale).
constexpr int kMinWidth = 800;
constexpr int kMinHeight = 640;

// The saved value; a different size (another version) is ignored.
struct Saved {
  LONG left;
  LONG top;
  LONG right;
  LONG bottom;
  UINT dpi;
  UINT maximized;
};

int Scale(int logical, UINT dpi) { return MulDiv(logical, dpi, 96); }

RECT WorkArea(HMONITOR monitor) {
  MONITORINFO info{};
  info.cbSize = sizeof(info);
  ::GetMonitorInfoW(monitor, &info);
  return info.rcWork;
}

// |wanted| when it fits in |work|, else 80% of it, but not under |minimum| (itself within |work|).
LONG Fit(LONG wanted, LONG work, LONG minimum) {
  if (wanted <= work) return wanted;
  return std::max(work * 8 / 10, std::min(minimum, work));
}

WindowStart FirstRun() {
  HMONITOR primary = ::MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  const RECT work = WorkArea(primary);
  const UINT dpi = FlutterDesktopGetDpiForMonitor(primary);
  const LONG work_w = work.right - work.left;
  const LONG work_h = work.bottom - work.top;
  const LONG w = Fit(Scale(kStartWidth, dpi), work_w, Scale(kMinWidth, dpi));
  const LONG h = Fit(Scale(kStartHeight, dpi), work_h, Scale(kMinHeight, dpi));
  const LONG left = work.left + (work_w - w) / 2;
  const LONG top = work.top + (work_h - h) / 2;
  return WindowStart{RECT{left, top, left + w, top + h}, false};
}

}  // namespace

WindowStart InitialWindowPlacement() {
  Saved saved{};
  DWORD size = sizeof(saved);
  if (::RegGetValueW(HKEY_CURRENT_USER, kKey, kValue, RRF_RT_REG_BINARY, nullptr, &saved,
                     &size) != ERROR_SUCCESS ||
      size != sizeof(saved) || saved.right <= saved.left || saved.bottom <= saved.top) {
    return FirstRun();
  }
  RECT frame{saved.left, saved.top, saved.right, saved.bottom};
  // Its monitor was removed (or the layout changed): start as on the first run.
  HMONITOR monitor = ::MonitorFromRect(&frame, MONITOR_DEFAULTTONULL);
  if (monitor == nullptr) return FirstRun();
  const RECT work = WorkArea(monitor);
  const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  LONG w = frame.right - frame.left;
  LONG h = frame.bottom - frame.top;
  // The same logical size when the monitor's scale changed since.
  if (saved.dpi != 0 && saved.dpi != dpi) {
    w = MulDiv(w, dpi, saved.dpi);
    h = MulDiv(h, dpi, saved.dpi);
  }
  w = std::min(w, work.right - work.left);
  h = std::min(h, work.bottom - work.top);
  const LONG left = std::clamp(frame.left, work.left, work.right - w);
  const LONG top = std::clamp(frame.top, work.top, work.bottom - h);
  return WindowStart{RECT{left, top, left + w, top + h}, saved.maximized != 0};
}

void SaveWindowPlacement(HWND window, const RECT& normal) {
  if (normal.right <= normal.left || normal.bottom <= normal.top) return;
  bool maximized = ::IsZoomed(window) != FALSE;
  if (::IsIconic(window)) {
    WINDOWPLACEMENT placement{};
    placement.length = sizeof(placement);
    if (::GetWindowPlacement(window, &placement)) {
      maximized = (placement.flags & WPF_RESTORETOMAXIMIZED) != 0;
    }
  }
  HMONITOR monitor = ::MonitorFromRect(&normal, MONITOR_DEFAULTTONEAREST);
  const Saved saved{normal.left,
                    normal.top,
                    normal.right,
                    normal.bottom,
                    FlutterDesktopGetDpiForMonitor(monitor),
                    maximized ? 1u : 0u};
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kKey, kValue, REG_BINARY, &saved, sizeof(saved));
}

POINT MinimumWindowSize(HWND window) {
  const UINT dpi = FlutterDesktopGetDpiForHWND(window);
  const RECT work = WorkArea(::MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST));
  return POINT{std::min<LONG>(Scale(kMinWidth, dpi), work.right - work.left),
               std::min<LONG>(Scale(kMinHeight, dpi), work.bottom - work.top)};
}

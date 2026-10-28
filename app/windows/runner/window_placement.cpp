#include "window_placement.h"

#include <flutter_windows.h>

#include <algorithm>

namespace {

// Under the publisher and the app's name. The registry, not a file in the data folder
// (%USERPROFILE%\.epic_cash_desktop): the runner needs no file or JSON code, the data folder
// stays the wallet's alone, and a value is written whole.
constexpr const wchar_t kKey[] = L"Software\\BT Labs\\Epic Cash Desktop";
constexpr const wchar_t kValue[] = L"WindowPlacement";

// The first window: 80% of the work area each way, at most kMaxStart, at least kMin (logical
// px). The same rule as the app's lib/src/desktop/app/window_placement.dart (Linux, macOS).
constexpr int kSharePercent = 80;
constexpr int kMaxStartWidth = 1600;
constexpr int kMaxStartHeight = 1000;
// The smallest: the sidebar stays a rail (Bp.phone is 600 px, 750 at 125% interface scale) and
// Send shows the recipient, the amount and Review without scrolling (deskWindowMinSize).
constexpr int kMinWidth = 800;
constexpr int kMinHeight = 700;
// How far a saved frame may be larger than the work area and still be restored (logical px).
constexpr int kBorderSlack = 16;

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

// kSharePercent of |work|, at most |most|, at least |least|; |least| itself never over |work|.
LONG Fit(LONG work, LONG least, LONG most) {
  least = std::min(least, work);
  return std::clamp(work * kSharePercent / 100, least, std::max(least, most));
}

WindowStart FirstRunOn(HMONITOR monitor, bool maximized) {
  const RECT work = WorkArea(monitor);
  const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  const LONG work_w = work.right - work.left;
  const LONG work_h = work.bottom - work.top;
  const LONG w = Fit(work_w, Scale(kMinWidth, dpi), Scale(kMaxStartWidth, dpi));
  const LONG h = Fit(work_h, Scale(kMinHeight, dpi), Scale(kMaxStartHeight, dpi));
  const LONG left = work.left + (work_w - w) / 2;
  const LONG top = work.top + (work_h - h) / 2;
  return WindowStart{RECT{left, top, left + w, top + h}, maximized};
}

// On the monitor the pointer is on (where the user started the app), else the primary.
WindowStart FirstRun() {
  POINT cursor{0, 0};
  HMONITOR monitor = ::GetCursorPos(&cursor)
                         ? ::MonitorFromPoint(cursor, MONITOR_DEFAULTTOPRIMARY)
                         : ::MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  return FirstRunOn(monitor, false);
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
  const bool maximized = saved.maximized != 0;
  // Its middle on no monitor (one was removed, the layout changed): start as on the first run.
  const POINT middle{frame.left + (frame.right - frame.left) / 2,
                     frame.top + (frame.bottom - frame.top) / 2};
  HMONITOR monitor = ::MonitorFromPoint(middle, MONITOR_DEFAULTTONULL);
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
  const LONG work_w = work.right - work.left;
  const LONG work_h = work.bottom - work.top;
  // Larger than the work area now (a smaller monitor, a larger scale): the first-run size there.
  // The slack is the frame's invisible resize borders, which may stick out of the work area.
  const LONG slack = Scale(kBorderSlack, dpi);
  if (w > work_w + slack || h > work_h + slack) return FirstRunOn(monitor, maximized);
  // Within the work area, and at least the smallest window (an older version's was smaller).
  w = std::clamp(w, std::min<LONG>(Scale(kMinWidth, dpi), work_w), work_w);
  h = std::clamp(h, std::min<LONG>(Scale(kMinHeight, dpi), work_h), work_h);
  const LONG left = std::clamp(frame.left, work.left, work.right - w);
  const LONG top = std::clamp(frame.top, work.top, work.bottom - h);
  return WindowStart{RECT{left, top, left + w, top + h}, maximized};
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

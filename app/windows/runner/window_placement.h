#ifndef RUNNER_WINDOW_PLACEMENT_H_
#define RUNNER_WINDOW_PLACEMENT_H_

#include <windows.h>

// Where the window opens and what it remembers: its size, position and maximised state, kept in
// HKCU\Software\BT Labs\Epic Cash Desktop (value "WindowPlacement"), all in physical pixels.

struct WindowStart {
  RECT frame;
  bool maximized;
};

// The saved placement, moved onto the work area of its monitor; without one (first run) or when
// its monitor is gone, 80% of the work area (at most 1600x1000, at least 800x700 logical px)
// centred on the monitor the pointer is on.
WindowStart InitialWindowPlacement();

// Saves |normal| (the window's frame when neither maximised nor minimised, in screen
// coordinates) and whether |window| is maximised or restores to maximised.
void SaveWindowPlacement(HWND window, const RECT& normal);

// The smallest window that keeps the desktop layout (800x700 logical px), at |window|'s DPI and
// never larger than its monitor's work area.
POINT MinimumWindowSize(HWND window);

#endif  // RUNNER_WINDOW_PLACEMENT_H_

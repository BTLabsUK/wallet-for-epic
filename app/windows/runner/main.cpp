#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"
#include "window_placement.h"

namespace {
// The window's title, also how a second start finds the first window. The app keeps it:
// MaterialApp's title (lib/src/app_info.dart appName) is the same text.
constexpr const wchar_t kWindowTitle[] = L"Epic Cash Desktop";
// Named after the data folder (%APPDATA%\com.blacktyger\EpicWallet).
constexpr const wchar_t kSingleInstanceMutex[] = L"Local\\com.blacktyger.EpicWallet.single";
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // One window per user session: a second start brings the first window to the front and
  // ends, so two processes never open the same wallet files.
  ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND first = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", kWindowTitle);
    if (first != nullptr) {
      if (::IsIconic(first)) ::ShowWindow(first, SW_RESTORE);
      ::SetForegroundWindow(first);
    }
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Skia by default: on Flutter 3.47 Impeller (its Windows default) draws light text thinner than
  // Skia, and neither renders ClearType (docs/desktop-ui.md, "Text on Windows"). --impeller opts
  // in, to compare on a given machine; --skia is accepted and means the default.
  flutter::ImpellerSwitch renderer = flutter::ImpellerSwitch::Disabled;
  for (const std::string& arg : command_line_arguments) {
    if (arg == "--impeller") {
      renderer = flutter::ImpellerSwitch::Enabled;
    } else if (arg == "--skia") {
      renderer = flutter::ImpellerSwitch::Disabled;
    }
  }
  project.set_impeller_switch(renderer);

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Where it was last time, or a first-run size centred on the primary monitor.
  const WindowStart start = InitialWindowPlacement();
  if (!window.Create(kWindowTitle, start.frame, start.maximized)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

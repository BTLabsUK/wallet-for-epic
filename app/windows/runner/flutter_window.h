#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // WM_COPYDATA's dwData for an epiccash:// link a second start hands over (main.cpp).
  static constexpr ULONG_PTR kLinkCopyDataId = 0x45504943;  // "EPIC"
  // The longest link taken, as the Dart side (lib/src/scan/incoming_link.dart).
  static constexpr size_t kMaxLinkChars = 4096;

  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // epic_wallet/incoming_link: a link opened while the app runs, handed to Dart; one Dart did
  // not take yet waits in |pending_link_| for its takePending.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> link_channel_;
  std::string pending_link_;
  void DeliverLink(const std::string& link);
};

#endif  // RUNNER_FLUTTER_WINDOW_H_

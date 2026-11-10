#ifndef RUNNER_TRAY_H_
#define RUNNER_TRAY_H_

#include <windows.h>

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

// The notification-area icon and its menu, driven over epic_wallet/tray (the Dart side:
// lib/src/desktop/app/tray/tray_windows.dart). Also holds the session end: Windows asks the
// app to stop the node before it logs off or shuts down.
class Tray {
 public:
  Tray() = default;
  ~Tray();

  // Registers the channel; |window| is the top-level window that owns the icon.
  void Init(HWND window, flutter::BinaryMessenger* messenger);

  // Removes the icon and frees what it holds. Safe to call twice.
  void Shutdown();

  // Handles the tray's window messages; nullopt for any other.
  std::optional<LRESULT> HandleMessage(HWND window, UINT message, WPARAM wparam, LPARAM lparam);

 private:
  struct Item {
    enum class Kind { kItem, kSeparator, kHeader, kStatus };
    Kind kind = Kind::kItem;
    std::string id;
    std::wstring label;
    bool enabled = true;
    bool has_check = false;
    bool checked = false;
    bool bold = false;
    // Premultiplied BGRA, top-down; null for no icon. Owned by the item.
    HBITMAP icon = nullptr;
  };

  void HandleCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                  flutter::MethodResult<flutter::EncodableValue>* result);
  bool Set(const flutter::EncodableMap& args);
  void Remove();
  void AddIcon();
  void ShowMenu();
  static void FreeItems(std::vector<Item>* items);
  void EndSession();

  HWND window_ = nullptr;
  UINT taskbar_created_ = 0;
  bool shown_ = false;
  HICON icon_ = nullptr;
  std::wstring tooltip_;
  std::vector<Item> items_;
  std::vector<Item> pending_;
  bool in_menu_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_TRAY_H_

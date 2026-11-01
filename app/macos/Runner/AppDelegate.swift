import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // epiccash:// links (CFBundleURLTypes in Info.plist): a cold start's arrive before the window
  // and its channel exist, and wait in IncomingLink.shared for Dart's takePending.
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.scheme?.lowercased() == "epiccash" {
      IncomingLink.shared.deliver(url.absoluteString)
    }
  }
}

/// Invite links another app opened, handed to Dart on `epic_wallet/incoming_link`
/// (lib/src/invite_links.dart) as the iOS runner does: `link` with the text while Dart listens,
/// else held as the one pending link for `takePending`.
final class IncomingLink: NSObject {
  static let shared = IncomingLink()
  private static let maxLinkChars = 4096
  private var channel: FlutterMethodChannel?
  private var pending: String?

  func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "epic_wallet/incoming_link", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePending" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.pending)
      self?.pending = nil
    }
    self.channel = channel
  }

  func deliver(_ link: String) {
    guard link.count <= Self.maxLinkChars else { return }
    pending = link
    channel?.invokeMethod("link", arguments: link) { [weak self] reply in
      // Dart took it unless the call failed or nothing listens yet.
      if reply is FlutterError || (reply as? NSObject) === FlutterMethodNotImplemented {
        return
      }
      if self?.pending == link { self?.pending = nil }
    }
  }
}

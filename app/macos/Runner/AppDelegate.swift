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

  // epic: and epiccash: links (CFBundleURLTypes in Info.plist): a cold start's arrive before the window
  // and its channel exist, and wait in IncomingLink.shared for Dart's takePending.
  override func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where ["epic", "epiccash"].contains(url.scheme?.lowercased()) {
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

/// The app from before the rename ("Epic Cash Desktop.app", one of our old bundle ids) left in
/// /Applications or ~/Applications next to this one, on `epic_wallet/old_app`
/// (lib/src/desktop/app/old_app_offer.dart). `find` gives its path or nil; `trash` checks again
/// and moves it to the Bin, never deletes it. The data folder is not touched.
enum OldApp {
  private static let bundleName = "Epic Cash Desktop.app"
  private static let oldIds: Set<String> = ["uk.btlabs.epiccash.desktop", "uk.btlabs.epiccashwallet.macos"]
  private static var channel: FlutterMethodChannel?

  static func attach(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "epic_wallet/old_app", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "find":
        result(OldApp.find()?.path)
      case "trash":
        guard let path = call.arguments as? String else {
          result("refused")
          return
        }
        result(OldApp.trash(path))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    OldApp.channel = channel
  }

  /// /Applications and ~/Applications.
  private static func folders() -> [URL] {
    return [
      URL(fileURLWithPath: "/Applications", isDirectory: true),
      FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
    ].map { $0.resolvingSymlinksInPath().standardizedFileURL }
  }

  /// The two places the old app can be: /Applications/Epic Cash Desktop.app and
  /// ~/Applications/Epic Cash Desktop.app.
  private static func candidates() -> [URL] {
    return folders().map { $0.appendingPathComponent(bundleName, isDirectory: true).standardizedFileURL }
  }

  private static func find() -> URL? {
    return candidates().first(where: isOld)
  }

  /// True when [url] is a real folder (not a link) whose Info.plist has one of our old bundle
  /// ids, is not this running app, and is not running now; and this app is itself installed in
  /// one of the two folders (not opened from the DMG or a translocated copy), so the user is
  /// never left with no app installed.
  private static func isOld(_ url: URL) -> Bool {
    let me = Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL
    let myFolder = me.deletingLastPathComponent().standardizedFileURL.path
    guard folders().contains(where: { $0.path == myFolder }) else { return false }
    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
          let type = attrs[.type] as? FileAttributeType,
          type == .typeDirectory else {
      return false
    }
    guard url.resolvingSymlinksInPath().standardizedFileURL.path != me.path else { return false }
    let plist = url.appendingPathComponent("Contents/Info.plist", isDirectory: false)
    guard let info = NSDictionary(contentsOf: plist),
          let id = info["CFBundleIdentifier"] as? String,
          oldIds.contains(id) else {
      return false
    }
    return NSRunningApplication.runningApplications(withBundleIdentifier: id).isEmpty
  }

  /// "ok" when moved to the Bin, "refused" when [path] is not one of the candidates or no longer
  /// passes [isOld], "failed" when the move failed (the app stays where it is).
  private static func trash(_ path: String) -> String {
    let url = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    guard candidates().contains(where: { $0.path == url.path }), isOld(url) else {
      return "refused"
    }
    do {
      try FileManager.default.trashItem(at: url, resultingItemURL: nil)
      return "ok"
    } catch {
      NSLog("old app not moved to the Bin: %@", error.localizedDescription)
      return "failed"
    }
  }
}

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SecureScreen") {
      SecureScreen.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IncomingLink") {
      IncomingLink.register(with: registrar)
    }
  }
}

/// Covers the app's windows while the app is inactive, so the app switcher's snapshot never
/// shows a recovery phrase or a payment QR. Dart turns it on with `setSecure` (the payment QR)
/// or `hidePreview` (the phrase screens, which allow screenshots); iOS cannot block a
/// screenshot either way (`epic_wallet/secure_screen`, lib/src/secure_screen.dart).
final class SecureScreen: NSObject, FlutterPlugin {
  private var secure = false
  private var covers: [UIView] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SecureScreen()
    let channel = FlutterMethodChannel(
      name: "epic_wallet/secure_screen", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    let center = NotificationCenter.default
    center.addObserver(
      instance, selector: #selector(cover), name: UIScene.willDeactivateNotification, object: nil)
    center.addObserver(
      instance, selector: #selector(uncover), name: UIScene.didActivateNotification, object: nil)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "openAppSettings" {
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      return
    }
    if call.method == "keepScreenOn" {
      UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) == true
      result(nil)
      return
    }
    guard call.method == "setSecure" || call.method == "hidePreview" else {
      result(FlutterMethodNotImplemented)
      return
    }
    secure = (call.arguments as? Bool) == true
    if !secure { uncover() }
    result(nil)
  }

  @objc private func cover() {
    guard secure, covers.isEmpty else { return }
    for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
      for window in scene.windows where !window.isHidden {
        let view = UIView(frame: window.bounds)
        view.backgroundColor = .systemBackground
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(view)
        covers.append(view)
      }
    }
  }

  @objc private func uncover() {
    covers.forEach { $0.removeFromSuperview() }
    covers.removeAll()
  }
}

/// Payment links (epic:, epiccash:; CFBundleURLTypes in Info.plist) another app opened, handed to
/// Dart on `epic_wallet/incoming_link` (lib/src/scan/incoming_link.dart) as MainActivity.kt does:
/// `link` with the text while Dart listens, else held as the one pending link for `takePending`.
final class IncomingLink: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private var channel: FlutterMethodChannel?
  private var pending: String?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = IncomingLink()
    let channel = FlutterMethodChannel(
      name: "epic_wallet/incoming_link", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "takePending" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(pending)
    pending = nil
  }

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    // A cold start from a link: Dart asks with takePending once it listens.
    for context in connectionOptions?.urlContexts ?? [] where Self.isPaymentLink(context.url) {
      pending = context.url.absoluteString
    }
    return false
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where Self.isPaymentLink(context.url) {
      deliver(context.url.absoluteString)
      handled = true
    }
    return handled
  }

  private func deliver(_ link: String) {
    pending = link
    channel?.invokeMethod("link", arguments: link) { [weak self] reply in
      // Dart took it unless the call failed or nothing listens yet.
      if reply is FlutterError || (reply as? NSObject) === FlutterMethodNotImplemented {
        return
      }
      if self?.pending == link { self?.pending = nil }
    }
  }

  private static func isPaymentLink(_ url: URL) -> Bool {
    let scheme = url.scheme?.lowercased()
    return scheme == "epic" || scheme == "epiccash"
  }
}

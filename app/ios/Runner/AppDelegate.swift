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

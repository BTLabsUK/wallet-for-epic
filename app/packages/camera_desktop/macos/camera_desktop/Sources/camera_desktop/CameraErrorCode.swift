import AVFoundation

/// Error codes the plugin sends in FlutterError.code and in cameraError's
/// "code", the same on every desktop platform. They come from AVFoundation's
/// error codes and the device's state, never from a message's text.
enum CameraErrorCode {
    static let denied = "denied"
    static let busy = "busy"
    static let unplugged = "unplugged"
    static let noDevice = "no_device"
    static let noPicture = "no_picture"
    static let failed = "failed"

    /// The code for an error from AVFoundation, with the device for its state.
    static func classify(_ error: Error, device: AVCaptureDevice?) -> String {
        let ns = error as NSError
        if ns.domain == AVFoundationErrorDomain, let avCode = AVError.Code(rawValue: ns.code) {
            switch avCode {
            case .applicationIsNotAuthorizedToUseDevice:
                return denied
            case .deviceInUseByAnotherApplication:
                return busy
            case .deviceNotConnected, .deviceWasDisconnected:
                return unplugged
            default:
                break
            }
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .denied || status == .restricted { return denied }
        if let device = device {
            if !device.isConnected { return unplugged }
            if device.isInUseByAnotherApplication { return busy }
        }
        return failed
    }

    /// Details for the Dart side: the error's domain and code.
    static func details(_ error: Error) -> [String: Any] {
        let ns = error as NSError
        return ["domain": ns.domain, "code": ns.code]
    }
}

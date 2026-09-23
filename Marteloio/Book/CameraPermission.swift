import AVFoundation

/// Role: Book. Camera status for the ISBN read. The system alert is the only Allow.
enum CameraPermission {
    static var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static func request() async -> AVAuthorizationStatus {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        return status
    }
}

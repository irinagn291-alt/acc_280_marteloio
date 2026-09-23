import AVFoundation
import SwiftUI
import UIKit

/// Role: Book. Live ISBN read. Session stops on disappear and when the scene leaves active.
struct IsbnScanner: UIViewRepresentable {
    var isActive: Bool
    var onCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCode: onCode)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.update(onCode: onCode, isActive: isActive)
    }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    @MainActor
    final class Coordinator {
        private let engine = IsbnScanEngine()

        init(onCode: @escaping (String) -> Void) {
            engine.setHandler(onCode)
        }

        func attach(to view: PreviewView) {
            engine.attach(to: view)
        }

        func update(onCode: @escaping (String) -> Void, isActive: Bool) {
            engine.setHandler(onCode)
            if isActive {
                engine.start()
            } else {
                engine.stop()
            }
        }

        func stop() {
            engine.stop()
        }
    }
}

/// Capture work stays on sessionQueue. Delegate hops to the main actor.
final class IsbnScanEngine: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.marteloio.chart.scan")
    private let lock = NSLock()
    private var onCode: ((String) -> Void)?
    private var lastCode = ""
    private var lastAt = Date.distantPast
    private var configured = false

    func setHandler(_ handler: @escaping (String) -> Void) {
        lock.lock()
        onCode = handler
        lock.unlock()
    }

    @MainActor
    func attach(to view: PreviewView) {
        view.preview.session = session
        view.preview.videoGravity = .resizeAspectFill
    }

    func start() {
        sessionQueue.async { [self] in
            self.configureIfNeeded()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        let wanted: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce, .qr, .code128]
        output.metadataObjectTypes = wanted.filter { output.availableMetadataObjectTypes.contains($0) }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let values = metadataObjects.compactMap { object -> String? in
            (object as? AVMetadataMachineReadableCodeObject)?.stringValue
        }
        handle(values)
    }

    private func handle(_ values: [String]) {
        let now = Date()
        for raw in values {
            guard let code = IsbnDigits.extract(from: raw).first else { continue }
            if code == lastCode, now.timeIntervalSince(lastAt) < 1.2 { return }
            lastCode = code
            lastAt = now
            lock.lock()
            let handler = onCode
            lock.unlock()
            handler?(code)
            return
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var preview: AVCaptureVideoPreviewLayer {
        if let layer = layer as? AVCaptureVideoPreviewLayer {
            return layer
        }
        return AVCaptureVideoPreviewLayer()
    }
}

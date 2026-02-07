import SwiftUI

@MainActor
class CameraViewModel: ObservableObject {
    @Published var cameraService = CameraService()
    @Published var capturedImage: UIImage?
    @Published var showEditor = false
    @Published var showPermissionDenied = false

    var isAuthorized: Bool {
        cameraService.isAuthorized
    }

    var isFlashOn: Bool {
        cameraService.isFlashOn
    }

    func onAppear() {
        if cameraService.isAuthorized {
            cameraService.startSession()
        } else {
            showPermissionDenied = true
        }
    }

    func onDisappear() {
        cameraService.stopSession()
    }

    func capturePhoto() {
        Task {
            if let image = await cameraService.capturePhoto() {
                capturedImage = image
                showEditor = true
                AnalyticsService.shared.track(.photoCapture)
            }
        }
    }

    func toggleCamera() {
        cameraService.toggleCamera()
    }

    func toggleFlash() {
        cameraService.toggleFlash()
    }

    func resetCapture() {
        capturedImage = nil
        showEditor = false
        cameraService.startSession()
    }
}

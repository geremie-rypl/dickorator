import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isAuthorized {
                    cameraContent
                } else {
                    permissionDeniedView
                }
            }
            .navigationDestination(isPresented: $viewModel.showEditor) {
                if let image = viewModel.capturedImage {
                    EditorView(baseImage: image, onDismiss: {
                        viewModel.resetCapture()
                    })
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var cameraContent: some View {
        VStack(spacing: 0) {
            // Camera preview
            CameraPreviewView(cameraService: viewModel.cameraService)
                .ignoresSafeArea()

            // Controls
            controlBar
        }
    }

    private var controlBar: some View {
        HStack(spacing: 40) {
            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            // Capture button
            Button {
                viewModel.capturePhoto()
            } label: {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    )
            }

            // Camera flip
            Button {
                viewModel.toggleCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.8))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Dickerator needs camera access to photograph your banana masterpiece.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = uiView.bounds
            if previewLayer.superlayer == nil {
                uiView.layer.addSublayer(previewLayer)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(AppState())
}

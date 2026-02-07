import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel: EditorViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let onDismiss: () -> Void

    @State private var showShareSheet = false
    @State private var exportResult: ExportService.ExportResult?

    init(baseImage: UIImage, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditorViewModel(baseImage: baseImage))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar
                canvas
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showStickerPicker) {
            StickerPickerView { asset in
                viewModel.addSticker(asset)
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showShareSheet) {
            if let result = exportResult {
                ShareSheet(image: result.cleanImage) {
                    appState.onShare()
                }
            }
        }
        .overlay {
            if viewModel.isExporting {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                onDismiss()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 20) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(viewModel.canUndo ? .white : .gray)
                }
                .disabled(!viewModel.canUndo)

                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundColor(viewModel.canRedo ? .white : .gray)
                }
                .disabled(!viewModel.canRedo)
            }

            Spacer()

            Button {
                Task {
                    if let result = await viewModel.exportImages() {
                        exportResult = result
                        showShareSheet = true
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }

    private var canvas: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Base image
                Image(uiImage: viewModel.baseImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Layer 2: Filter overlay
                if let filter = viewModel.selectedFilter {
                    FilterOverlayView(filter: filter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Layer 3: Stickers
                ForEach($viewModel.stickers) { $sticker in
                    StickerView(
                        sticker: $sticker,
                        isSelected: viewModel.selectedStickerId == sticker.id,
                        onSelect: {
                            viewModel.selectSticker(sticker.id)
                        },
                        onDelete: {
                            viewModel.deleteSelectedSticker()
                        },
                        onBringToFront: {
                            viewModel.bringToFront(sticker.id)
                        }
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectSticker(nil)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            // Filter picker
            FilterPickerView(
                filters: viewModel.availableFilters.filter { !$0.isSecret || appState.isContentUnlocked($0.id) },
                selectedFilter: viewModel.selectedFilter,
                onSelect: { filter in
                    viewModel.selectFilter(filter)
                }
            )
            .environmentObject(appState)

            // Action buttons
            HStack(spacing: 40) {
                Button {
                    viewModel.showStickerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                            .font(.title2)
                        Text("Stickers")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }

                if viewModel.selectedStickerId != nil {
                    Button {
                        viewModel.deleteSelectedSticker()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("Delete")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.8))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let onShare: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onShare()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EditorView(baseImage: UIImage(systemName: "photo")!, onDismiss: {})
        .environmentObject(AppState())
}

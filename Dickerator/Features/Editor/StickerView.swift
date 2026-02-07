import SwiftUI

struct StickerView: View {
    @Binding var sticker: StickerState
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onBringToFront: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var body: some View {
        Image(sticker.asset.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .scaleEffect(sticker.transform.scale * currentScale)
            .rotationEffect(sticker.transform.rotation + currentRotation)
            .offset(
                x: sticker.transform.position.x + dragOffset.width,
                y: sticker.transform.position.y + dragOffset.height
            )
            .overlay(
                isSelected ? selectionOverlay : nil
            )
            .gesture(combinedGesture)
            .onTapGesture {
                onSelect()
                onBringToFront()
            }
            .zIndex(Double(sticker.zIndex))
    }

    private var selectionOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.red))
                }
            }
            Spacer()
        }
        .frame(width: 100 * sticker.transform.scale, height: 100 * sticker.transform.scale)
    }

    private var combinedGesture: some Gesture {
        SimultaneousGesture(
            SimultaneousGesture(dragGesture, magnificationGesture),
            rotationGesture
        )
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                sticker.transform.position.x += value.translation.width
                sticker.transform.position.y += value.translation.height
                dragOffset = .zero
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = value
            }
            .onEnded { value in
                sticker.transform.scale *= value
                sticker.transform.scale = max(0.3, min(3.0, sticker.transform.scale))
                currentScale = 1.0
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = value
            }
            .onEnded { value in
                sticker.transform.rotation += value
                currentRotation = .zero
            }
    }
}

struct StickerPickerView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (StickerAsset) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(availablePacks) { pack in
                        stickerPackSection(pack)
                    }
                }
                .padding()
            }
            .navigationTitle("Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var availablePacks: [StickerPack] {
        StickerPack.all.filter { pack in
            !pack.isSecret || appState.isContentUnlocked(pack.id)
        }
    }

    private func stickerPackSection(_ pack: StickerPack) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pack.name)
                    .font(.headline)

                if !pack.isFree && !appState.isContentUnlocked(pack.id) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                }
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 70), spacing: 12)
            ], spacing: 12) {
                ForEach(pack.stickers) { sticker in
                    let isLocked = !pack.isFree && !appState.isContentUnlocked(pack.id)

                    StickerThumbnail(
                        sticker: sticker,
                        isLocked: isLocked
                    ) {
                        if !isLocked {
                            onSelect(sticker)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct StickerThumbnail: View {
    let sticker: StickerAsset
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Image(sticker.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isLocked {
                    Color.black.opacity(0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StickerPickerView(onSelect: { _ in })
        .environmentObject(AppState())
}

import SwiftUI
import UIKit

struct StickerTransform: Equatable {
    var position: CGPoint
    var scale: CGFloat
    var rotation: Angle

    static let identity = StickerTransform(
        position: CGPoint(x: 150, y: 150),
        scale: 1.0,
        rotation: .zero
    )
}

struct StickerState: Identifiable, Equatable {
    let id: UUID
    let asset: StickerAsset
    var transform: StickerTransform
    var zIndex: Int
}

struct EditorSnapshot: Equatable {
    let selectedFilter: FilterItem?
    let stickers: [StickerState]
}

@MainActor
class EditorViewModel: ObservableObject {
    @Published var baseImage: UIImage
    @Published var selectedFilter: FilterItem?
    @Published var stickers: [StickerState] = []
    @Published var selectedStickerId: UUID?
    @Published var showFilterPicker = false
    @Published var showStickerPicker = false
    @Published var isExporting = false

    private var undoStack: [EditorSnapshot] = []
    private var redoStack: [EditorSnapshot] = []

    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    init(baseImage: UIImage) {
        self.baseImage = baseImage
    }

    // MARK: - Filters

    var availableFilters: [FilterItem] {
        FilterItem.all
    }

    func selectFilter(_ filter: FilterItem?) {
        saveSnapshot()
        selectedFilter = filter
        vibeCheck()
        if let filter = filter {
            AnalyticsService.shared.trackFilterUsage(filter.id)
        }
    }

    // MARK: - Stickers

    func addSticker(_ asset: StickerAsset) {
        saveSnapshot()
        let sticker = StickerState(
            id: UUID(),
            asset: asset,
            transform: .identity,
            zIndex: stickers.count
        )
        stickers.append(sticker)
        selectedStickerId = sticker.id
        vibeCheck()
        AnalyticsService.shared.trackStickerUsage(asset.id)
    }

    func updateStickerTransform(_ id: UUID, transform: StickerTransform) {
        guard let index = stickers.firstIndex(where: { $0.id == id }) else { return }
        stickers[index].transform = transform
    }

    func selectSticker(_ id: UUID?) {
        selectedStickerId = id
    }

    func deleteSelectedSticker() {
        guard let selectedId = selectedStickerId else { return }
        saveSnapshot()
        stickers.removeAll { $0.id == selectedId }
        selectedStickerId = nil
    }

    func bringToFront(_ id: UUID) {
        guard let index = stickers.firstIndex(where: { $0.id == id }) else { return }
        let maxZ = stickers.map(\.zIndex).max() ?? 0
        stickers[index].zIndex = maxZ + 1
    }

    // MARK: - Undo/Redo

    private func saveSnapshot() {
        let snapshot = EditorSnapshot(
            selectedFilter: selectedFilter,
            stickers: stickers
        )
        undoStack.append(snapshot)
        redoStack.removeAll()
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        let current = EditorSnapshot(
            selectedFilter: selectedFilter,
            stickers: stickers
        )
        redoStack.append(current)
        selectedFilter = snapshot.selectedFilter
        stickers = snapshot.stickers
    }

    func redo() {
        guard let snapshot = redoStack.popLast() else { return }
        let current = EditorSnapshot(
            selectedFilter: selectedFilter,
            stickers: stickers
        )
        undoStack.append(current)
        selectedFilter = snapshot.selectedFilter
        stickers = snapshot.stickers
    }

    // MARK: - Export

    func exportImages() async -> ExportService.ExportResult? {
        isExporting = true
        defer { isExporting = false }

        let filterOverlay: UIImage? = selectedFilter.flatMap { UIImage(named: $0.imageName) }

        let stickerData: [(image: UIImage, transform: CGAffineTransform)] = stickers.compactMap { sticker in
            guard let image = UIImage(named: sticker.asset.imageName) else { return nil }
            let t = sticker.transform
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: t.position.x, y: t.position.y)
            transform = transform.scaledBy(x: t.scale, y: t.scale)
            transform = transform.rotated(by: CGFloat(t.rotation.radians))
            return (image, transform)
        }

        let result = ExportService.shared.createExportImages(
            baseImage: baseImage,
            filterOverlay: filterOverlay,
            stickers: stickerData
        )

        vibeCheck()
        AnalyticsService.shared.track(.exportClean)

        return result
    }

    // MARK: - Haptics

    private func vibeCheck() {
        let intensity = min(1.0, 0.3 + Double(stickers.count) * 0.1)
        haptics.impactOccurred(intensity: intensity)
    }
}

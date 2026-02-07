import SwiftUI

struct FilterOverlayView: View {
    let filter: FilterItem

    var body: some View {
        Image(filter.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .allowsHitTesting(false)
    }
}

struct FilterPickerView: View {
    @EnvironmentObject var appState: AppState
    let filters: [FilterItem]
    let selectedFilter: FilterItem?
    let onSelect: (FilterItem?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // No filter option
                FilterThumbnail(
                    imageName: nil,
                    name: "None",
                    isSelected: selectedFilter == nil,
                    isLocked: false
                ) {
                    onSelect(nil)
                }

                ForEach(filters) { filter in
                    let isLocked = !filter.isFree &&
                                   !filter.isSecret &&
                                   !appState.isContentUnlocked(filter.id)

                    FilterThumbnail(
                        imageName: filter.imageName,
                        name: filter.name,
                        isSelected: selectedFilter?.id == filter.id,
                        isLocked: isLocked
                    ) {
                        if !isLocked || appState.isContentUnlocked(filter.id) {
                            onSelect(filter)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 100)
        .background(Color.black.opacity(0.8))
    }
}

struct FilterThumbnail: View {
    let imageName: String?
    let name: String
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if let imageName = imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "nosign")
                                    .foregroundColor(.gray)
                            )
                    }

                    if isLocked {
                        Color.black.opacity(0.5)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 3)
                )

                Text(name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterPickerView(
        filters: FilterItem.all,
        selectedFilter: nil,
        onSelect: { _ in }
    )
    .environmentObject(AppState())
}

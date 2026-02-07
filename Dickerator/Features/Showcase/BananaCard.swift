import SwiftUI

struct BananaCard: View {
    let post: BananaPost
    let onUpvote: () -> Void
    let onReport: () -> Void

    @State private var isRevealed = false
    @State private var showReportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with blur overlay
            ZStack {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView())

                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: isRevealed ? 0 : 20)

                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )

                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if !isRevealed {
                    VStack(spacing: 8) {
                        Image(systemName: "eye.slash.fill")
                            .font(.title)
                            .foregroundColor(.white)

                        Text("Tap to reveal")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isRevealed.toggle()
                }
            }

            // Post info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.username)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        if let filter = post.filterUsed {
                            Text(filter)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if post.stickerCount > 0 {
                            Text("\(post.stickerCount) stickers")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Actions
                HStack(spacing: 16) {
                    Button {
                        onUpvote()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("\(post.upvotes)")
                        }
                        .foregroundColor(.pink)
                    }

                    Menu {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label("Report", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if post.isFeatured {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text("Featured")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .confirmationDialog("Report Post", isPresented: $showReportSheet) {
            Button("Inappropriate Content", role: .destructive) {
                onReport()
            }
            Button("Spam", role: .destructive) {
                onReport()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FeaturedBananaCard: View {
    let post: BananaPost
    let onUpvote: () -> Void

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("Today's Featured")
                    .font(.headline)
            }

            ZStack {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: isRevealed ? 0 : 20)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if !isRevealed {
                    Text("Tap to reveal")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .onTapGesture {
                withAnimation {
                    isRevealed.toggle()
                }
            }

            HStack {
                Text("@\(post.username)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    onUpvote()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("\(post.upvotes)")
                    }
                    .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    VStack {
        BananaCard(
            post: BananaPost(
                userId: "123",
                username: "bananafan",
                imageURL: "https://example.com/image.jpg",
                filterUsed: "Neon Dreams",
                stickerCount: 3,
                upvotes: 42,
                createdAt: Date(),
                isFeatured: false
            ),
            onUpvote: {},
            onReport: {}
        )
    }
    .padding()
}

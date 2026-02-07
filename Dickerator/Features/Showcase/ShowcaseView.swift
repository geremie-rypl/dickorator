import SwiftUI
import FirebaseAuth

struct ShowcaseView: View {
    @StateObject private var viewModel = ShowcaseViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Featured post
                    if let featured = viewModel.featuredPost {
                        FeaturedBananaCard(post: featured) {
                            upvote(featured)
                        }
                        .padding(.horizontal)
                    }

                    // Tab picker
                    Picker("Feed", selection: $viewModel.selectedTab) {
                        ForEach(ShowcaseViewModel.ShowcaseTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Posts grid
                    switch viewModel.selectedTab {
                    case .recent:
                        recentPostsGrid
                    case .top:
                        topPostsGrid
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Showcase")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showLeaderboard = true
                    } label: {
                        Image(systemName: "trophy")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showLeaderboard) {
                LeaderboardView(topPosts: viewModel.topPosts)
            }
            .task {
                await viewModel.loadInitial()
            }
        }
    }

    private var recentPostsGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.posts) { post in
                BananaCard(
                    post: post,
                    onUpvote: { upvote(post) },
                    onReport: { report(post) }
                )
                .padding(.horizontal)
                .onAppear {
                    if post.id == viewModel.posts.last?.id {
                        Task {
                            await viewModel.loadMore()
                        }
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }

    private var topPostsGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.topPosts) { post in
                BananaCard(
                    post: post,
                    onUpvote: { upvote(post) },
                    onReport: { report(post) }
                )
                .padding(.horizontal)
            }
        }
    }

    private func upvote(_ post: BananaPost) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            await viewModel.upvote(post, userId: userId)
        }
    }

    private func report(_ post: BananaPost) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        Task {
            await viewModel.reportPost(post, userId: userId, reason: "inappropriate")
        }
    }
}

struct LeaderboardView: View {
    let topPosts: [BananaPost]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(topPosts.enumerated()), id: \.element.id) { index, post in
                    HStack(spacing: 12) {
                        // Rank
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index))
                                .frame(width: 32, height: 32)

                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading) {
                            Text("@\(post.username)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("\(post.upvotes) upvotes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if index == 0 {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Leaderboard")
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

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .pink
        }
    }
}

#Preview {
    ShowcaseView()
        .environmentObject(AppState())
}

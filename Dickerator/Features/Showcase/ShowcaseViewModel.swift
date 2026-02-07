import SwiftUI
import FirebaseFirestore

@MainActor
class ShowcaseViewModel: ObservableObject {
    @Published var posts: [BananaPost] = []
    @Published var featuredPost: BananaPost?
    @Published var topPosts: [BananaPost] = []
    @Published var isLoading = false
    @Published var showLeaderboard = false
    @Published var selectedTab: ShowcaseTab = .recent

    private var lastDocument: DocumentSnapshot?
    private let firebaseService = FirebaseService.shared

    enum ShowcaseTab: String, CaseIterable {
        case recent = "Recent"
        case top = "Top"
    }

    func loadInitial() async {
        isLoading = true
        defer { isLoading = false }

        async let postsTask = loadPosts()
        async let featuredTask = loadFeatured()
        async let topTask = loadTopPosts()

        await postsTask
        await featuredTask
        await topTask

        AnalyticsService.shared.track(.showcaseView)
    }

    private func loadPosts() async {
        do {
            let (fetchedPosts, lastDoc) = try await firebaseService.fetchPosts()
            posts = fetchedPosts
            lastDocument = lastDoc
        } catch {
            print("Failed to load posts: \(error)")
        }
    }

    private func loadFeatured() async {
        do {
            featuredPost = try await firebaseService.fetchFeaturedPost()
        } catch {
            print("Failed to load featured: \(error)")
        }
    }

    private func loadTopPosts() async {
        do {
            topPosts = try await firebaseService.fetchTopPosts()
        } catch {
            print("Failed to load top posts: \(error)")
        }
    }

    func loadMore() async {
        guard !isLoading, lastDocument != nil else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (morePosts, lastDoc) = try await firebaseService.fetchPosts(lastDocument: lastDocument)
            posts.append(contentsOf: morePosts)
            lastDocument = lastDoc
        } catch {
            print("Failed to load more posts: \(error)")
        }
    }

    func refresh() async {
        lastDocument = nil
        await loadInitial()
    }

    func upvote(_ post: BananaPost, userId: String) async {
        guard let postId = post.id else { return }

        do {
            try await firebaseService.upvotePost(postId: postId, userId: userId)

            // Optimistic update
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].upvotes += 1
            }

            AnalyticsService.shared.track(.showcaseUpvote)
        } catch {
            print("Failed to upvote: \(error)")
        }
    }

    func reportPost(_ post: BananaPost, userId: String, reason: String) async {
        guard let postId = post.id else { return }

        do {
            try await firebaseService.reportPost(postId: postId, userId: userId, reason: reason)
        } catch {
            print("Failed to report: \(error)")
        }
    }
}

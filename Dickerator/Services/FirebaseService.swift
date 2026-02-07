import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

actor FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - User Profile

    func fetchUserProfile(userId: String) async -> UserProfile? {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            return try doc.data(as: UserProfile.self)
        } catch {
            print("Failed to fetch user profile: \(error)")
            return nil
        }
    }

    func createUserProfile(userId: String, username: String) async throws {
        let profile = UserProfile(
            username: username,
            totalUpvotes: 0,
            postCount: 0,
            createdAt: Date()
        )
        try db.collection("users").document(userId).setData(from: profile)
    }

    func updateUsername(userId: String, username: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "username": username
        ])
    }

    // MARK: - Banana Posts

    func fetchPosts(limit: Int = 20, lastDocument: DocumentSnapshot? = nil) async throws -> ([BananaPost], DocumentSnapshot?) {
        var query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let posts = snapshot.documents.compactMap { try? $0.data(as: BananaPost.self) }
        let lastDoc = snapshot.documents.last

        return (posts, lastDoc)
    }

    func fetchTopPosts(limit: Int = 10) async throws -> [BananaPost] {
        let snapshot = try await db.collection("posts")
            .order(by: "upvotes", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: BananaPost.self) }
    }

    func fetchFeaturedPost() async throws -> BananaPost? {
        let snapshot = try await db.collection("posts")
            .whereField("isFeatured", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: BananaPost.self) }
    }

    func createPost(_ post: BananaPost) async throws -> String {
        let docRef = try db.collection("posts").addDocument(from: post)
        return docRef.documentID
    }

    func upvotePost(postId: String, userId: String) async throws {
        let upvoteRef = db.collection("posts").document(postId)
            .collection("upvotes").document(userId)

        let exists = try await upvoteRef.getDocument().exists
        guard !exists else { return }

        let batch = db.batch()
        batch.setData(["createdAt": FieldValue.serverTimestamp()], forDocument: upvoteRef)
        batch.updateData(["upvotes": FieldValue.increment(Int64(1))],
                         forDocument: db.collection("posts").document(postId))
        try await batch.commit()
    }

    func reportPost(postId: String, userId: String, reason: String) async throws {
        try await db.collection("reports").addDocument(data: [
            "postId": postId,
            "reporterId": userId,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending"
        ])
    }

    // MARK: - Storage

    func uploadImage(_ imageData: Data, path: String) async throws -> String {
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}

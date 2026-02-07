import Foundation
import FirebaseFirestore

struct BananaPost: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let imageURL: String
    let filterUsed: String?
    let stickerCount: Int
    var upvotes: Int
    let createdAt: Date
    var isFeatured: Bool

    static func == (lhs: BananaPost, rhs: BananaPost) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

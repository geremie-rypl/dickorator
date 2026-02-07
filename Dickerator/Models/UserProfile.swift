import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var username: String
    var totalUpvotes: Int
    var postCount: Int
    let createdAt: Date

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

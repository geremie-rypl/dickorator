import Foundation

struct FilterItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let imageName: String  // Asset name for the PNG overlay
    let price: Decimal?    // nil = free
    let isSecret: Bool

    var isFree: Bool { price == nil }

    // Built-in free filters
    static let freeFilters: [FilterItem] = [
        FilterItem(id: "filter.basic.glow", name: "Soft Glow", imageName: "filter_glow", price: nil, isSecret: false),
        FilterItem(id: "filter.basic.vintage", name: "Vintage Vibes", imageName: "filter_vintage", price: nil, isSecret: false),
        FilterItem(id: "filter.basic.neon", name: "Neon Dreams", imageName: "filter_neon", price: nil, isSecret: false),
    ]

    // Premium filters
    static let premiumFilters: [FilterItem] = [
        FilterItem(id: "filter.futuristic", name: "Futuristic Banana", imageName: "filter_futuristic", price: 1.99, isSecret: false),
        FilterItem(id: "filter.doctor", name: "Dr. Banana", imageName: "filter_doctor", price: 1.99, isSecret: false),
        FilterItem(id: "filter.party", name: "Party Banana", imageName: "filter_party", price: 1.99, isSecret: false),
        FilterItem(id: "filter.galaxy", name: "Galaxy Banana", imageName: "filter_galaxy", price: 1.99, isSecret: false),
        FilterItem(id: "filter.tropical", name: "Tropical Paradise", imageName: "filter_tropical", price: 1.99, isSecret: false),
    ]

    // Secret filters (unlocked via sharing)
    static let secretFilters: [FilterItem] = [
        FilterItem(id: "secret.filter.golden", name: "Golden Hour", imageName: "filter_golden", price: nil, isSecret: true),
    ]

    static var all: [FilterItem] {
        freeFilters + premiumFilters + secretFilters
    }
}

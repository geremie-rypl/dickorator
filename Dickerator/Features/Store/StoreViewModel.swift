import SwiftUI
import StoreKit

@MainActor
class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let storeKitService = StoreKitService.shared

    var filterProducts: [Product] {
        products.filter { $0.id.hasPrefix("filter.") }
    }

    var stickerProducts: [Product] {
        products.filter { $0.id.hasPrefix("stickers.") }
    }

    var subscriptionProducts: [Product] {
        products.filter { $0.id.hasPrefix("unlimited.") }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        await storeKitService.loadProducts()
        products = storeKitService.products

        AnalyticsService.shared.track(.storeView)
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        AnalyticsService.shared.track(.purchaseStarted, properties: ["product_id": product.id])

        do {
            let success = try await storeKitService.purchase(product)
            if success {
                AnalyticsService.shared.trackPurchase(productId: product.id, success: true)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            AnalyticsService.shared.trackPurchase(productId: product.id, success: false)
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        await storeKitService.restorePurchases()
    }

    func isPurchased(_ productId: String) -> Bool {
        storeKitService.purchasedProductIDs.contains(productId)
    }

    func hasUnlimitedAccess() -> Bool {
        storeKitService.hasUnlimitedAccess
    }
}

import Foundation

class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    enum Event: String {
        case appLaunch = "app_launch"
        case photoCapture = "photo_capture"
        case filterApplied = "filter_applied"
        case stickerAdded = "sticker_added"
        case exportClean = "export_clean"
        case exportCensored = "export_censored"
        case share = "share"
        case showcaseView = "showcase_view"
        case showcaseUpvote = "showcase_upvote"
        case showcasePost = "showcase_post"
        case storeView = "store_view"
        case purchaseStarted = "purchase_started"
        case purchaseCompleted = "purchase_completed"
        case purchaseFailed = "purchase_failed"
        case secretUnlocked = "secret_unlocked"
    }

    func track(_ event: Event, properties: [String: Any]? = nil) {
        var logMessage = "Analytics: \(event.rawValue)"
        if let props = properties {
            logMessage += " | \(props)"
        }
        print(logMessage)

        // TODO: Send to backend analytics service if needed
        // For MVP, just logging locally
    }

    func trackFilterUsage(_ filterId: String) {
        track(.filterApplied, properties: ["filter_id": filterId])
    }

    func trackStickerUsage(_ stickerId: String) {
        track(.stickerAdded, properties: ["sticker_id": stickerId])
    }

    func trackPurchase(productId: String, success: Bool) {
        if success {
            track(.purchaseCompleted, properties: ["product_id": productId])
        } else {
            track(.purchaseFailed, properties: ["product_id": productId])
        }
    }

    func trackSecretUnlock(_ secretId: String) {
        track(.secretUnlocked, properties: ["secret_id": secretId])
    }
}

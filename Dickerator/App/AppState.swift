import SwiftUI
import FirebaseAuth

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var hasUnlimitedAccess = false
    @Published var purchasedProductIDs: Set<String> = []

    // Share counter for secret unlocks
    @AppStorage("shareCount") var shareCount: Int = 0

    private let firebaseService = FirebaseService.shared
    private let storeKitService = StoreKitService.shared

    init() {
        Task {
            await setupAuth()
            await checkEntitlements()
        }
    }

    private func setupAuth() async {
        // Sign in anonymously if not already signed in
        if Auth.auth().currentUser == nil {
            do {
                try await Auth.auth().signInAnonymously()
                isAuthenticated = true
            } catch {
                print("Anonymous auth failed: \(error)")
            }
        } else {
            isAuthenticated = true
            await loadUserProfile()
        }
    }

    private func loadUserProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        currentUser = await firebaseService.fetchUserProfile(userId: uid)
    }

    private func checkEntitlements() async {
        await storeKitService.checkEntitlements()
        hasUnlimitedAccess = storeKitService.hasUnlimitedAccess
        purchasedProductIDs = storeKitService.purchasedProductIDs
    }

    func onShare() {
        shareCount += 1
        checkSecretUnlocks()
        AnalyticsService.shared.track(.share)
    }

    private func checkSecretUnlocks() {
        if shareCount == 5 {
            unlockSecret("secret.filter.golden")
        }
        if shareCount == 10 {
            unlockSecret("secret.stickers.rare")
        }
    }

    private func unlockSecret(_ id: String) {
        purchasedProductIDs.insert(id)
        // TODO: Persist to UserDefaults for MVP
        UserDefaults.standard.set(Array(purchasedProductIDs), forKey: "unlockedSecrets")
    }

    func isContentUnlocked(_ id: String) -> Bool {
        hasUnlimitedAccess || purchasedProductIDs.contains(id)
    }
}

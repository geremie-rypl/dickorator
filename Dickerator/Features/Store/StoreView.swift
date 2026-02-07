import SwiftUI
import StoreKit

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Unlimited subscription banner
                    if !viewModel.hasUnlimitedAccess() {
                        unlimitedBanner
                    }

                    // Filters section
                    if !viewModel.filterProducts.isEmpty {
                        productSection(
                            title: "Filters",
                            icon: "camera.filters",
                            products: viewModel.filterProducts
                        )
                    }

                    // Stickers section
                    if !viewModel.stickerProducts.isEmpty {
                        productSection(
                            title: "Sticker Packs",
                            icon: "face.smiling",
                            products: viewModel.stickerProducts
                        )
                    }

                    // Restore purchases
                    Button {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Shop")
            .task {
                await viewModel.loadProducts()
            }
            .overlay {
                if viewModel.isLoading || viewModel.isPurchasing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Purchase Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var unlimitedBanner: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "infinity")
                    .font(.largeTitle)
                    .foregroundColor(.pink)

                VStack(alignment: .leading) {
                    Text("Go Unlimited")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Unlock all filters & stickers forever")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(viewModel.subscriptionProducts) { product in
                    SubscriptionButton(product: product) {
                        Task {
                            await viewModel.purchase(product)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func productSection(title: String, icon: String, products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        isPurchased: viewModel.isPurchased(product.id),
                        hasUnlimited: viewModel.hasUnlimitedAccess()
                    ) {
                        Task {
                            await viewModel.purchase(product)
                        }
                    }
                }
            }
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    let onPurchase: () -> Void

    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 4) {
                Text(product.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.pink)

                if product.id == "unlimited.annual" {
                    Text("Best Value")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct ProductCard: View {
    let product: Product
    let isPurchased: Bool
    let hasUnlimited: Bool
    let onPurchase: () -> Void

    private var isUnlocked: Bool {
        isPurchased || hasUnlimited
    }

    private var previewImage: String {
        // Map product IDs to preview images
        switch product.id {
        case "filter.futuristic": return "filter_futuristic"
        case "filter.doctor": return "filter_doctor"
        case "filter.party": return "filter_party"
        case "filter.galaxy": return "filter_galaxy"
        case "filter.tropical": return "filter_tropical"
        case "stickers.fancy": return "pack_fancy_preview"
        case "stickers.food": return "pack_food_preview"
        default: return "pack_default_preview"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Image(previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isUnlocked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(Circle().fill(.white).padding(2))
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }

            Text(product.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            if isUnlocked {
                Text("Owned")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button(action: onPurchase) {
                    Text(product.displayPrice)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.pink)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StoreView()
        .environmentObject(AppState())
}

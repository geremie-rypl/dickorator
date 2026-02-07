import SwiftUI
import FirebaseCore

@main
struct DickeratorApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Create", systemImage: "camera.fill")
                }
                .tag(0)

            ShowcaseView()
                .tabItem {
                    Label("Showcase", systemImage: "star.fill")
                }
                .tag(1)

            StoreView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(2)
        }
        .tint(.pink)
    }
}

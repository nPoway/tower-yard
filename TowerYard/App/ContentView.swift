import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var yardStore: TowerYardStore
    @StateObject private var profileStore: TowerYardProfileStore
    @StateObject private var progressStore: TowerProgressStore
    @AppStorage("TowerYard.hasCompletedOnboarding.v1") private var hasCompletedOnboarding = false

    init() {
        _yardStore = StateObject(wrappedValue: TowerYardStore())
        _profileStore = StateObject(wrappedValue: TowerYardProfileStore())
        _progressStore = StateObject(wrappedValue: TowerProgressStore())
    }

    init(
        yardStore: TowerYardStore,
        profileStore: TowerYardProfileStore,
        progressStore: TowerProgressStore
    ) {
        _yardStore = StateObject(wrappedValue: yardStore)
        _profileStore = StateObject(wrappedValue: profileStore)
        _progressStore = StateObject(wrappedValue: progressStore)
    }

    var body: some View {
        fanApp
            .onAppear {
                AppDelegate.lockGameOrientation()
            }
            .onDisappear {
                AppDelegate.restoreDefaultOrientations()
            }
    }

    @ViewBuilder
    private var fanApp: some View {
        if hasCompletedOnboarding {
            appShell
        } else {
            TowerYardOnboardingView {
                withAnimation(.easeInOut(duration: 0.24)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }

    private var appShell: some View {
        AppShellView(store: yardStore)
            .environmentObject(yardStore)
            .environmentObject(profileStore)
            .environmentObject(progressStore)
    }
}

#Preview {
    ContentView(
        yardStore: .preview,
        profileStore: .preview(sampleData: true),
        progressStore: TowerProgressStore(progress: TowerProgress())
    )
}

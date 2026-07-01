import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var yardStore: TowerYardStore
    @StateObject private var profileStore: TowerYardProfileStore
    @StateObject private var progressStore: TowerProgressStore
    @AppStorage("TowerYard.hasCompletedOnboarding.v1") private var hasCompletedOnboarding = false
    @State private var hasFinishedSplash = false

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
        ZStack {
            if !hasFinishedSplash {
                LaunchSplashView()
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                appShell
                    .transition(.opacity)
            } else {
                TowerYardOnboardingView {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            guard !hasFinishedSplash else { return }

            try? await Task.sleep(nanoseconds: 3_000_000_000)

            withAnimation(.easeInOut(duration: 0.28)) {
                hasFinishedSplash = true
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

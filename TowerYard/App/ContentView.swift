import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var yardStore: TowerYardStore
    @StateObject private var profileStore: TowerYardProfileStore
    @StateObject private var progressStore: TowerProgressStore
    @State private var launchCoordinator: AppLaunchCoordinator
    @AppStorage("TowerYard.hasCompletedOnboarding.v1") private var hasCompletedOnboarding = false

    init() {
        _yardStore = StateObject(wrappedValue: TowerYardStore())
        _profileStore = StateObject(wrappedValue: TowerYardProfileStore())
        _progressStore = StateObject(wrappedValue: TowerProgressStore())
        _launchCoordinator = State(initialValue: AppLaunchCoordinator())
    }

    init(
        yardStore: TowerYardStore,
        profileStore: TowerYardProfileStore,
        progressStore: TowerProgressStore,
        launchCoordinator: AppLaunchCoordinator? = nil
    ) {
        _yardStore = StateObject(wrappedValue: yardStore)
        _profileStore = StateObject(wrappedValue: profileStore)
        _progressStore = StateObject(wrappedValue: progressStore)
        _launchCoordinator = State(initialValue: launchCoordinator ?? AppLaunchCoordinator())
    }

    var body: some View {
        ZStack {
            switch launchCoordinator.route {
            case .loading:
                LaunchSplashView()
                    .transition(.opacity)
            case .noInternet(let message):
                NoInternetView(message: message) {
                    launchCoordinator.retry()
                }
                .transition(.opacity)
            case .fanContent:
                fanApp
                    .transition(.opacity)
                    .onAppear {
                        AppDelegate.lockGameOrientation()
                    }
                    .onDisappear {
                        AppDelegate.restoreDefaultOrientations()
                    }
            case .notificationPrompt:
                NotificationOptInView(
                    allowAction: {
                        launchCoordinator.acceptNotifications()
                    },
                    skipAction: {
                        launchCoordinator.skipNotifications()
                    }
                )
                .transition(.opacity)
            case .webView(let request):
                TowerWebView(url: request.url, requestID: request.id)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .preferredColorScheme(.dark)
            }
        }
        .task {
            AppDelegate.startAppsFlyerForLaunch()
            await launchCoordinator.start()
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

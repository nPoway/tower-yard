import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case play
    case contracts
    case shop
    case achievements
    case profile
    case settings
    case foremanChat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .play: "Play"
        case .contracts: "Contracts"
        case .shop: "Shop"
        case .achievements: "Achievements"
        case .profile: "Profile"
        case .settings: "Settings"
        case .foremanChat: "Foreman Chat"
        }
    }

    var shortTitle: String {
        switch self {
        case .play: "Play"
        case .contracts: "Jobs"
        case .shop: "Shop"
        case .achievements: "Awards"
        case .profile: "Profile"
        case .settings: "Settings"
        case .foremanChat: "Chat"
        }
    }

    var systemImage: String {
        switch self {
        case .play: "play.fill"
        case .contracts: "doc.text.fill"
        case .shop: "cart.fill"
        case .achievements: "trophy.fill"
        case .profile: "person.crop.square.fill"
        case .settings: "gearshape.fill"
        case .foremanChat: "bubble.left.and.bubble.right.fill"
        }
    }
}

struct AppShellView: View {
    @ObservedObject var store: TowerYardStore
    @EnvironmentObject private var progressStore: TowerProgressStore
    @State private var selectedTab: AppTab = .play

    var body: some View {
        tabDeck
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TowerYardBottomTabBar(selection: $selectedTab)
            }
            .tint(TYTheme.accent)
    }

    private var tabDeck: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    content(for: tab)
                        .navigationTitle(tab.title)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .opacity(selectedTab == tab ? 1 : 0)
                .allowsHitTesting(selectedTab == tab)
                .accessibilityHidden(selectedTab != tab)
                .zIndex(selectedTab == tab ? 1 : 0)
            }
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .play:
            PlayHubView()
        case .contracts:
            ContractsHubView()
        case .shop:
            ShopShellView(store: store)
        case .achievements:
            AchievementsView(store: progressStore)
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .foremanChat:
            ForemanChatShellView()
        }
    }
}

private struct TowerYardBottomTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                TowerYardTabButton(
                    tab: tab,
                    isSelected: selection == tab
                ) {
                    guard selection != tab else { return }
                    withAnimation(.easeInOut(duration: 0.16)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(.horizontal, AppShellMetrics.tabBarHorizontalPadding)
        .padding(.top, AppShellMetrics.tabBarTopPadding)
        .padding(.bottom, AppShellMetrics.tabBarBottomPadding)
        .frame(height: AppShellMetrics.tabBarHeight)
        .background {
            Rectangle()
                .fill(TowerYardTheme.deepSteel)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TowerYardTheme.panelStroke)
                .frame(height: 1)
        }
    }
}

private struct TowerYardTabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 32, height: 28)
                    .foregroundStyle(iconColor)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? TYTheme.accent : Color.clear)
                    )

                Text(tab.shortTitle)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppShellMetrics.tabBarButtonHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityValue(isSelected ? "Selected" : "")
    }

    private var iconColor: Color {
        isSelected ? TowerYardTheme.warningStripe : TowerYardTheme.textSecondary
    }

    private var labelColor: Color {
        isSelected ? TowerYardTheme.textPrimary : TowerYardTheme.textSecondary
    }
}

#Preview {
    AppShellView(store: .preview)
        .environmentObject(TowerYardProfileStore.preview(sampleData: true))
        .environmentObject(TowerProgressStore(progress: TowerProgress()))
}

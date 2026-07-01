import SwiftUI

enum EconomyTab: Hashable {
    case game
    case shop
}

struct EconomyRootView: View {
    @ObservedObject var store: TowerYardStore
    @State private var selectedTab: EconomyTab = .game

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GameView(store: store)
            }
            .tabItem {
                Label("Game", systemImage: "square.stack.3d.up.fill")
            }
            .tag(EconomyTab.game)

            NavigationStack {
                ShopView(store: store)
            }
            .tabItem {
                Label("Shop", systemImage: "cart.fill")
            }
            .tag(EconomyTab.shop)
        }
        .tint(TYTheme.accent)
    }
}

#Preview {
    EconomyRootView(store: .preview)
}

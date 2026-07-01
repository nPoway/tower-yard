import SwiftUI

struct ContractsHubView: View {
    @EnvironmentObject private var progressStore: TowerProgressStore
    @State private var selectedSession: GameSession?

    var body: some View {
        ContractsView(progressStore: progressStore) { contract in
            selectedSession = .contract(contract)
        }
        .navigationDestination(item: $selectedSession) { session in
            GameSessionView(session: session, progressStore: progressStore)
        }
    }
}

struct ShopShellView: View {
    @ObservedObject var store: TowerYardStore

    var body: some View {
        ShopView(store: store)
    }
}

struct ForemanChatShellView: View {
    var body: some View {
        ForemanChatView()
    }
}

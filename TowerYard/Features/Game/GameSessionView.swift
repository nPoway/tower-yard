import SwiftUI

struct GameSessionView: View {
    @EnvironmentObject private var yardStore: TowerYardStore
    @ObservedObject var progressStore: TowerProgressStore

    @State private var activeSession: GameSession
    @StateObject private var game: YardGameStore
    @State private var progressOutcome: RunOutcome?
    @State private var handledResultID: UUID?

    init(session: GameSession, progressStore: TowerProgressStore) {
        self.progressStore = progressStore
        _activeSession = State(initialValue: session)
        _game = StateObject(wrappedValue: YardGameStore(configuration: .session(session)))
    }

    var body: some View {
        TowerGameView(
            game: game,
            progressOutcome: progressOutcome,
            canAdvanceContract: canAdvanceContract,
            onResult: recordGameResult,
            onNextContract: advanceToNextContract
        )
    }

    private var canAdvanceContract: Bool {
        guard game.mode == .contracts,
              case .won = game.phase,
              case .contract(let contract) = activeSession else {
            return false
        }

        return contract.id < ContractCatalog.maxID
    }

    private func recordGameResult(_ result: YardGameResult) {
        guard handledResultID != result.id else { return }
        handledResultID = result.id

        guard result.mode == .contracts, result.outcome != .zenSnapshot else {
            progressOutcome = nil
            return
        }

        let progressCoinsBefore = progressStore.walletCoins
        let outcome = progressStore.recordResult(
            for: activeSession,
            height: result.height,
            completed: result.outcome == .victory
        )
        progressOutcome = outcome

        let progressCoinDelta = progressStore.walletCoins - progressCoinsBefore
        let earnedCoins = max(0, max(outcome.coinsAwarded, progressCoinDelta))
        yardStore.awardCoins(earnedCoins)
    }

    private func advanceToNextContract() {
        guard case .contract(let contract) = activeSession,
              let nextContract = ContractCatalog.all.first(where: { $0.id == contract.id + 1 }) else {
            game.restartRound()
            return
        }

        let nextSession = GameSession.contract(nextContract)
        activeSession = nextSession
        progressOutcome = nil
        handledResultID = nil
        game.configure(for: nextSession)
    }
}

#Preview {
    NavigationStack {
        GameSessionView(
            session: .contract(ContractCatalog.all[0]),
            progressStore: TowerProgressStore(progress: TowerProgress())
        )
        .environmentObject(TowerYardStore.preview)
    }
}

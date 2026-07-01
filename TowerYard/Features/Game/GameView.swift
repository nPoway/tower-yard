import SwiftUI

@MainActor
struct GameView: View {
    @ObservedObject var store: TowerYardStore

    @StateObject private var progressStore = TowerProgressStore()
    @StateObject private var game = YardGameStore(configuration: .session(.contract(ContractCatalog.all[0])), mode: .endless)
    @State private var activeContract = ContractCatalog.all[0]
    @State private var progressOutcome: RunOutcome?
    @State private var handledResultID: UUID?

    var body: some View {
        TowerGameView(
            game: game,
            progressOutcome: progressOutcome,
            canAdvanceContract: canAdvanceContract,
            onResult: recordResult,
            onNextContract: advanceContract
        )
    }

    private var canAdvanceContract: Bool {
        guard game.mode == .contracts, case .won = game.phase else {
            return false
        }

        return activeContract.id < ContractCatalog.maxID
    }

    private func recordResult(_ result: YardGameResult) {
        guard handledResultID != result.id else { return }
        handledResultID = result.id

        guard result.outcome != .zenSnapshot else {
            progressOutcome = nil
            return
        }

        let stability = max(0, min(1, 1 - Double(game.instability / 3)))
        store.recordGameResult(
            TowerRunResult(
                blocksPlaced: result.height,
                stabilityScore: stability,
                usedToolIDs: [],
                finishedSafely: result.outcome == .victory
            )
        )

        guard result.mode == .contracts else {
            progressOutcome = nil
            return
        }

        progressOutcome = progressStore.recordResult(
            for: .contract(activeContract),
            height: result.height,
            completed: result.outcome == .victory
        )
    }

    private func advanceContract() {
        guard let nextContract = ContractCatalog.all.first(where: { $0.id == activeContract.id + 1 }) else {
            game.restartRound()
            return
        }

        activeContract = nextContract
        progressOutcome = nil
        handledResultID = nil
        game.configure(for: .contract(nextContract))
    }
}

#Preview {
    GameView(store: .preview)
}

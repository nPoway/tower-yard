import SwiftUI

struct GameSessionView: View {
    @EnvironmentObject private var yardStore: TowerYardStore
    @EnvironmentObject private var profileStore: TowerYardProfileStore
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
            availableTools: yardStore.gameTools,
            onUseTool: useTool,
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

        guard result.outcome != .zenSnapshot else {
            progressOutcome = nil
            return
        }

        let progressCoinsBefore = progressStore.walletCoins
        let outcome = progressStore.recordResult(
            for: activeSession,
            height: result.height,
            completed: result.outcome == .victory,
            resultID: result.id,
            completedAt: result.date,
            perfectBlocks: result.perfectBlocks,
            usedHelperTools: result.usedHelperTools,
            ratingStars: result.rating?.stars,
            precisionScore: result.rating?.precision,
            stabilityScore: result.rating?.stability,
            efficiencyScore: result.rating?.efficiency,
            runRewardCoins: result.outcome == .victory ? result.coins : 0
        )
        progressOutcome = outcome

        yardStore.recordRunStats(
            TowerRunResult(
                blocksPlaced: result.height,
                stabilityScore: max(0, min(1, 1 - Double(game.tiltDangerLevel))),
                usedToolIDs: result.usedToolIDs ?? [],
                finishedSafely: result.outcome == .victory
            )
        )
        let earnedCoins = max(0, progressStore.walletCoins - progressCoinsBefore)
        yardStore.awardCoins(earnedCoins)
        profileStore.recordTowerResult(
            resultCard(for: result),
            walletCoins: yardStore.coins,
            equippedSkin: yardStore.equippedSkin.name
        )
    }

    private func useTool(_ toolID: GameToolID) {
        guard game.canUseTool(toolID), yardStore.consumeTool(toolID) else {
            return
        }

        _ = game.useTool(toolID)
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

    private func resultCard(for result: YardGameResult) -> TowerResultCard {
        TowerResultCard(
            id: result.id,
            mode: playMode(for: result.mode),
            height: result.height,
            weather: towerWeather(for: game.configuration.weather),
            date: result.date,
            material: game.configuration.material.displayName,
            skin: yardStore.equippedSkin.name,
            outcome: towerOutcome(for: result.outcome),
            score: result.score,
            perfectBlocks: result.perfectBlocks,
            toolsUsed: result.helperToolUseCount,
            ratingStars: result.rating?.stars
        )
    }

    private func playMode(for mode: YardRunMode) -> YardPlayMode {
        switch mode {
        case .contracts:
            return .contracts
        case .endless:
            return .endlessTower
        case .zen:
            return .zenBuild
        }
    }

    private func towerWeather(for weather: ContractWeather) -> TowerWeather {
        switch weather {
        case .clear:
            return .clear
        case .breeze, .crosswind, .gusts, .storm:
            return .windy
        case .rain:
            return .rainy
        case .fog:
            return .foggy
        }
    }

    private func towerOutcome(for outcome: YardResultOutcome) -> TowerBuildOutcome {
        switch outcome {
        case .victory:
            return .completed
        case .defeat:
            return .toppled
        case .zenSnapshot:
            return .abandoned
        }
    }
}

#Preview {
    NavigationStack {
        GameSessionView(
            session: .contract(ContractCatalog.all[0]),
            progressStore: TowerProgressStore(progress: TowerProgress())
        )
        .environmentObject(TowerYardStore.preview)
        .environmentObject(TowerYardProfileStore.preview(sampleData: true))
    }
}

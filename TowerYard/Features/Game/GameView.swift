import SwiftUI

@MainActor
struct GameView: View {
    @ObservedObject var store: TowerYardStore
    @EnvironmentObject private var profileStore: TowerYardProfileStore
    @EnvironmentObject private var progressStore: TowerProgressStore

    @StateObject private var game = YardGameStore(configuration: .session(.contract(ContractCatalog.all[0])), mode: .endless)
    @State private var activeContract = ContractCatalog.all[0]
    @State private var progressOutcome: RunOutcome?
    @State private var handledResultID: UUID?

    var body: some View {
        TowerGameView(
            game: game,
            progressOutcome: progressOutcome,
            canAdvanceContract: canAdvanceContract,
            availableTools: store.gameTools,
            onUseTool: useTool,
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

        let progressCoinsBefore = progressStore.walletCoins
        let completed = result.outcome == .victory

        if result.mode == .contracts {
            progressOutcome = progressStore.recordResult(
                for: .contract(activeContract),
                height: result.height,
                completed: completed,
                resultID: result.id,
                completedAt: result.date,
                perfectBlocks: result.perfectBlocks,
                usedHelperTools: result.usedHelperTools,
                ratingStars: result.rating?.stars,
                precisionScore: result.rating?.precision,
                stabilityScore: result.rating?.stability,
                efficiencyScore: result.rating?.efficiency,
                runRewardCoins: completed ? result.coins : 0
            )
        } else {
            progressOutcome = nil
            _ = progressStore.recordGameResult(
                GameResult(
                    id: result.id,
                    completedAt: result.date,
                    mode: gameMode(for: result.mode),
                    floors: result.height,
                    heightMeters: Double(result.height) * 4.2,
                    weather: constructionWeather(for: game.configuration.weather),
                    rewardCoins: result.coins,
                    outcome: completed ? .completed : .failed,
                    perfectBlocks: result.perfectBlocks,
                    toolsUsed: result.usedHelperTools,
                    blueprintMatched: false,
                    style: buildingStyle(for: game.configuration.material),
                    difficulty: max(1, Int((Double(max(1, result.height)) / 6).rounded(.up))),
                    timeOfDay: .day,
                    ratingStars: result.rating?.stars,
                    precisionScore: result.rating?.precision,
                    stabilityScore: result.rating?.stability,
                    efficiencyScore: result.rating?.efficiency
                )
            )
        }

        store.recordRunStats(
            TowerRunResult(
                blocksPlaced: result.height,
                stabilityScore: max(0, min(1, 1 - Double(game.tiltDangerLevel))),
                usedToolIDs: result.usedToolIDs ?? [],
                finishedSafely: completed
            )
        )
        store.awardCoins(max(0, progressStore.walletCoins - progressCoinsBefore))
        profileStore.recordTowerResult(
            resultCard(for: result),
            walletCoins: store.coins,
            equippedSkin: store.equippedSkin.name
        )
    }

    private func useTool(_ toolID: GameToolID) {
        guard game.canUseTool(toolID), store.consumeTool(toolID) else {
            return
        }

        _ = game.useTool(toolID)
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

    private func resultCard(for result: YardGameResult) -> TowerResultCard {
        TowerResultCard(
            id: result.id,
            mode: playMode(for: result.mode),
            height: result.height,
            weather: towerWeather(for: game.configuration.weather),
            date: result.date,
            material: game.configuration.material.displayName,
            skin: store.equippedSkin.name,
            outcome: result.outcome == .victory ? .completed : .toppled,
            score: result.score,
            perfectBlocks: result.perfectBlocks,
            toolsUsed: result.helperToolUseCount,
            ratingStars: result.rating?.stars
        )
    }

    private func gameMode(for mode: YardRunMode) -> GameMode {
        switch mode {
        case .contracts:
            return .contract
        case .endless:
            return .endless
        case .zen:
            return .zen
        }
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

    private func constructionWeather(for weather: ContractWeather) -> ConstructionWeather {
        switch weather {
        case .clear:
            return .clear
        case .breeze, .crosswind, .gusts:
            return .wind
        case .rain:
            return .rain
        case .fog:
            return .fog
        case .storm:
            return .storm
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

    private func buildingStyle(for material: ContractMaterialStyle) -> BuildingStyle {
        switch material {
        case .timber:
            return .timber
        case .brick:
            return .brick
        case .concrete:
            return .concrete
        case .steel:
            return .steel
        case .glass:
            return .glass
        case .composite:
            return .modular
        case .mixed:
            return .industrial
        }
    }
}

#Preview {
    GameView(store: .preview)
        .environmentObject(TowerYardProfileStore.preview(sampleData: true))
        .environmentObject(TowerProgressStore(progress: TowerProgress()))
}

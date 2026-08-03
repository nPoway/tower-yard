import Combine
import Foundation

enum ContractStatus: String, Hashable {
    case locked
    case available
    case completed

    var displayName: String {
        switch self {
        case .locked: "Locked"
        case .available: "Available"
        case .completed: "Completed"
        }
    }
}

struct TowerProfileStats: Equatable {
    let contractsPlayed: Int
    let contractsCompleted: Int
    let maximumHeight: Int
}

struct TowerProgress: Codable, Equatable {
    var coins: Int = 0
    var unlockedContractID: Int = 1
    var completedContractIDs: Set<Int> = []
    var bestHeightsByContractID: [Int: Int] = [:]
    var bestRatingStarsByContractID: [Int: Int] = [:]
    var contractRunsPlayed: Int = 0
    var highestBuiltHeight: Int = 0
    var dailyRecordsByDateKey: [String: DailyProgress] = [:]
    var blueprintRecordsByID: [String: BlueprintProgress] = [:]
    var constructionStats: ConstructionStats = ConstructionStats()
    var achievementStates: [AchievementState] = AchievementCatalog.all.map { AchievementState(id: $0.id) }
    var unlockedBuildingIDs: Set<String> = []
    var journalEntries: [JournalEntry] = []
    var recordedGameResultIDs: [UUID] = []

    init() {}

    enum CodingKeys: String, CodingKey {
        case coins
        case unlockedContractID
        case completedContractIDs
        case bestHeightsByContractID
        case bestRatingStarsByContractID
        case contractRunsPlayed
        case highestBuiltHeight
        case dailyRecordsByDateKey
        case blueprintRecordsByID
        case constructionStats
        case achievementStates
        case unlockedBuildingIDs
        case journalEntries
        case recordedGameResultIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? 0
        unlockedContractID = try container.decodeIfPresent(Int.self, forKey: .unlockedContractID) ?? 1
        completedContractIDs = try container.decodeIfPresent(Set<Int>.self, forKey: .completedContractIDs) ?? []
        bestHeightsByContractID = try container.decodeIfPresent([Int: Int].self, forKey: .bestHeightsByContractID) ?? [:]
        bestRatingStarsByContractID = try container.decodeIfPresent([Int: Int].self, forKey: .bestRatingStarsByContractID) ?? [:]
        contractRunsPlayed = try container.decodeIfPresent(Int.self, forKey: .contractRunsPlayed) ?? 0
        highestBuiltHeight = try container.decodeIfPresent(Int.self, forKey: .highestBuiltHeight) ?? 0
        dailyRecordsByDateKey = try container.decodeIfPresent([String: DailyProgress].self, forKey: .dailyRecordsByDateKey) ?? [:]
        blueprintRecordsByID = try container.decodeIfPresent([String: BlueprintProgress].self, forKey: .blueprintRecordsByID) ?? [:]
        constructionStats = try container.decodeIfPresent(ConstructionStats.self, forKey: .constructionStats) ?? ConstructionStats()
        achievementStates = try container.decodeIfPresent([AchievementState].self, forKey: .achievementStates) ?? AchievementCatalog.all.map { AchievementState(id: $0.id) }
        unlockedBuildingIDs = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedBuildingIDs) ?? []
        journalEntries = try container.decodeIfPresent([JournalEntry].self, forKey: .journalEntries) ?? []
        recordedGameResultIDs = try container.decodeIfPresent([UUID].self, forKey: .recordedGameResultIDs) ?? []
        normalizeConstructionProgress()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coins, forKey: .coins)
        try container.encode(unlockedContractID, forKey: .unlockedContractID)
        try container.encode(completedContractIDs, forKey: .completedContractIDs)
        try container.encode(bestHeightsByContractID, forKey: .bestHeightsByContractID)
        try container.encode(bestRatingStarsByContractID, forKey: .bestRatingStarsByContractID)
        try container.encode(contractRunsPlayed, forKey: .contractRunsPlayed)
        try container.encode(highestBuiltHeight, forKey: .highestBuiltHeight)
        try container.encode(dailyRecordsByDateKey, forKey: .dailyRecordsByDateKey)
        try container.encode(blueprintRecordsByID, forKey: .blueprintRecordsByID)
        try container.encode(constructionStats, forKey: .constructionStats)
        try container.encode(achievementStates, forKey: .achievementStates)
        try container.encode(unlockedBuildingIDs, forKey: .unlockedBuildingIDs)
        try container.encode(journalEntries, forKey: .journalEntries)
        try container.encode(recordedGameResultIDs, forKey: .recordedGameResultIDs)
    }

    mutating func normalizeConstructionProgress() {
        coins = max(0, coins)
        unlockedContractID = max(1, unlockedContractID)
        contractRunsPlayed = max(0, contractRunsPlayed)
        highestBuiltHeight = max(0, highestBuiltHeight)
        bestRatingStarsByContractID = bestRatingStarsByContractID.mapValues { min(3, max(0, $0)) }
        journalEntries = Array(journalEntries.prefix(20))
        recordedGameResultIDs = Array(recordedGameResultIDs.suffix(100))

        var statesByID = Dictionary(uniqueKeysWithValues: achievementStates.map { ($0.id, $0) })
        for achievement in AchievementCatalog.all where statesByID[achievement.id] == nil {
            statesByID[achievement.id] = AchievementState(id: achievement.id)
        }
        achievementStates = AchievementCatalog.all.map { statesByID[$0.id] ?? AchievementState(id: $0.id) }
    }
}

struct DailyProgress: Codable, Equatable {
    var bestHeight: Int = 0
    var completed: Bool = false
}

struct BlueprintProgress: Codable, Equatable {
    var bestHeight: Int = 0
    var completed: Bool = false
}

struct RunOutcome: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let completed: Bool
    let coinsAwarded: Int
}

enum GameSession: Hashable, Identifiable {
    case contract(TowerContract)
    case daily(DailyContract)
    case blueprint(BlueprintChallenge)

    var id: String {
        switch self {
        case .contract(let contract): "contract-\(contract.id)"
        case .daily(let contract): contract.id
        case .blueprint(let challenge): "blueprint-\(challenge.id)"
        }
    }

    var title: String {
        switch self {
        case .contract(let contract): contract.title
        case .daily(let contract): contract.title
        case .blueprint(let challenge): challenge.title
        }
    }

    var goal: String {
        switch self {
        case .contract(let contract): contract.goal
        case .daily(let contract): contract.goal
        case .blueprint(let challenge): challenge.goal
        }
    }

    var targetHeight: Int {
        switch self {
        case .contract(let contract): contract.targetHeight
        case .daily(let contract): contract.targetHeight
        case .blueprint(let challenge): challenge.targetHeight
        }
    }

    var weather: ContractWeather {
        switch self {
        case .contract(let contract): contract.weather
        case .daily(let contract): contract.weather
        case .blueprint(let challenge): challenge.weather
        }
    }

    var material: ContractMaterialStyle {
        switch self {
        case .contract(let contract): contract.material
        case .daily(let contract): contract.material
        case .blueprint(let challenge): challenge.material
        }
    }

    var coinReward: Int {
        switch self {
        case .contract(let contract): contract.coinReward
        case .daily(let contract): contract.coinReward
        case .blueprint(let challenge): challenge.coinReward
        }
    }

    var blueprintWidths: [Int]? {
        if case .blueprint(let challenge) = self {
            return challenge.silhouetteWidths
        }
        return nil
    }
}

final class TowerProgressStore: ObservableObject {
    @Published private(set) var progress: TowerProgress {
        didSet {
            if savesProgress {
                TowerProgressPersistence.save(progress)
            }
        }
    }

    private let savesProgress: Bool

    init(progress: TowerProgress = TowerProgressPersistence.load(), savesProgress: Bool = true) {
        self.progress = progress
        self.savesProgress = savesProgress
    }

    var profileStats: TowerProfileStats {
        TowerProfileStats(
            contractsPlayed: progress.contractRunsPlayed,
            contractsCompleted: progress.completedContractIDs.count,
            maximumHeight: progress.highestBuiltHeight
        )
    }

    var walletCoins: Int {
        progress.coins
    }

    var unlockedAchievementCount: Int {
        progress.achievementStates.filter { $0.unlockedAt != nil }.count
    }

    var unlockedBuildingCount: Int {
        progress.unlockedBuildingIDs.count
    }

    var journalEntries: [JournalEntry] {
        progress.journalEntries
    }

    func achievementState(for definition: AchievementDefinition) -> AchievementState {
        progress.achievementStates.first { $0.id == definition.id } ?? AchievementState(id: definition.id)
    }

    func achievementProgress(for definition: AchievementDefinition) -> AchievementProgress {
        definition.condition.progress(
            stats: progress.constructionStats,
            unlockedBuildingCount: progress.unlockedBuildingIDs.count
        )
    }

    func isBuildingUnlocked(_ building: BuildingDefinition) -> Bool {
        progress.unlockedBuildingIDs.contains(building.id)
    }

    func status(for contract: TowerContract) -> ContractStatus {
        if progress.completedContractIDs.contains(contract.id) {
            return .completed
        }

        if contract.id <= progress.unlockedContractID {
            return .available
        }

        return .locked
    }

    func bestHeight(for contract: TowerContract) -> Int {
        progress.bestHeightsByContractID[contract.id] ?? 0
    }

    func bestRating(for contract: TowerContract) -> Int {
        progress.bestRatingStarsByContractID[contract.id] ?? 0
    }

    func dailyProgress(for contract: DailyContract) -> DailyProgress {
        progress.dailyRecordsByDateKey[contract.dateKey] ?? DailyProgress()
    }

    func blueprintProgress(for challenge: BlueprintChallenge) -> BlueprintProgress {
        progress.blueprintRecordsByID[challenge.id] ?? BlueprintProgress()
    }

    func recordResult(
        for session: GameSession,
        height: Int,
        completed: Bool? = nil,
        resultID: UUID = UUID(),
        completedAt: Date = Date(),
        perfectBlocks: Int = 0,
        usedHelperTools: Bool = true,
        ratingStars: Int? = nil,
        precisionScore: Int? = nil,
        stabilityScore: Int? = nil,
        efficiencyScore: Int? = nil,
        runRewardCoins: Int = 0
    ) -> RunOutcome {
        switch session {
        case .contract(let contract):
            recordContractResult(
                contract,
                height: height,
                completed: completed,
                resultID: resultID,
                completedAt: completedAt,
                perfectBlocks: perfectBlocks,
                usedHelperTools: usedHelperTools,
                ratingStars: ratingStars,
                precisionScore: precisionScore,
                stabilityScore: stabilityScore,
                efficiencyScore: efficiencyScore,
                runRewardCoins: runRewardCoins
            )
        case .daily(let contract):
            recordDailyResult(
                contract,
                height: height,
                completed: completed,
                resultID: resultID,
                completedAt: completedAt,
                perfectBlocks: perfectBlocks,
                usedHelperTools: usedHelperTools,
                ratingStars: ratingStars,
                precisionScore: precisionScore,
                stabilityScore: stabilityScore,
                efficiencyScore: efficiencyScore,
                runRewardCoins: runRewardCoins
            )
        case .blueprint(let challenge):
            recordBlueprintResult(
                challenge,
                height: height,
                completed: completed,
                resultID: resultID,
                completedAt: completedAt,
                perfectBlocks: perfectBlocks,
                usedHelperTools: usedHelperTools,
                ratingStars: ratingStars,
                precisionScore: precisionScore,
                stabilityScore: stabilityScore,
                efficiencyScore: efficiencyScore,
                runRewardCoins: runRewardCoins
            )
        }
    }

    private func recordContractResult(
        _ contract: TowerContract,
        height: Int,
        completed: Bool?,
        resultID: UUID,
        completedAt: Date,
        perfectBlocks: Int,
        usedHelperTools: Bool,
        ratingStars: Int?,
        precisionScore: Int?,
        stabilityScore: Int?,
        efficiencyScore: Int?,
        runRewardCoins: Int
    ) -> RunOutcome {
        var updated = progress
        updated.contractRunsPlayed += 1
        updated.highestBuiltHeight = max(updated.highestBuiltHeight, height)
        updated.bestHeightsByContractID[contract.id] = max(updated.bestHeightsByContractID[contract.id] ?? 0, height)
        if let ratingStars {
            updated.bestRatingStarsByContractID[contract.id] = max(
                updated.bestRatingStarsByContractID[contract.id] ?? 0,
                ratingStars
            )
        }

        let didComplete = completed ?? (height >= contract.targetHeight)
        let alreadyCompleted = updated.completedContractIDs.contains(contract.id)
        var coinsAwarded = 0

        if didComplete {
            updated.completedContractIDs.insert(contract.id)
            updated.unlockedContractID = min(
                ContractCatalog.maxID,
                max(updated.unlockedContractID, contract.id + 1)
            )

            if !alreadyCompleted {
                coinsAwarded = contract.coinReward
            }
        }

        let runReward = didComplete ? max(0, runRewardCoins) : 0

        let result = gameResult(
            for: .contract(contract),
            height: height,
            rewardCoins: coinsAwarded + runReward,
            completed: didComplete,
            id: resultID,
            completedAt: completedAt,
            perfectBlocks: perfectBlocks,
            toolsUsed: usedHelperTools,
            ratingStars: ratingStars,
            precisionScore: precisionScore,
            stabilityScore: stabilityScore,
            efficiencyScore: efficiencyScore
        )
        let summary = applyConstructionResult(result, to: &updated)
        progress = updated

        if didComplete {
            let message = alreadyCompleted
                ? replayMessage(runReward: runReward, summary: summary)
                : rewardMessage(prefix: "Next contract unlocked.", coinsAwarded: result.rewardCoins, summary: summary)
            return RunOutcome(
                title: "Contract Complete",
                message: message,
                completed: true,
                coinsAwarded: result.rewardCoins + summary.achievementRewardCoins
            )
        }

        let failureMessage = "Best height saved. Reach \(contract.targetHeight) floors to complete this contract."
        return RunOutcome(
            title: "Contract Failed",
            message: messageWithAchievementReward(failureMessage, summary: summary),
            completed: false,
            coinsAwarded: summary.achievementRewardCoins
        )
    }

    private func recordDailyResult(
        _ contract: DailyContract,
        height: Int,
        completed: Bool?,
        resultID: UUID,
        completedAt: Date,
        perfectBlocks: Int,
        usedHelperTools: Bool,
        ratingStars: Int?,
        precisionScore: Int?,
        stabilityScore: Int?,
        efficiencyScore: Int?,
        runRewardCoins: Int
    ) -> RunOutcome {
        var updated = progress
        updated.highestBuiltHeight = max(updated.highestBuiltHeight, height)

        var record = updated.dailyRecordsByDateKey[contract.dateKey] ?? DailyProgress()
        record.bestHeight = max(record.bestHeight, height)

        let didComplete = completed ?? (height >= contract.targetHeight)
        let alreadyCompleted = record.completed
        var coinsAwarded = 0

        if didComplete {
            record.completed = true
            if !alreadyCompleted {
                coinsAwarded = contract.coinReward
            }
        }

        let runReward = didComplete ? max(0, runRewardCoins) : 0

        updated.dailyRecordsByDateKey[contract.dateKey] = record
        let result = gameResult(
            for: .daily(contract),
            height: height,
            rewardCoins: coinsAwarded + runReward,
            completed: didComplete,
            id: resultID,
            completedAt: completedAt,
            perfectBlocks: perfectBlocks,
            toolsUsed: usedHelperTools,
            ratingStars: ratingStars,
            precisionScore: precisionScore,
            stabilityScore: stabilityScore,
            efficiencyScore: efficiencyScore
        )
        let summary = applyConstructionResult(result, to: &updated)
        progress = updated

        if didComplete {
            let message = alreadyCompleted
                ? replayMessage(runReward: runReward, summary: summary)
                : rewardMessage(prefix: nil, coinsAwarded: result.rewardCoins, summary: summary)
            return RunOutcome(
                title: "Daily Complete",
                message: message,
                completed: true,
                coinsAwarded: result.rewardCoins + summary.achievementRewardCoins
            )
        }

        let failureMessage = "Best daily height saved for \(contract.dateKey)."
        return RunOutcome(
            title: "Daily Failed",
            message: messageWithAchievementReward(failureMessage, summary: summary),
            completed: false,
            coinsAwarded: summary.achievementRewardCoins
        )
    }

    private func recordBlueprintResult(
        _ challenge: BlueprintChallenge,
        height: Int,
        completed: Bool?,
        resultID: UUID,
        completedAt: Date,
        perfectBlocks: Int,
        usedHelperTools: Bool,
        ratingStars: Int?,
        precisionScore: Int?,
        stabilityScore: Int?,
        efficiencyScore: Int?,
        runRewardCoins: Int
    ) -> RunOutcome {
        var updated = progress
        updated.highestBuiltHeight = max(updated.highestBuiltHeight, height)

        var record = updated.blueprintRecordsByID[challenge.id] ?? BlueprintProgress()
        record.bestHeight = max(record.bestHeight, height)

        let didComplete = completed ?? (height >= challenge.targetHeight)
        let alreadyCompleted = record.completed
        var coinsAwarded = 0

        if didComplete {
            record.completed = true
            if !alreadyCompleted {
                coinsAwarded = challenge.coinReward
            }
        }

        let runReward = didComplete ? max(0, runRewardCoins) : 0

        updated.blueprintRecordsByID[challenge.id] = record
        let result = gameResult(
            for: .blueprint(challenge),
            height: height,
            rewardCoins: coinsAwarded + runReward,
            completed: didComplete,
            id: resultID,
            completedAt: completedAt,
            perfectBlocks: perfectBlocks,
            toolsUsed: usedHelperTools,
            ratingStars: ratingStars,
            precisionScore: precisionScore,
            stabilityScore: stabilityScore,
            efficiencyScore: efficiencyScore
        )
        let summary = applyConstructionResult(result, to: &updated)
        progress = updated

        if didComplete {
            let message = alreadyCompleted
                ? replayMessage(runReward: runReward, summary: summary)
                : rewardMessage(prefix: nil, coinsAwarded: result.rewardCoins, summary: summary)
            return RunOutcome(
                title: "Legacy Build Complete",
                message: message,
                completed: true,
                coinsAwarded: result.rewardCoins + summary.achievementRewardCoins
            )
        }

        return RunOutcome(
            title: "Legacy Build Failed",
            message: messageWithAchievementReward("Best height saved.", summary: summary),
            completed: false,
            coinsAwarded: summary.achievementRewardCoins
        )
    }

    @discardableResult
    func recordGameResult(_ result: GameResult) -> ConstructionRecordSummary {
        var updated = progress
        let summary = applyConstructionResult(result, to: &updated)
        progress = updated
        return summary
    }

    private func applyConstructionResult(_ result: GameResult, to updated: inout TowerProgress) -> ConstructionRecordSummary {
        guard !updated.recordedGameResultIDs.contains(result.id) else {
            return ConstructionRecordSummary(
                wasDuplicate: true,
                baseRewardCoins: 0,
                achievementRewardCoins: 0,
                unlockedAchievementIDs: [],
                unlockedBuildingIDs: [],
                journalEntryID: nil
            )
        }

        updated.recordedGameResultIDs.append(result.id)
        updated.recordedGameResultIDs = Array(updated.recordedGameResultIDs.suffix(100))

        let buildingName = BuildingCollectionCatalog.all.first { $0.id == result.buildingID }?.name
        let journalEntry = JournalEntry(result: result, buildingName: buildingName)
        updated.journalEntries.insert(journalEntry, at: 0)
        updated.journalEntries = Array(updated.journalEntries.prefix(20))

        updated.coins += result.rewardCoins
        updated.constructionStats.apply(result)

        let unlockedBuildings = unlockBuildings(matching: result, in: &updated)
        let unlockedAchievements = unlockEligibleAchievements(in: &updated)
        let achievementRewardCoins = unlockedAchievements.reduce(0) { $0 + $1.rewardCoins }
        updated.coins += achievementRewardCoins
        updated.normalizeConstructionProgress()

        return ConstructionRecordSummary(
            wasDuplicate: false,
            baseRewardCoins: result.rewardCoins,
            achievementRewardCoins: achievementRewardCoins,
            unlockedAchievementIDs: unlockedAchievements.map(\.id),
            unlockedBuildingIDs: unlockedBuildings.map(\.id),
            journalEntryID: journalEntry.id
        )
    }

    private func unlockBuildings(matching result: GameResult, in updated: inout TowerProgress) -> [BuildingDefinition] {
        var newlyUnlocked: [BuildingDefinition] = []

        for building in BuildingCollectionCatalog.all where !updated.unlockedBuildingIDs.contains(building.id) {
            guard building.unlockRule.isMet(stats: updated.constructionStats, result: result) else {
                continue
            }
            updated.unlockedBuildingIDs.insert(building.id)
            newlyUnlocked.append(building)
        }

        return newlyUnlocked
    }

    private func unlockEligibleAchievements(in updated: inout TowerProgress) -> [AchievementDefinition] {
        var statesByID = Dictionary(uniqueKeysWithValues: updated.achievementStates.map { ($0.id, $0) })
        var newlyUnlocked: [AchievementDefinition] = []

        for achievement in AchievementCatalog.all {
            let state = statesByID[achievement.id] ?? AchievementState(id: achievement.id)
            guard state.unlockedAt == nil else {
                continue
            }

            guard achievement.condition.isMet(stats: updated.constructionStats, unlockedBuildingCount: updated.unlockedBuildingIDs.count) else {
                statesByID[achievement.id] = state
                continue
            }

            statesByID[achievement.id] = AchievementState(
                id: achievement.id,
                unlockedAt: Date(),
                rewardCoinsAwarded: true
            )
            newlyUnlocked.append(achievement)
        }

        updated.achievementStates = AchievementCatalog.all.map { statesByID[$0.id] ?? AchievementState(id: $0.id) }
        return newlyUnlocked
    }

    private func gameResult(
        for session: GameSession,
        height: Int,
        rewardCoins: Int,
        completed: Bool,
        id: UUID,
        completedAt: Date,
        perfectBlocks: Int,
        toolsUsed: Bool,
        ratingStars: Int?,
        precisionScore: Int?,
        stabilityScore: Int?,
        efficiencyScore: Int?
    ) -> GameResult {
        GameResult(
            id: id,
            completedAt: completedAt,
            mode: gameMode(for: session),
            floors: height,
            heightMeters: Double(height) * 4.2,
            weather: constructionWeather(for: session.weather),
            rewardCoins: rewardCoins,
            outcome: completed ? .completed : .failed,
            perfectBlocks: perfectBlocks,
            toolsUsed: toolsUsed,
            blueprintMatched: session.blueprintWidths != nil && completed,
            buildingID: buildingID(for: session),
            style: buildingStyle(for: session.material),
            difficulty: difficulty(for: session),
            timeOfDay: .day,
            ratingStars: ratingStars,
            precisionScore: precisionScore,
            stabilityScore: stabilityScore,
            efficiencyScore: efficiencyScore
        )
    }

    private func gameMode(for session: GameSession) -> GameMode {
        switch session {
        case .contract:
            return .contract
        case .daily:
            return .contract
        case .blueprint:
            return .blueprintChallenge
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

    private func difficulty(for session: GameSession) -> Int {
        min(5, max(1, Int((Double(session.targetHeight) / 6.0).rounded(.up))))
    }

    private func buildingID(for session: GameSession) -> String? {
        switch session {
        case .contract(let contract):
            switch contract.id {
            case 1:
                return "permit-house"
            case 2:
                return "riverside-brickworks"
            case 5:
                return "glass-spire"
            case 6:
                return "windbreak-stack"
            case 13:
                return "storm-core"
            case 16:
                return "skyline-twenty"
            case 20:
                return "cloudline-atrium"
            default:
                return nil
            }
        case .blueprint(let challenge):
            return challenge.id == BlueprintChallenge.featured.id ? "neon-plaza" : nil
        case .daily:
            return nil
        }
    }

    private func rewardMessage(prefix: String?, coinsAwarded: Int, summary: ConstructionRecordSummary) -> String {
        let base = prefix.map { "\($0) \(coinsAwarded) coins added." } ?? "\(coinsAwarded) coins added."
        guard summary.achievementRewardCoins > 0 else {
            return base
        }
        return "\(base) Achievement rewards added: \(summary.achievementRewardCoins)."
    }

    private func replayMessage(runReward: Int, summary: ConstructionRecordSummary) -> String {
        let base = runReward > 0
            ? "Best height saved. Run payout: \(runReward) coins."
            : "Best height saved. Contract reward was already claimed."
        guard summary.achievementRewardCoins > 0 else {
            return base
        }
        return "\(base) Achievement rewards added: \(summary.achievementRewardCoins)."
    }

    private func messageWithAchievementReward(_ message: String, summary: ConstructionRecordSummary) -> String {
        guard summary.achievementRewardCoins > 0 else {
            return message
        }
        return "\(message) Achievement rewards added: \(summary.achievementRewardCoins)."
    }
}

enum TowerProgressPersistence {
    private static let key = "TowerYard.contractProgress.v1"

    static func load(userDefaults: UserDefaults = .standard) -> TowerProgress {
        guard let data = userDefaults.data(forKey: key) else {
            return TowerProgress()
        }

        do {
            var progress = try JSONDecoder().decode(TowerProgress.self, from: data)
            progress.normalizeConstructionProgress()
            return progress
        } catch {
            return TowerProgress()
        }
    }

    static func save(_ progress: TowerProgress, userDefaults: UserDefaults = .standard) {
        var normalized = progress
        normalized.normalizeConstructionProgress()
        guard let data = try? JSONEncoder().encode(normalized) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}

extension TowerProgressStore {
    static func preview(sampleData: Bool = false) -> TowerProgressStore {
        let store = TowerProgressStore(progress: TowerProgress(), savesProgress: false)

        guard sampleData else {
            return store
        }

        store.recordGameResult(
            GameResult(
                mode: .contract,
                floors: 22,
                heightMeters: 132,
                weather: .wind,
                rewardCoins: 240,
                outcome: .completed,
                perfectBlocks: 7,
                toolsUsed: false,
                blueprintMatched: false,
                buildingID: "windbreak-stack",
                style: .steel,
                difficulty: 3,
                timeOfDay: .night
            )
        )
        return store
    }
}

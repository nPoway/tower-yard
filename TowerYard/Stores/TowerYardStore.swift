import Combine
import Foundation

struct TowerYardProgress: Codable, Equatable {
    var coins: Int
    var ownedSkinIDs: [BlockSkinID]
    var equippedSkinID: BlockSkinID
    var toolCounts: [String: Int]
    var bestHeight: Int
    var completedRuns: Int
    var totalCoinsEarned: Int

    static var initial: TowerYardProgress {
        TowerYardProgress(
            coins: 0,
            ownedSkinIDs: [.brick],
            equippedSkinID: .brick,
            toolCounts: Dictionary(uniqueKeysWithValues: GameToolID.allCases.map { ($0.rawValue, 0) }),
            bestHeight: 0,
            completedRuns: 0,
            totalCoinsEarned: 0
        )
    }

    mutating func normalize() {
        coins = max(0, coins)
        bestHeight = max(0, bestHeight)
        completedRuns = max(0, completedRuns)
        totalCoinsEarned = max(0, totalCoinsEarned)

        let allowedSkins = Set(BlockSkinID.allCases)
        var owned = Set(ownedSkinIDs.filter { allowedSkins.contains($0) })
        owned.insert(.brick)

        if !owned.contains(equippedSkinID) {
            equippedSkinID = .brick
        }

        ownedSkinIDs = BlockSkinID.allCases.filter { owned.contains($0) }

        var sanitizedTools: [String: Int] = [:]
        for id in GameToolID.allCases {
            sanitizedTools[id.rawValue] = max(0, toolCounts[id.rawValue] ?? 0)
        }
        toolCounts = sanitizedTools
    }
}

struct TowerRunResult: Equatable {
    let blocksPlaced: Int
    let stabilityScore: Double
    let usedToolIDs: [GameToolID]
    let finishedSafely: Bool
}

struct TowerRunReward: Equatable {
    let coins: Int
    let heightCoins: Int
    let stabilityCoins: Int
    let finishBonus: Int
}

enum TowerYardStoreActionResult: Equatable {
    case success
    case alreadyOwned
    case notOwned
    case insufficientCoins(missing: Int)
}

final class TowerYardStore: ObservableObject {
    @Published private(set) var progress: TowerYardProgress {
        didSet {
            persist()
        }
    }

    private let defaults: UserDefaults
    private let persistenceKey: String

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "TowerYard.progress.v1"
    ) {
        self.defaults = defaults
        self.persistenceKey = persistenceKey

        if
            let data = defaults.data(forKey: persistenceKey),
            var decoded = try? JSONDecoder().decode(TowerYardProgress.self, from: data)
        {
            decoded.normalize()
            progress = decoded
        } else {
            var initial = TowerYardProgress.initial
            initial.normalize()
            progress = initial
        }

        persist()
    }

    var coins: Int {
        progress.coins
    }

    var bestHeight: Int {
        progress.bestHeight
    }

    var completedRuns: Int {
        progress.completedRuns
    }

    var walletCoins: Int {
        coins
    }

    var bestRecord: Int {
        bestHeight
    }

    var equippedSkin: BlockSkin {
        TowerYardCatalog.skin(for: progress.equippedSkinID)
    }

    var profile: BuilderProfile {
        BuilderProfile(
            coins: coins,
            builderLevel: max(1, progress.totalCoinsEarned / 250 + 1),
            experience: progress.totalCoinsEarned,
            totalTowersBuilt: progress.completedRuns,
            highestTower: progress.bestHeight,
            contractsCompleted: 0,
            perfectBlocks: 0,
            toolsUsed: 0,
            equippedMaterial: nil,
            equippedSkin: equippedSkin.name,
            bestRecord: progress.bestHeight
        )
    }

    var favoriteMaterial: String? {
        nil
    }

    var favoriteSkin: String? {
        equippedSkin.name
    }

    var latestTowerResult: TowerResultCard? {
        nil
    }

    var towerResults: [TowerResultCard] {
        []
    }

    var journalEntries: [JournalEntry] {
        []
    }

    var unlockedBuildingCount: Int {
        0
    }

    var unlockedAchievementCount: Int {
        0
    }

    var gameTools: [GameToolState] {
        TowerYardCatalog.shopTools.map { definition in
            GameToolState(definition: definition, count: toolCount(for: definition.id))
        }
    }

    func skinState(for skinID: BlockSkinID) -> SkinOwnershipState {
        guard ownsSkin(skinID) else {
            return .locked
        }

        return progress.equippedSkinID == skinID ? .equipped : .owned
    }

    func ownsSkin(_ skinID: BlockSkinID) -> Bool {
        progress.ownedSkinIDs.contains(skinID)
    }

    func canAfford(_ price: Int) -> Bool {
        price <= progress.coins
    }

    func coinsNeeded(for price: Int) -> Int {
        max(0, price - progress.coins)
    }

    @discardableResult
    func awardCoins(_ amount: Int) -> Int {
        let coinsAwarded = max(0, amount)
        guard coinsAwarded > 0 else {
            return 0
        }

        progress.coins += coinsAwarded
        progress.totalCoinsEarned += coinsAwarded
        progress.normalize()
        return coinsAwarded
    }

    @discardableResult
    func buySkin(_ skinID: BlockSkinID) -> Bool {
        purchaseSkin(skinID) == .success
    }

    @discardableResult
    func purchaseSkin(_ skinID: BlockSkinID) -> TowerYardStoreActionResult {
        guard !ownsSkin(skinID) else {
            return .alreadyOwned
        }

        let skin = TowerYardCatalog.skin(for: skinID)
        guard spendCoins(skin.price) else {
            return .insufficientCoins(missing: coinsNeeded(for: skin.price))
        }

        progress.ownedSkinIDs.append(skinID)
        progress.normalize()
        return .success
    }

    @discardableResult
    func equipSkin(_ skinID: BlockSkinID) -> Bool {
        equipOwnedSkin(skinID) == .success
    }

    @discardableResult
    func equipOwnedSkin(_ skinID: BlockSkinID) -> TowerYardStoreActionResult {
        guard ownsSkin(skinID) else {
            return .notOwned
        }

        progress.equippedSkinID = skinID
        return .success
    }

    func toolCount(for toolID: GameToolID) -> Int {
        max(0, progress.toolCounts[toolID.rawValue] ?? 0)
    }

    func status(for feature: TowerFeature) -> TowerFeatureStatus {
        switch feature {
        case .contracts:
            TowerFeatureStatus(
                isConnected: true,
                title: "Contracts connected",
                message: "Contract progress and coin rewards are saved locally."
            )
        case .endlessTower:
            TowerFeatureStatus(
                isConnected: true,
                title: "Endless connected",
                message: "Endless Tower records height, stability, and earned coins."
            )
        case .shop:
            TowerFeatureStatus(
                isConnected: true,
                title: "Shop connected",
                message: "Coins, skins, and tool counts are saved locally."
            )
        case .achievements:
            TowerFeatureStatus(
                isConnected: true,
                title: "Achievements connected",
                message: "Milestones unlock from saved construction progress."
            )
        case .foremanChat:
            TowerFeatureStatus(
                isConnected: true,
                title: "Builder Assistant ready",
                message: "Chat-style building guidance is available in the yard."
            )
        }
    }

    func achievementProgress(for achievement: AchievementDefinition) -> AchievementProgress {
        achievement.condition.progress(
            stats: constructionStats,
            unlockedBuildingCount: unlockedBuildingCount
        )
    }

    func achievementState(for achievement: AchievementDefinition) -> AchievementState {
        AchievementState(id: achievement.id)
    }

    func isBuildingUnlocked(_ building: BuildingDefinition) -> Bool {
        false
    }

    @discardableResult
    func buyTool(_ toolID: GameToolID) -> Bool {
        purchaseTool(toolID) == .success
    }

    @discardableResult
    func purchaseTool(_ toolID: GameToolID) -> TowerYardStoreActionResult {
        let tool = TowerYardCatalog.tool(for: toolID)
        guard spendCoins(tool.price) else {
            return .insufficientCoins(missing: coinsNeeded(for: tool.price))
        }

        progress.toolCounts[toolID.rawValue, default: 0] += 1
        progress.normalize()
        return .success
    }

    @discardableResult
    func consumeTool(_ toolID: GameToolID) -> Bool {
        let currentCount = toolCount(for: toolID)
        guard currentCount > 0 else {
            return false
        }

        progress.toolCounts[toolID.rawValue] = currentCount - 1
        progress.normalize()
        return true
    }

    @discardableResult
    func recordGameResult(_ result: TowerRunResult) -> TowerRunReward {
        let reward = reward(for: result)

        progress.coins += reward.coins
        progress.totalCoinsEarned += reward.coins
        recordRunStats(result)
        progress.normalize()

        return reward
    }

    func recordRunStats(_ result: TowerRunResult) {
        progress.completedRuns += 1
        progress.bestHeight = max(progress.bestHeight, max(0, result.blocksPlaced))
        progress.normalize()
    }

    @discardableResult
    private func spendCoins(_ amount: Int) -> Bool {
        guard amount >= 0, progress.coins >= amount else {
            return false
        }

        progress.coins -= amount
        return true
    }

    private func reward(for result: TowerRunResult) -> TowerRunReward {
        let blocks = max(0, result.blocksPlaced)
        let stability = min(1, max(0, result.stabilityScore))
        let heightCoins = blocks * 24
        let stabilityCoins = Int((Double(blocks) * stability * 10).rounded())
        let finishBonus = result.finishedSafely && blocks > 0 ? 25 : 0
        let coins = max(0, heightCoins + stabilityCoins + finishBonus)

        return TowerRunReward(
            coins: coins,
            heightCoins: heightCoins,
            stabilityCoins: stabilityCoins,
            finishBonus: finishBonus
        )
    }

    private var constructionStats: ConstructionStats {
        var stats = ConstructionStats()
        stats.recordedResults = progress.completedRuns
        stats.successfulResults = progress.completedRuns
        stats.maxFloors = progress.bestHeight
        stats.maxHeightMeters = Double(progress.bestHeight) * 3
        stats.totalBaseRewardCoins = progress.totalCoinsEarned
        return stats
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(progress) else {
            return
        }

        defaults.set(data, forKey: persistenceKey)
    }
}

extension TowerYardStore {
    static var preview: TowerYardStore {
        let defaults = UserDefaults(suiteName: "TowerYard.preview.\(UUID().uuidString)") ?? .standard
        let store = TowerYardStore(defaults: defaults, persistenceKey: "TowerYard.preview.progress")
        store.progress.coins = 520
        store.progress.ownedSkinIDs = [.brick, .concrete, .wood]
        store.progress.equippedSkinID = .wood
        store.progress.toolCounts = [
            GameToolID.levelingHammer.rawValue: 2,
            GameToolID.safetyNet.rawValue: 1,
            GameToolID.foundationBooster.rawValue: 1,
            GameToolID.craneSlowdown.rawValue: 3
        ]
        store.progress.bestHeight = 8
        store.progress.normalize()
        return store
    }

    static func preview(sampleData: Bool) -> TowerYardStore {
        guard sampleData else {
            return TowerYardStore()
        }

        return preview
    }
}

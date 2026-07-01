import Combine
import Foundation

final class TowerYardProfileStore: ObservableObject {
    @Published private(set) var profile: BuilderProfile
    @Published private(set) var towerResults: [TowerResultCard]

    private let persistence: any TowerYardPersistence
    private let featureAvailability: any TowerFeatureAvailabilityProviding
    private let galleryLimit = 30

    init(
        persistence: any TowerYardPersistence = UserDefaultsTowerYardPersistence(),
        featureAvailability: any TowerFeatureAvailabilityProviding = PlaceholderFeatureAvailabilityProvider()
    ) {
        let snapshot = persistence.loadSnapshot()
        self.profile = snapshot.profile
        self.towerResults = snapshot.towerResults.sorted { $0.date > $1.date }
        self.persistence = persistence
        self.featureAvailability = featureAvailability
    }

    var latestTowerResult: TowerResultCard? {
        towerResults.first
    }

    var journalEntries: [JournalEntry] {
        gameResults.prefix(20).map { result in
            JournalEntry(result: result, buildingName: nil)
        }
    }

    var walletCoins: Int {
        profile.coins
    }

    var bestRecord: Int {
        max(profile.bestRecord, towerResults.map(\.height).max() ?? 0)
    }

    var favoriteMaterial: String? {
        if let equippedMaterial = profile.equippedMaterial, !equippedMaterial.isEmpty {
            return equippedMaterial
        }

        return mostFrequentValue(in: towerResults.map(\.material))
    }

    var favoriteSkin: String? {
        if let equippedSkin = profile.equippedSkin, !equippedSkin.isEmpty {
            return equippedSkin
        }

        return mostFrequentValue(in: towerResults.compactMap(\.skin))
    }

    var unlockedAchievementCount: Int {
        AchievementCatalog.all.filter { achievementState(for: $0).unlockedAt != nil }.count
    }

    var unlockedBuildingCount: Int {
        BuildingCollectionCatalog.all.filter(isBuildingUnlocked).count
    }

    var constructionStats: ConstructionStats {
        var stats = ConstructionStats()
        for result in gameResults {
            stats.apply(result)
        }
        return stats
    }

    var gameResults: [GameResult] {
        towerResults.map(GameResult.init(towerResult:))
    }

    func status(for feature: TowerFeature) -> TowerFeatureStatus {
        featureAvailability.status(for: feature)
    }

    func achievementState(for definition: AchievementDefinition) -> AchievementState {
        let progress = achievementProgress(for: definition)
        guard progress.fraction >= 1 else {
            return AchievementState(id: definition.id)
        }

        return AchievementState(
            id: definition.id,
            unlockedAt: towerResults.first?.date,
            rewardCoinsAwarded: false
        )
    }

    func achievementProgress(for definition: AchievementDefinition) -> AchievementProgress {
        definition.condition.progress(stats: constructionStats, unlockedBuildingCount: unlockedBuildingCount)
    }

    func isBuildingUnlocked(_ building: BuildingDefinition) -> Bool {
        let stats = constructionStats
        switch building.unlockRule {
        case .completedObject:
            return gameResults.contains { building.unlockRule.isMet(stats: stats, result: $0) }
        default:
            return building.unlockRule.isMet(stats: stats, result: nil)
        }
    }

    func recordTowerResult(_ result: TowerResultCard) {
        profile.apply(result: result)
        towerResults.removeAll { $0.id == result.id }
        towerResults.insert(result, at: 0)

        if towerResults.count > galleryLimit {
            towerResults = Array(towerResults.prefix(galleryLimit))
        }

        save()
    }

    private func save() {
        persistence.saveSnapshot(TowerYardSnapshot(profile: profile, towerResults: towerResults))
    }

    private func mostFrequentValue(in values: [String]) -> String? {
        let trimmedValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !trimmedValues.isEmpty else {
            return nil
        }

        let counts = Dictionary(grouping: trimmedValues, by: { $0 }).mapValues(\.count)
        return counts.sorted { left, right in
            if left.value == right.value {
                return left.key < right.key
            }

            return left.value > right.value
        }.first?.key
    }
}

protocol TowerYardPersistence {
    func loadSnapshot() -> TowerYardSnapshot
    func saveSnapshot(_ snapshot: TowerYardSnapshot)
}

struct UserDefaultsTowerYardPersistence: TowerYardPersistence {
    private let key = "towerYard.snapshot.v1"
    private let defaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSnapshot() -> TowerYardSnapshot {
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? decoder.decode(TowerYardSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: TowerYardSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: key)
    }
}

private extension GameResult {
    init(towerResult: TowerResultCard) {
        self.init(
            id: towerResult.id,
            completedAt: towerResult.date,
            mode: GameMode(towerResult.mode),
            floors: towerResult.height,
            heightMeters: Double(towerResult.height),
            weather: ConstructionWeather(towerResult.weather),
            rewardCoins: 0,
            outcome: ConstructionOutcome(towerResult.outcome),
            perfectBlocks: towerResult.perfectBlocks,
            toolsUsed: towerResult.toolsUsed > 0,
            blueprintMatched: towerResult.mode == .blueprintChallenge && towerResult.outcome == .completed,
            buildingID: nil,
            style: BuildingStyle(materialName: towerResult.material),
            difficulty: 1,
            timeOfDay: towerResult.weather == .nightShift ? .night : .day
        )
    }
}

private extension GameMode {
    init(_ mode: YardPlayMode) {
        switch mode {
        case .contracts:
            self = .contract
        case .endlessTower:
            self = .endless
        case .blueprintChallenge:
            self = .blueprintChallenge
        case .zenBuild:
            self = .zen
        }
    }
}

private extension ConstructionWeather {
    init(_ weather: TowerWeather) {
        switch weather {
        case .clear:
            self = .clear
        case .windy:
            self = .wind
        case .rainy:
            self = .rain
        case .foggy:
            self = .fog
        case .nightShift:
            self = .clear
        }
    }
}

private extension ConstructionOutcome {
    init(_ outcome: TowerBuildOutcome) {
        switch outcome {
        case .completed, .toppedOut:
            self = .completed
        case .toppled:
            self = .failed
        case .abandoned:
            self = .abandoned
        }
    }
}

private extension BuildingStyle {
    init(materialName: String) {
        let normalized = materialName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self = BuildingStyle.allCases.first { style in
            style.title.lowercased() == normalized || style.rawValue == normalized
        } ?? .brick
    }
}

extension TowerYardProfileStore {
    static func preview(sampleData: Bool = false) -> TowerYardProfileStore {
        let suiteName = "TowerYard.profile.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        let store = TowerYardProfileStore(
            persistence: UserDefaultsTowerYardPersistence(defaults: defaults)
        )

        guard sampleData else {
            return store
        }

        store.recordTowerResult(
            TowerResultCard(
                mode: .contracts,
                height: 18,
                weather: .windy,
                material: "Steel",
                skin: "Glass",
                outcome: .completed,
                score: 820,
                perfectBlocks: 6,
                toolsUsed: 0
            )
        )
        store.recordTowerResult(
            TowerResultCard(
                mode: .contracts,
                height: 12,
                weather: .clear,
                material: "Glass",
                skin: "Brick",
                outcome: .completed,
                score: 610,
                perfectBlocks: 4,
                toolsUsed: 1
            )
        )

        return store
    }
}

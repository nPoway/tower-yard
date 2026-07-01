import Foundation

struct AchievementDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let condition: AchievementCondition
    let rewardCoins: Int
}

struct AchievementState: Codable, Identifiable, Equatable {
    let id: String
    var unlockedAt: Date?
    var rewardCoinsAwarded: Bool

    init(id: String, unlockedAt: Date? = nil, rewardCoinsAwarded: Bool = false) {
        self.id = id
        self.unlockedAt = unlockedAt
        self.rewardCoinsAwarded = rewardCoinsAwarded
    }
}

struct AchievementProgress: Equatable {
    let current: Int
    let target: Int

    var fraction: Double {
        guard target > 0 else {
            return 1
        }
        return min(1, Double(current) / Double(target))
    }

    var label: String {
        "\(min(current, target))/\(target)"
    }
}

enum AchievementCondition: Equatable {
    case completedContracts(Int)
    case maxFloors(Int)
    case completedWeather(ConstructionWeather)
    case noToolsCompletions(Int)
    case perfectBlocks(Int)
    case completedStyle(BuildingStyle)
    case nightBuilds(Int)
    case endlessRuns(Int)
    case totalBaseRewardCoins(Int)
    case unlockedBuildings(Int)
    case recordedResults(Int)
    case heightMeters(Int)
    case difficulty(Int)
    case completedWeatherCount(Int)

    var title: String {
        switch self {
        case .completedContracts(let target):
            return target == 1 ? "Complete 1 contract" : "Complete \(target) contracts"
        case .maxFloors(let target):
            return "Reach \(target) floors"
        case .completedWeather(let weather):
            return "Complete a build in \(weather.title.lowercased())"
        case .noToolsCompletions(let target):
            return target == 1 ? "Complete 1 build without tools" : "Complete \(target) builds without tools"
        case .perfectBlocks(let target):
            return "Place \(target) perfect blocks in one result"
        case .completedStyle(let style):
            return "Complete a \(style.title.lowercased()) tower"
        case .nightBuilds(let target):
            return target == 1 ? "Complete 1 night build" : "Complete \(target) night builds"
        case .endlessRuns(let target):
            return target == 1 ? "Finish 1 endless run" : "Finish \(target) endless runs"
        case .totalBaseRewardCoins(let target):
            return "Earn \(target) coins from results"
        case .unlockedBuildings(let target):
            return "Unlock \(target) buildings"
        case .recordedResults(let target):
            return "Record \(target) build results"
        case .heightMeters(let target):
            return "Reach \(target)m height"
        case .difficulty(let target):
            return "Complete difficulty \(target)"
        case .completedWeatherCount(let target):
            return "Complete builds in \(target) weather types"
        }
    }

    func progress(stats: ConstructionStats, unlockedBuildingCount: Int) -> AchievementProgress {
        switch self {
        case .completedContracts(let target):
            return AchievementProgress(current: stats.completedContracts, target: target)
        case .maxFloors(let target):
            return AchievementProgress(current: stats.maxFloors, target: target)
        case .completedWeather(let weather):
            return AchievementProgress(current: stats.hasCompleted(weather: weather) ? 1 : 0, target: 1)
        case .noToolsCompletions(let target):
            return AchievementProgress(current: stats.noToolsCompletions, target: target)
        case .perfectBlocks(let target):
            return AchievementProgress(current: stats.bestPerfectBlockStreak, target: target)
        case .completedStyle(let style):
            return AchievementProgress(current: stats.hasCompleted(style: style) ? 1 : 0, target: 1)
        case .nightBuilds(let target):
            return AchievementProgress(current: stats.nightBuilds, target: target)
        case .endlessRuns(let target):
            return AchievementProgress(current: stats.endlessRuns, target: target)
        case .totalBaseRewardCoins(let target):
            return AchievementProgress(current: stats.totalBaseRewardCoins, target: target)
        case .unlockedBuildings(let target):
            return AchievementProgress(current: unlockedBuildingCount, target: target)
        case .recordedResults(let target):
            return AchievementProgress(current: stats.recordedResults, target: target)
        case .heightMeters(let target):
            return AchievementProgress(current: Int(stats.maxHeightMeters.rounded(.down)), target: target)
        case .difficulty(let target):
            return AchievementProgress(current: stats.highestDifficultyCompleted, target: target)
        case .completedWeatherCount(let target):
            return AchievementProgress(current: stats.completedWeatherRawValues.count, target: target)
        }
    }

    func isMet(stats: ConstructionStats, unlockedBuildingCount: Int) -> Bool {
        progress(stats: stats, unlockedBuildingCount: unlockedBuildingCount).fraction >= 1
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first-contract",
            title: "First Contract",
            description: "Finish your first paid construction contract.",
            condition: .completedContracts(1),
            rewardCoins: 75
        ),
        AchievementDefinition(
            id: "twenty-floors",
            title: "20 Floors",
            description: "Stack a tower that reaches the twentieth floor.",
            condition: .maxFloors(20),
            rewardCoins: 120
        ),
        AchievementDefinition(
            id: "built-in-the-wind",
            title: "Built in the Wind",
            description: "Complete a build while wind is active.",
            condition: .completedWeather(.wind),
            rewardCoins: 90
        ),
        AchievementDefinition(
            id: "no-tools-needed",
            title: "No Tools Needed",
            description: "Complete a build without using any tools.",
            condition: .noToolsCompletions(1),
            rewardCoins: 100
        ),
        AchievementDefinition(
            id: "five-perfect-blocks",
            title: "Five Perfect Blocks",
            description: "Place five perfect blocks in a single result.",
            condition: .perfectBlocks(5),
            rewardCoins: 125
        ),
        AchievementDefinition(
            id: "glass-tower",
            title: "Glass Tower",
            description: "Finish a tower in the glass style.",
            condition: .completedStyle(.glass),
            rewardCoins: 110
        ),
        AchievementDefinition(
            id: "night-builder",
            title: "Night Builder",
            description: "Finish a construction run during the night shift.",
            condition: .nightBuilds(1),
            rewardCoins: 80
        ),
        AchievementDefinition(
            id: "endless-rookie",
            title: "Endless Rookie",
            description: "Complete your first endless run.",
            condition: .endlessRuns(1),
            rewardCoins: 70
        ),
        AchievementDefinition(
            id: "rain-ready",
            title: "Rain Ready",
            description: "Complete a build while rain is active.",
            condition: .completedWeather(.rain),
            rewardCoins: 95
        ),
        AchievementDefinition(
            id: "storm-certified",
            title: "Storm Certified",
            description: "Complete a build during storm weather.",
            condition: .completedWeather(.storm),
            rewardCoins: 140
        ),
        AchievementDefinition(
            id: "contract-streak",
            title: "Contract Streak",
            description: "Complete five contracts.",
            condition: .completedContracts(5),
            rewardCoins: 180
        ),
        AchievementDefinition(
            id: "high-rise-crew",
            title: "High-Rise Crew",
            description: "Reach a height of 120 meters.",
            condition: .heightMeters(120),
            rewardCoins: 150
        ),
        AchievementDefinition(
            id: "precision-foreman",
            title: "Precision Foreman",
            description: "Place ten perfect blocks in a single result.",
            condition: .perfectBlocks(10),
            rewardCoins: 200
        ),
        AchievementDefinition(
            id: "high-rise-regular",
            title: "High-Rise Regular",
            description: "Reach a height of 80 meters.",
            condition: .heightMeters(80),
            rewardCoins: 210
        ),
        AchievementDefinition(
            id: "coin-reserve",
            title: "Coin Reserve",
            description: "Earn 1,000 coins from construction results.",
            condition: .totalBaseRewardCoins(1_000),
            rewardCoins: 220
        ),
        AchievementDefinition(
            id: "collection-starter",
            title: "Collection Starter",
            description: "Unlock three building cards.",
            condition: .unlockedBuildings(3),
            rewardCoins: 150
        ),
        AchievementDefinition(
            id: "all-weather-builder",
            title: "All-Weather Builder",
            description: "Complete builds in four different weather types.",
            condition: .completedWeatherCount(4),
            rewardCoins: 260
        ),
        AchievementDefinition(
            id: "master-contractor",
            title: "Master Contractor",
            description: "Complete ten contracts.",
            condition: .completedContracts(10),
            rewardCoins: 300
        )
    ]
}

import Foundation

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case contract
    case endless
    case blueprintChallenge
    case zen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contract:
            return "Contract"
        case .endless:
            return "Endless"
        case .blueprintChallenge:
            return "Legacy Build"
        case .zen:
            return "Legacy Build"
        }
    }
}

enum ConstructionWeather: String, Codable, CaseIterable, Identifiable {
    case clear
    case wind
    case rain
    case fog
    case snow
    case storm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear:
            return "Clear"
        case .wind:
            return "Wind"
        case .rain:
            return "Rain"
        case .fog:
            return "Fog"
        case .snow:
            return "Snow"
        case .storm:
            return "Storm"
        }
    }
}

enum ConstructionOutcome: String, Codable, CaseIterable, Identifiable {
    case completed
    case failed
    case abandoned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .abandoned:
            return "Abandoned"
        }
    }
}

enum BuildingStyle: String, Codable, CaseIterable, Identifiable {
    case brick
    case glass
    case steel
    case timber
    case concrete
    case artDeco
    case modular
    case neon
    case industrial
    case classic
    case eco
    case brutalist

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brick:
            return "Brick"
        case .glass:
            return "Glass"
        case .steel:
            return "Steel"
        case .timber:
            return "Timber"
        case .concrete:
            return "Concrete"
        case .artDeco:
            return "Art Deco"
        case .modular:
            return "Modular"
        case .neon:
            return "Neon"
        case .industrial:
            return "Industrial"
        case .classic:
            return "Classic"
        case .eco:
            return "Eco"
        case .brutalist:
            return "Brutalist"
        }
    }
}

enum ConstructionTimeOfDay: String, Codable, CaseIterable, Identifiable {
    case day
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "Day"
        case .night:
            return "Night"
        }
    }
}

struct GameResult: Codable, Identifiable, Equatable {
    var id: UUID
    var completedAt: Date
    var mode: GameMode
    var floors: Int
    var heightMeters: Double
    var weather: ConstructionWeather
    var rewardCoins: Int
    var outcome: ConstructionOutcome
    var perfectBlocks: Int
    var toolsUsed: Bool
    var blueprintMatched: Bool
    var buildingID: String?
    var style: BuildingStyle
    var difficulty: Int
    var timeOfDay: ConstructionTimeOfDay
    var ratingStars: Int?
    var precisionScore: Int?
    var stabilityScore: Int?
    var efficiencyScore: Int?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        mode: GameMode,
        floors: Int,
        heightMeters: Double,
        weather: ConstructionWeather,
        rewardCoins: Int,
        outcome: ConstructionOutcome,
        perfectBlocks: Int,
        toolsUsed: Bool,
        blueprintMatched: Bool,
        buildingID: String? = nil,
        style: BuildingStyle,
        difficulty: Int,
        timeOfDay: ConstructionTimeOfDay,
        ratingStars: Int? = nil,
        precisionScore: Int? = nil,
        stabilityScore: Int? = nil,
        efficiencyScore: Int? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.mode = mode
        self.floors = max(0, floors)
        self.heightMeters = max(0, heightMeters)
        self.weather = weather
        self.rewardCoins = max(0, rewardCoins)
        self.outcome = outcome
        self.perfectBlocks = max(0, perfectBlocks)
        self.toolsUsed = toolsUsed
        self.blueprintMatched = blueprintMatched
        self.buildingID = buildingID
        self.style = style
        self.difficulty = max(1, difficulty)
        self.timeOfDay = timeOfDay
        self.ratingStars = ratingStars.map { min(3, max(0, $0)) }
        self.precisionScore = precisionScore.map { min(100, max(0, $0)) }
        self.stabilityScore = stabilityScore.map { min(100, max(0, $0)) }
        self.efficiencyScore = efficiencyScore.map { min(100, max(0, $0)) }
    }
}

struct JournalEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var mode: GameMode
    var floors: Int
    var heightMeters: Double
    var weather: ConstructionWeather
    var rewardCoins: Int
    var outcome: ConstructionOutcome
    var buildingName: String?
    var ratingStars: Int?
    var precisionScore: Int?
    var stabilityScore: Int?
    var efficiencyScore: Int?

    init(result: GameResult, buildingName: String?) {
        id = result.id
        date = result.completedAt
        mode = result.mode
        floors = result.floors
        heightMeters = result.heightMeters
        weather = result.weather
        rewardCoins = result.rewardCoins
        outcome = result.outcome
        self.buildingName = buildingName
        ratingStars = result.ratingStars
        precisionScore = result.precisionScore
        stabilityScore = result.stabilityScore
        efficiencyScore = result.efficiencyScore
    }
}

struct ConstructionRecordSummary: Equatable {
    let wasDuplicate: Bool
    let baseRewardCoins: Int
    let achievementRewardCoins: Int
    let unlockedAchievementIDs: [String]
    let unlockedBuildingIDs: [String]
    let journalEntryID: UUID?
}

struct ConstructionStats: Codable, Equatable {
    var recordedResults: Int = 0
    var successfulResults: Int = 0
    var completedContracts: Int = 0
    var completedBlueprintChallenges: Int = 0
    var endlessRuns: Int = 0
    var blueprintMatches: Int = 0
    var maxFloors: Int = 0
    var maxHeightMeters: Double = 0
    var totalBaseRewardCoins: Int = 0
    var bestPerfectBlockStreak: Int = 0
    var noToolsCompletions: Int = 0
    var nightBuilds: Int = 0
    var highestDifficultyCompleted: Int = 0
    var completedWeatherRawValues: [String] = []
    var completedStyleRawValues: [String] = []

    mutating func apply(_ result: GameResult) {
        recordedResults += 1

        guard result.outcome == .completed else {
            return
        }

        successfulResults += 1
        maxFloors = max(maxFloors, result.floors)
        maxHeightMeters = max(maxHeightMeters, result.heightMeters)
        totalBaseRewardCoins += result.rewardCoins
        bestPerfectBlockStreak = max(bestPerfectBlockStreak, result.perfectBlocks)
        highestDifficultyCompleted = max(highestDifficultyCompleted, result.difficulty)
        insertUnique(result.weather.rawValue, into: &completedWeatherRawValues)
        insertUnique(result.style.rawValue, into: &completedStyleRawValues)

        switch result.mode {
        case .contract:
            completedContracts += 1
        case .endless:
            endlessRuns += 1
        case .blueprintChallenge:
            completedBlueprintChallenges += 1
        case .zen:
            break
        }

        if result.blueprintMatched {
            blueprintMatches += 1
        }

        if !result.toolsUsed {
            noToolsCompletions += 1
        }

        if result.timeOfDay == .night {
            nightBuilds += 1
        }
    }

    func hasCompleted(weather: ConstructionWeather) -> Bool {
        completedWeatherRawValues.contains(weather.rawValue)
    }

    func hasCompleted(style: BuildingStyle) -> Bool {
        completedStyleRawValues.contains(style.rawValue)
    }

    private func insertUnique(_ value: String, into values: inout [String]) {
        guard !values.contains(value) else {
            return
        }
        values.append(value)
    }
}

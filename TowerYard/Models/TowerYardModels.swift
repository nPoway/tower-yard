import Foundation

enum YardPlayMode: String, CaseIterable, Identifiable, Codable, Hashable {
    case contracts
    case endlessTower
    case blueprintChallenge
    case zenBuild

    // Retained for decoding older saved results, but no longer launchable.
    static let allCases: [YardPlayMode] = [.contracts, .endlessTower]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contracts:
            "Contracts"
        case .endlessTower:
            "Endless Tower"
        case .blueprintChallenge, .zenBuild:
            "Legacy Build"
        }
    }

    var subtitle: String {
        switch self {
        case .contracts:
            "Take a job from the yard board."
        case .endlessTower:
            "Stack as high as the crane can reach."
        case .blueprintChallenge, .zenBuild:
            "Saved result from an earlier build route."
        }
    }

}

enum TowerFeature: String, Codable, Hashable {
    case contracts
    case endlessTower
    case shop
    case achievements
    case foremanChat
}

struct TowerFeatureStatus: Equatable {
    var isConnected: Bool
    var title: String
    var message: String
}

protocol TowerFeatureAvailabilityProviding {
    func status(for feature: TowerFeature) -> TowerFeatureStatus
}

struct PlaceholderFeatureAvailabilityProvider: TowerFeatureAvailabilityProviding {
    func status(for feature: TowerFeature) -> TowerFeatureStatus {
        switch feature {
        case .contracts:
            TowerFeatureStatus(
                isConnected: true,
                title: "Contracts connected",
                message: "Contract jobs, progress, and rewards are saved locally."
            )
        case .endlessTower:
            TowerFeatureStatus(
                isConnected: true,
                title: "Endless connected",
                message: "Endless Tower launches directly from Quick Launch."
            )
        case .shop:
            TowerFeatureStatus(
                isConnected: true,
                title: "Shop connected",
                message: "Coins, block skins, and construction tools are saved locally."
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
}

enum TowerWeather: String, CaseIterable, Identifiable, Codable, Hashable {
    case clear
    case windy
    case rainy
    case foggy
    case nightShift

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear:
            "Clear"
        case .windy:
            "Windy"
        case .rainy:
            "Rainy"
        case .foggy:
            "Foggy"
        case .nightShift:
            "Night Shift"
        }
    }
}

enum TowerBuildOutcome: String, CaseIterable, Identifiable, Codable, Hashable {
    case completed
    case toppedOut
    case toppled
    case abandoned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completed:
            "Completed"
        case .toppedOut:
            "Topped Out"
        case .toppled:
            "Toppled"
        case .abandoned:
            "Abandoned"
        }
    }
}

struct TowerResultCard: Identifiable, Codable, Hashable {
    var id: UUID
    var mode: YardPlayMode
    var height: Int
    var weather: TowerWeather
    var date: Date
    var material: String
    var skin: String?
    var outcome: TowerBuildOutcome
    var score: Int
    var perfectBlocks: Int
    var toolsUsed: Int

    init(
        id: UUID = UUID(),
        mode: YardPlayMode,
        height: Int,
        weather: TowerWeather,
        date: Date = Date(),
        material: String,
        skin: String? = nil,
        outcome: TowerBuildOutcome,
        score: Int,
        perfectBlocks: Int,
        toolsUsed: Int
    ) {
        self.id = id
        self.mode = mode
        self.height = height
        self.weather = weather
        self.date = date
        self.material = material
        self.skin = skin
        self.outcome = outcome
        self.score = score
        self.perfectBlocks = perfectBlocks
        self.toolsUsed = toolsUsed
    }
}

struct BuilderProfile: Codable, Equatable {
    var coins: Int
    var builderLevel: Int
    var experience: Int
    var totalTowersBuilt: Int
    var highestTower: Int
    var contractsCompleted: Int
    var perfectBlocks: Int
    var toolsUsed: Int
    var equippedMaterial: String?
    var equippedSkin: String?
    var bestRecord: Int

    static let empty = BuilderProfile(
        coins: 0,
        builderLevel: 1,
        experience: 0,
        totalTowersBuilt: 0,
        highestTower: 0,
        contractsCompleted: 0,
        perfectBlocks: 0,
        toolsUsed: 0,
        equippedMaterial: nil,
        equippedSkin: nil,
        bestRecord: 0
    )

    var rankTitle: String {
        switch builderLevel {
        case 1...2:
            "Yard Apprentice"
        case 3...5:
            "Beam Setter"
        case 6...9:
            "Crane Operator"
        case 10...14:
            "Tower Foreman"
        default:
            "Skyline Chief"
        }
    }

    var currentLevelExperienceFloor: Int {
        max(0, (builderLevel - 1) * 100)
    }

    var nextLevelExperience: Int {
        max(100, builderLevel * 100)
    }

    var experienceIntoLevel: Int {
        max(0, experience - currentLevelExperienceFloor)
    }

    var experienceNeededForNextLevel: Int {
        max(1, nextLevelExperience - currentLevelExperienceFloor)
    }

    var progressToNextLevel: Double {
        min(1, Double(experienceIntoLevel) / Double(experienceNeededForNextLevel))
    }

    mutating func apply(result: TowerResultCard) {
        totalTowersBuilt += 1
        highestTower = max(highestTower, result.height)
        bestRecord = max(bestRecord, result.height)
        perfectBlocks += result.perfectBlocks
        toolsUsed += result.toolsUsed

        if result.mode == .contracts, result.outcome == .completed || result.outcome == .toppedOut {
            contractsCompleted += 1
        }

        let earnedExperience = max(10, result.height * 2 + result.perfectBlocks * 3 + result.score / 25)
        experience += earnedExperience
        builderLevel = max(1, experience / 100 + 1)
    }
}

struct TowerYardSnapshot: Codable, Equatable {
    var profile: BuilderProfile
    var towerResults: [TowerResultCard]

    static let empty = TowerYardSnapshot(profile: .empty, towerResults: [])
}

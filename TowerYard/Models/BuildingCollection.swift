import Foundation

struct BuildingDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let style: BuildingStyle
    let description: String
    let heightBand: String
    let difficulty: Int
    let unlockRule: BuildingUnlockRule
}

enum BuildingUnlockRule: Equatable {
    case completedObject(id: String)
    case completedContracts(Int)
    case completedStyle(BuildingStyle)
    case completedWeather(ConstructionWeather)
    case floors(Int)
    case heightMeters(Int)
    case difficulty(Int)
    case nightBuilds(Int)
    case endlessRuns(Int)

    var title: String {
        switch self {
        case .completedObject:
            return "Complete its assigned contract."
        case .completedContracts(let target):
            return target == 1 ? "Complete 1 contract." : "Complete \(target) contracts."
        case .completedStyle(let style):
            return "Complete a \(style.title.lowercased()) build."
        case .completedWeather(let weather):
            return "Complete a build in \(weather.title.lowercased())."
        case .floors(let target):
            return "Reach \(target) floors."
        case .heightMeters(let target):
            return "Reach \(target)m height."
        case .difficulty(let target):
            return "Complete difficulty \(target)."
        case .nightBuilds(let target):
            return target == 1 ? "Complete 1 night build." : "Complete \(target) night builds."
        case .endlessRuns(let target):
            return target == 1 ? "Finish 1 endless run." : "Finish \(target) endless runs."
        }
    }

    func isMet(stats: ConstructionStats, result: GameResult?) -> Bool {
        switch self {
        case .completedObject(let id):
            return result?.outcome == .completed && result?.buildingID == id
        case .completedContracts(let target):
            return stats.completedContracts >= target
        case .completedStyle(let style):
            return stats.hasCompleted(style: style)
        case .completedWeather(let weather):
            return stats.hasCompleted(weather: weather)
        case .floors(let target):
            return stats.maxFloors >= target
        case .heightMeters(let target):
            return Int(stats.maxHeightMeters.rounded(.down)) >= target
        case .difficulty(let target):
            return stats.highestDifficultyCompleted >= target
        case .nightBuilds(let target):
            return stats.nightBuilds >= target
        case .endlessRuns(let target):
            return stats.endlessRuns >= target
        }
    }
}

enum BuildingCollectionCatalog {
    static let all: [BuildingDefinition] = [
        BuildingDefinition(
            id: "permit-house",
            name: "Permit House",
            style: .classic,
            description: "A compact first-site landmark with clean roof lines.",
            heightBand: "Low",
            difficulty: 1,
            unlockRule: .completedContracts(1)
        ),
        BuildingDefinition(
            id: "riverside-brickworks",
            name: "Riverside Brickworks",
            style: .brick,
            description: "Warm masonry blocks built for stable early contracts.",
            heightBand: "Low",
            difficulty: 2,
            unlockRule: .completedObject(id: "riverside-brickworks")
        ),
        BuildingDefinition(
            id: "windbreak-stack",
            name: "Windbreak Stack",
            style: .steel,
            description: "A narrow steel tower tuned for gusty construction days.",
            heightBand: "Medium",
            difficulty: 3,
            unlockRule: .completedWeather(.wind)
        ),
        BuildingDefinition(
            id: "glass-spire",
            name: "Glass Spire",
            style: .glass,
            description: "A reflective glass tower with tight alignment demands.",
            heightBand: "Medium",
            difficulty: 3,
            unlockRule: .completedStyle(.glass)
        ),
        BuildingDefinition(
            id: "night-crane-loft",
            name: "Night Crane Loft",
            style: .industrial,
            description: "A late-shift build marked by crane lights and stacked decks.",
            heightBand: "Medium",
            difficulty: 3,
            unlockRule: .nightBuilds(1)
        ),
        BuildingDefinition(
            id: "modular-yard-tower",
            name: "Modular Yard Tower",
            style: .modular,
            description: "Repeatable modules that reward steady contract progress.",
            heightBand: "Medium",
            difficulty: 3,
            unlockRule: .completedContracts(3)
        ),
        BuildingDefinition(
            id: "storm-core",
            name: "Storm Core",
            style: .brutalist,
            description: "A heavy concrete core earned through storm work.",
            heightBand: "Tall",
            difficulty: 4,
            unlockRule: .completedWeather(.storm)
        ),
        BuildingDefinition(
            id: "skyline-twenty",
            name: "Skyline Twenty",
            style: .concrete,
            description: "A vertical milestone tower for twenty-floor builders.",
            heightBand: "Tall",
            difficulty: 4,
            unlockRule: .floors(20)
        ),
        BuildingDefinition(
            id: "timber-frame-hall",
            name: "Timber Frame Hall",
            style: .timber,
            description: "A warm-frame build with careful weight distribution.",
            heightBand: "Low",
            difficulty: 2,
            unlockRule: .completedStyle(.timber)
        ),
        BuildingDefinition(
            id: "foundry-stack",
            name: "Foundry Stack",
            style: .industrial,
            description: "A difficult metalwork tower unlocked by tougher jobs.",
            heightBand: "Tall",
            difficulty: 4,
            unlockRule: .difficulty(4)
        ),
        BuildingDefinition(
            id: "neon-plaza",
            name: "Neon Plaza",
            style: .neon,
            description: "A bright plaza reward for sustained contract progress.",
            heightBand: "Medium",
            difficulty: 4,
            unlockRule: .completedContracts(5)
        ),
        BuildingDefinition(
            id: "cloudline-atrium",
            name: "Cloudline Atrium",
            style: .eco,
            description: "A high-altitude green atrium for elite height records.",
            heightBand: "Very Tall",
            difficulty: 5,
            unlockRule: .heightMeters(160)
        )
    ]
}

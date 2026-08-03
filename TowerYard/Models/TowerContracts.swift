import CoreGraphics
import Foundation

enum ContractWeather: String, CaseIterable, Codable, Hashable, Identifiable {
    case clear
    case breeze
    case crosswind
    case gusts
    case rain
    case fog
    case storm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clear: "Clear"
        case .breeze: "Light Breeze"
        case .crosswind: "Crosswind"
        case .gusts: "Gusts"
        case .rain: "Rain"
        case .fog: "Fog"
        case .storm: "Storm"
        }
    }

    var symbolName: String {
        switch self {
        case .clear: "sun.max.fill"
        case .breeze: "wind"
        case .crosswind: "arrow.left.and.right"
        case .gusts: "tornado"
        case .rain: "cloud.rain.fill"
        case .fog: "cloud.fog.fill"
        case .storm: "cloud.bolt.rain.fill"
        }
    }
}

enum ContractMaterialStyle: String, CaseIterable, Codable, Hashable, Identifiable {
    case timber
    case brick
    case concrete
    case steel
    case glass
    case composite
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .timber: "Timber"
        case .brick: "Brick"
        case .concrete: "Concrete"
        case .steel: "Steel"
        case .glass: "Glass"
        case .composite: "Composite"
        case .mixed: "Mixed"
        }
    }
}

enum DailyBuildModifier: String, CaseIterable, Codable, Hashable, Identifiable {
    case precisionPayday
    case safetyInspection
    case reinforcedFoundation
    case fastCrane

    var id: String { rawValue }

    var title: String {
        switch self {
        case .precisionPayday: "Precision Payday"
        case .safetyInspection: "Safety Inspection"
        case .reinforcedFoundation: "Reinforced Foundation"
        case .fastCrane: "Fast Crane"
        }
    }

    var detail: String {
        switch self {
        case .precisionPayday:
            "Perfect placements earn extra run coins."
        case .safetyInspection:
            "Helper tools are not allowed on this site."
        case .reinforcedFoundation:
            "The first four drops get extra foundation tolerance."
        case .fastCrane:
            "The crane moves faster for the whole order."
        }
    }

    var systemImage: String {
        switch self {
        case .precisionPayday: "scope"
        case .safetyInspection: "checkmark.shield.fill"
        case .reinforcedFoundation: "building.columns.fill"
        case .fastCrane: "bolt.fill"
        }
    }

    var allowsHelperTools: Bool {
        self != .safetyInspection
    }

    var perfectPlacementCoinBonus: Int {
        self == .precisionPayday ? 2 : 0
    }

    var foundationAssist: CGFloat {
        self == .reinforcedFoundation ? 0.18 : 0
    }

    var craneSpeedMultiplier: CGFloat {
        self == .fastCrane ? 1.22 : 1
    }

    func completionBonus(perfectBlocks: Int, helperToolUses: Int) -> Int {
        switch self {
        case .precisionPayday:
            return perfectBlocks >= 3 ? 28 : 0
        case .safetyInspection:
            return helperToolUses == 0 ? 35 : 0
        case .reinforcedFoundation:
            return 22
        case .fastCrane:
            return 25
        }
    }
}

struct TowerContract: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let targetHeight: Int
    let weather: ContractWeather
    let material: ContractMaterialStyle
    let coinReward: Int
    let goal: String
    let rule: String
}

enum ContractCatalog {
    static let all: [TowerContract] = [
        TowerContract(id: 1, title: "Starter Scaffold", targetHeight: 5, weather: .clear, material: .timber, coinReward: 60, goal: "Build 5 floors", rule: "Keep the tower upright with basic timber blocks."),
        TowerContract(id: 2, title: "Eight Floor Order", targetHeight: 8, weather: .clear, material: .brick, coinReward: 80, goal: "Build 8 floors", rule: "Reach the height target with heavier brick parts."),
        TowerContract(id: 3, title: "Tool-Free Trial", targetHeight: 8, weather: .breeze, material: .timber, coinReward: 95, goal: "Do not use tools", rule: "Complete the order without helper tools."),
        TowerContract(id: 4, title: "Rainy Row Houses", targetHeight: 9, weather: .rain, material: .concrete, coinReward: 110, goal: "Build 9 floors in rain", rule: "Handle slick concrete sections during light rain."),
        TowerContract(id: 5, title: "Glass Lobby", targetHeight: 10, weather: .clear, material: .glass, coinReward: 125, goal: "Use glass blocks", rule: "Finish with fragile glass pieces in the build set."),
        TowerContract(id: 6, title: "Wind Check", targetHeight: 10, weather: .crosswind, material: .steel, coinReward: 140, goal: "Endure crosswind", rule: "Keep the stack standing while wind pushes sideways."),
        TowerContract(id: 7, title: "Narrow Corner Lot", targetHeight: 12, weather: .breeze, material: .brick, coinReward: 160, goal: "Build 12 floors", rule: "Work with a tighter footprint and less margin."),
        TowerContract(id: 8, title: "Fog Line", targetHeight: 12, weather: .fog, material: .composite, coinReward: 175, goal: "Build through fog", rule: "Finish the order with reduced visibility."),
        TowerContract(id: 9, title: "Glass Spine", targetHeight: 13, weather: .crosswind, material: .glass, coinReward: 195, goal: "Use glass in wind", rule: "Reach the target with fragile parts under crosswind."),
        TowerContract(id: 10, title: "No-Tool Midrise", targetHeight: 14, weather: .rain, material: .steel, coinReward: 215, goal: "No tools for 14 floors", rule: "Complete a wet steel build without helper tools."),
        TowerContract(id: 11, title: "Gust Alley", targetHeight: 15, weather: .gusts, material: .concrete, coinReward: 235, goal: "Withstand gusts", rule: "Survive stronger bursts while stacking dense blocks."),
        TowerContract(id: 12, title: "Mixed Materials", targetHeight: 16, weather: .breeze, material: .mixed, coinReward: 255, goal: "Build with mixed parts", rule: "Balance different weights in one contract."),
        TowerContract(id: 13, title: "Storm Prep", targetHeight: 17, weather: .storm, material: .steel, coinReward: 280, goal: "Build 17 floors in storm", rule: "Hold a steel tower through rain and lightning."),
        TowerContract(id: 14, title: "Thin Tower", targetHeight: 18, weather: .crosswind, material: .composite, coinReward: 305, goal: "Keep a slim profile", rule: "Reach 18 floors with a narrow construction plan."),
        TowerContract(id: 15, title: "Glass Crown", targetHeight: 19, weather: .gusts, material: .glass, coinReward: 330, goal: "Finish with glass", rule: "Place fragile upper floors while gusts intensify."),
        TowerContract(id: 16, title: "Concrete Monolith", targetHeight: 20, weather: .fog, material: .concrete, coinReward: 355, goal: "Build 20 floors", rule: "Lift heavy concrete sections past the fog line."),
        TowerContract(id: 17, title: "Tool-Free Highrise", targetHeight: 21, weather: .crosswind, material: .mixed, coinReward: 385, goal: "No tools above 20 floors", rule: "Complete a high target without helper tools."),
        TowerContract(id: 18, title: "Storm Needle", targetHeight: 23, weather: .storm, material: .steel, coinReward: 420, goal: "Reach 23 floors", rule: "Build a tall steel stack in severe weather."),
        TowerContract(id: 19, title: "Composite Skyline", targetHeight: 25, weather: .gusts, material: .composite, coinReward: 460, goal: "Build 25 floors", rule: "Use advanced parts with late-run gust pressure."),
        TowerContract(id: 20, title: "Skyline Commission", targetHeight: 28, weather: .storm, material: .mixed, coinReward: 520, goal: "Complete the final skyline order", rule: "Balance mixed materials through the hardest contract.")
    ]

    static var maxID: Int {
        all.map(\.id).max() ?? 1
    }
}

struct DailyContract: Identifiable, Codable, Hashable {
    let id: String
    let dateKey: String
    let title: String
    let targetHeight: Int
    let weather: ContractWeather
    let material: ContractMaterialStyle
    let modifier: DailyBuildModifier
    let coinReward: Int
    let goal: String

    static func generate(for date: Date, calendar: Calendar = .current) -> DailyContract {
        let key = dateKey(for: date, calendar: calendar)
        var generator = SeededDailyGenerator(seed: seed(for: date, calendar: calendar))
        let weather = ContractWeather.allCases[generator.next(upperBound: ContractWeather.allCases.count)]
        let material = ContractMaterialStyle.allCases[generator.next(upperBound: ContractMaterialStyle.allCases.count)]
        let targetHeight = 9 + generator.next(upperBound: 15)
        let reward = 140 + targetHeight * 9 + generator.next(upperBound: 45)
        let modifier = DailyBuildModifier.allCases[generator.next(upperBound: DailyBuildModifier.allCases.count)]

        return DailyContract(
            id: "daily-\(key)",
            dateKey: key,
            title: "Daily Yard Order",
            targetHeight: targetHeight,
            weather: weather,
            material: material,
            modifier: modifier,
            coinReward: reward,
            goal: "Build \(targetHeight) floors before the day ends"
        )
    }

    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 2000,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    private static func seed(for date: Date, calendar: Calendar) -> UInt64 {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(components.year ?? 2000)
        let month = UInt64(components.month ?? 1)
        let day = UInt64(components.day ?? 1)
        return year * 10_000 + month * 100 + day
    }
}

struct SeededDailyGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int(state % UInt64(upperBound))
    }
}

struct BlueprintChallenge: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let targetHeight: Int
    let weather: ContractWeather
    let material: ContractMaterialStyle
    let coinReward: Int
    let silhouetteWidths: [Int]
    let goal: String

    static let featured = BlueprintChallenge(
        id: "stepped-civic-tower",
        title: "Stepped Civic Tower",
        targetHeight: 8,
        weather: .breeze,
        material: .mixed,
        coinReward: 180,
        silhouetteWidths: [6, 6, 5, 5, 4, 3, 3, 2],
        goal: "Match the stepped silhouette"
    )
}

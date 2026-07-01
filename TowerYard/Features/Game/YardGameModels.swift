import CoreGraphics
import Foundation
import SwiftUI

enum YardRunMode: String, CaseIterable, Codable, Identifiable {
    case contracts
    case endless
    case zen

    var id: String { rawValue }

    var title: String {
        switch self {
        case .contracts: "Contracts"
        case .endless: "Endless Tower"
        case .zen: "Legacy Build"
        }
    }
}

enum YardMaterial: String, CaseIterable, Codable, Identifiable {
    case timber
    case brick
    case concrete
    case steel
    case glass
    case composite
    case roofTile
    case decor

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timber: "Timber"
        case .brick: "Brick"
        case .concrete: "Concrete"
        case .steel: "Steel"
        case .glass: "Glass"
        case .composite: "Composite"
        case .roofTile: "Roof Tile"
        case .decor: "Decor"
        }
    }

    var weight: CGFloat {
        switch self {
        case .timber: 1.05
        case .brick: 1.45
        case .concrete: 1.75
        case .steel: 1.9
        case .glass: 0.92
        case .composite: 1.25
        case .roofTile: 1.18
        case .decor: 0.72
        }
    }

    var baseWidth: CGFloat {
        switch self {
        case .timber: 118
        case .brick: 126
        case .concrete: 134
        case .steel: 108
        case .glass: 94
        case .composite: 112
        case .roofTile: 138
        case .decor: 78
        }
    }

    var tint: Color {
        switch self {
        case .timber:
            Color(red: 0.78, green: 0.47, blue: 0.25)
        case .brick:
            Color(red: 0.76, green: 0.24, blue: 0.17)
        case .concrete:
            Color(red: 0.52, green: 0.53, blue: 0.5)
        case .steel:
            Color(red: 0.43, green: 0.49, blue: 0.55)
        case .glass:
            Color(red: 0.37, green: 0.68, blue: 0.88)
        case .composite:
            Color(red: 0.28, green: 0.54, blue: 0.56)
        case .roofTile:
            Color(red: 0.62, green: 0.17, blue: 0.16)
        case .decor:
            Color(red: 0.92, green: 0.67, blue: 0.22)
        }
    }
}

enum YardPieceKind: String, Codable {
    case block
    case beam
    case roof
    case window
    case decor
}

enum YardPlacementQuality: String, Codable, Equatable {
    case perfect
    case good
    case risky

    var title: String {
        switch self {
        case .perfect: "Perfect"
        case .good: "Good"
        case .risky: "Risky"
        }
    }
}

struct YardGameConfiguration: Equatable {
    var title: String
    var goal: String
    var contractIndex: Int
    var targetHeight: Int
    var weather: ContractWeather
    var material: ContractMaterialStyle
    var coinReward: Int
    var blueprintWidths: [Int]?

    static func session(_ session: GameSession) -> YardGameConfiguration {
        YardGameConfiguration(
            title: session.title,
            goal: session.goal,
            contractIndex: session.contractIndex,
            targetHeight: session.targetHeight,
            weather: session.weather,
            material: session.material,
            coinReward: session.coinReward,
            blueprintWidths: session.blueprintWidths
        )
    }
}

struct YardPiece: Identifiable, Equatable {
    let id: UUID
    var width: CGFloat
    var height: CGFloat
    var weight: CGFloat
    var material: YardMaterial
    var kind: YardPieceKind

    init(
        id: UUID = UUID(),
        width: CGFloat,
        height: CGFloat,
        weight: CGFloat,
        material: YardMaterial,
        kind: YardPieceKind
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.weight = weight
        self.material = material
        self.kind = kind
    }

    static let placeholder = YardPiece(
        width: 118,
        height: 34,
        weight: YardMaterial.timber.weight,
        material: .timber,
        kind: .block
    )
}

struct YardPlacedPiece: Codable, Equatable, Identifiable {
    var id: UUID
    var width: CGFloat
    var height: CGFloat
    var weight: CGFloat
    var material: YardMaterial
    var kind: YardPieceKind
    var centerOffset: CGFloat
    var perfect: Bool
    var quality: YardPlacementQuality

    init(
        id: UUID = UUID(),
        width: CGFloat,
        height: CGFloat,
        weight: CGFloat,
        material: YardMaterial,
        kind: YardPieceKind,
        centerOffset: CGFloat,
        perfect: Bool,
        quality: YardPlacementQuality = .good
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.weight = weight
        self.material = material
        self.kind = kind
        self.centerOffset = centerOffset
        self.perfect = perfect
        self.quality = quality
    }
}

struct YardPlacementFeedback: Equatable, Identifiable {
    var id = UUID()
    var quality: YardPlacementQuality
    var message: String
    var stabilityLevel: CGFloat
}

enum YardRoundPhase: Equatable {
    case playing
    case paused
    case won
    case lost(reason: String)

    var isTerminal: Bool {
        switch self {
        case .won, .lost:
            true
        case .playing, .paused:
            false
        }
    }
}

enum YardResultOutcome: String, Codable {
    case victory
    case defeat
    case zenSnapshot
}

struct YardGameResult: Codable, Equatable, Identifiable {
    var id: UUID
    var date: Date
    var mode: YardRunMode
    var contractIndex: Int
    var height: Int
    var perfectBlocks: Int
    var usedTools: [String]
    var coins: Int
    var score: Int
    var outcome: YardResultOutcome
}

extension GameSession {
    var contractIndex: Int {
        switch self {
        case .contract(let contract):
            contract.id
        case .daily:
            0
        case .blueprint:
            0
        }
    }
}

extension ContractWeather {
    var windIntensity: CGFloat {
        switch self {
        case .clear: 0.05
        case .breeze: 0.35
        case .crosswind: 0.68
        case .gusts: 0.86
        case .rain: 0.24
        case .fog: 0.14
        case .storm: 1.05
        }
    }

    var gripPenalty: CGFloat {
        switch self {
        case .clear: 0
        case .breeze: 0.02
        case .crosswind: 0.05
        case .gusts: 0.08
        case .rain: 0.18
        case .fog: 0.07
        case .storm: 0.24
        }
    }
}

extension ContractMaterialStyle {
    var primaryYardMaterial: YardMaterial {
        switch self {
        case .timber: .timber
        case .brick: .brick
        case .concrete: .concrete
        case .steel: .steel
        case .glass: .glass
        case .composite: .composite
        case .mixed: .composite
        }
    }
}

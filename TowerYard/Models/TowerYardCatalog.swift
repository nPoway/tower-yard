import SwiftUI

enum BlockSkinID: String, CaseIterable, Identifiable, Codable {
    case brick
    case concrete
    case glass
    case wood
    case neon
    case gold

    var id: String { rawValue }
}

enum BlockSkinPattern {
    case brick
    case aggregate
    case glass
    case grain
    case neon
    case metallic
}

struct BlockSkin: Identifiable {
    let id: BlockSkinID
    let name: String
    let description: String
    let price: Int
    let style: BlockSkinVisualStyle
}

struct BlockSkinVisualStyle {
    let baseColor: Color
    let highlightColor: Color
    let shadowColor: Color
    let strokeColor: Color
    let glowColor: Color
    let glowRadius: CGFloat
    let pattern: BlockSkinPattern
}

enum GameToolID: String, CaseIterable, Identifiable, Codable {
    case levelingHammer
    case safetyNet
    case foundationBooster
    case craneSlowdown

    var id: String { rawValue }
}

struct GameToolDefinition: Identifiable {
    let id: GameToolID
    let name: String
    let shortName: String
    let description: String
    let application: String
    let price: Int
    let systemImage: String
}

struct GameToolState: Identifiable {
    let definition: GameToolDefinition
    let count: Int

    var id: GameToolID { definition.id }
}

enum SkinOwnershipState: Equatable {
    case locked
    case owned
    case equipped
}

enum TowerYardCatalog {
    static let skins: [BlockSkin] = [
        BlockSkin(
            id: .brick,
            name: "Brick",
            description: "Classic red masonry with clean mortar lines.",
            price: 0,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.70, green: 0.20, blue: 0.14),
                highlightColor: Color(red: 0.92, green: 0.38, blue: 0.22),
                shadowColor: Color(red: 0.38, green: 0.08, blue: 0.06),
                strokeColor: Color(red: 0.98, green: 0.76, blue: 0.62),
                glowColor: .clear,
                glowRadius: 0,
                pattern: .brick
            )
        ),
        BlockSkin(
            id: .concrete,
            name: "Concrete",
            description: "Heavy gray blocks with a rough aggregate finish.",
            price: 150,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.48, green: 0.50, blue: 0.49),
                highlightColor: Color(red: 0.78, green: 0.79, blue: 0.76),
                shadowColor: Color(red: 0.26, green: 0.27, blue: 0.27),
                strokeColor: Color(red: 0.88, green: 0.87, blue: 0.82),
                glowColor: .clear,
                glowRadius: 0,
                pattern: .aggregate
            )
        ),
        BlockSkin(
            id: .glass,
            name: "Glass",
            description: "Clear blue panels with bright reflective edges.",
            price: 280,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.20, green: 0.68, blue: 0.88).opacity(0.72),
                highlightColor: Color(red: 0.78, green: 0.96, blue: 1.00).opacity(0.90),
                shadowColor: Color(red: 0.05, green: 0.34, blue: 0.55).opacity(0.78),
                strokeColor: Color(red: 0.88, green: 0.98, blue: 1.00),
                glowColor: Color(red: 0.42, green: 0.86, blue: 1.00).opacity(0.28),
                glowRadius: 8,
                pattern: .glass
            )
        ),
        BlockSkin(
            id: .wood,
            name: "Wood",
            description: "Warm timber beams with visible grain.",
            price: 240,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.58, green: 0.34, blue: 0.16),
                highlightColor: Color(red: 0.92, green: 0.63, blue: 0.30),
                shadowColor: Color(red: 0.28, green: 0.15, blue: 0.07),
                strokeColor: Color(red: 0.98, green: 0.78, blue: 0.48),
                glowColor: .clear,
                glowRadius: 0,
                pattern: .grain
            )
        ),
        BlockSkin(
            id: .neon,
            name: "Neon",
            description: "Dark tech blocks with cyan and magenta light strips.",
            price: 460,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.05, green: 0.06, blue: 0.08),
                highlightColor: Color(red: 0.00, green: 0.95, blue: 0.92),
                shadowColor: Color(red: 0.50, green: 0.05, blue: 0.82),
                strokeColor: Color(red: 0.58, green: 1.00, blue: 0.94),
                glowColor: Color(red: 0.00, green: 0.94, blue: 0.90).opacity(0.55),
                glowRadius: 12,
                pattern: .neon
            )
        ),
        BlockSkin(
            id: .gold,
            name: "Gold",
            description: "Polished premium blocks with metallic highlights.",
            price: 760,
            style: BlockSkinVisualStyle(
                baseColor: Color(red: 0.95, green: 0.63, blue: 0.12),
                highlightColor: Color(red: 1.00, green: 0.91, blue: 0.40),
                shadowColor: Color(red: 0.58, green: 0.32, blue: 0.03),
                strokeColor: Color(red: 1.00, green: 0.96, blue: 0.62),
                glowColor: Color(red: 1.00, green: 0.76, blue: 0.22).opacity(0.30),
                glowRadius: 9,
                pattern: .metallic
            )
        )
    ]

    static let tools: [GameToolDefinition] = [
        GameToolDefinition(
            id: .levelingHammer,
            name: "Leveling Hammer",
            shortName: "Hammer",
            description: "Slightly straightens the last placed block.",
            application: "Applies once to the current tower and moves the last block closer to the block below.",
            price: 90,
            systemImage: "hammer.fill"
        ),
        GameToolDefinition(
            id: .safetyNet,
            name: "Safety Net",
            shortName: "Net",
            description: "Saves one failed drop during the current run.",
            application: "Arms one save. The next missed block is caught and placed safely.",
            price: 120,
            systemImage: "shield.lefthalf.filled"
        ),
        GameToolDefinition(
            id: .foundationBooster,
            name: "Foundation Booster",
            shortName: "Booster",
            description: "Reduces early tower wobble for the next few drops.",
            application: "Adds extra tolerance to the first foundation drops of the current run.",
            price: 140,
            systemImage: "building.columns.fill"
        ),
        GameToolDefinition(
            id: .craneSlowdown,
            name: "Crane Slowdown",
            shortName: "Slowdown",
            description: "Slows crane movement for a short stretch.",
            application: "Reduces crane speed for the next five block drops.",
            price: 110,
            systemImage: "tortoise.fill"
        )
    ]

    static var shopSkins: [BlockSkin] {
        BlockSkinID.allCases.compactMap { id in
            skins.first { $0.id == id }
        }
    }

    static var shopTools: [GameToolDefinition] {
        GameToolID.allCases.compactMap { id in
            tools.first { $0.id == id }
        }
    }

    static func skin(for id: BlockSkinID) -> BlockSkin {
        skins.first { $0.id == id } ?? skins[0]
    }

    static func tool(for id: GameToolID) -> GameToolDefinition {
        tools.first { $0.id == id } ?? tools[0]
    }
}

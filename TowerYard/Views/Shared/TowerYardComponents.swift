import SwiftUI

enum TYTheme {
    static let background = TowerYardTheme.deepSteel
    static let panel = TowerYardTheme.panel
    static let panelElevated = TowerYardTheme.steel.opacity(0.92)
    static let border = TowerYardTheme.panelStroke
    static let textPrimary = TowerYardTheme.textPrimary
    static let textSecondary = TowerYardTheme.textSecondary
    static let accent = TowerYardTheme.constructionYellow
    static let teal = Color(red: 0.18, green: 0.72, blue: 0.66)
    static let danger = Color(red: 0.95, green: 0.30, blue: 0.22)
}

struct TYCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(TYTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(TYTheme.border, lineWidth: 1)
            )
    }
}

struct CoinPill: View {
    let coins: Int

    var body: some View {
        Label("\(coins)", systemImage: "bitcoinsign.circle.fill")
            .font(.system(.callout, design: .rounded, weight: .bold))
            .foregroundStyle(TYTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TYTheme.panelElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(TYTheme.accent.opacity(0.45), lineWidth: 1)
            )
    }
}

struct PricePill: View {
    let price: Int

    var body: some View {
        Label(price == 0 ? "Free" : "\(price)", systemImage: "bitcoinsign.circle.fill")
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(price == 0 ? TYTheme.teal : TYTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.20))
            .clipShape(Capsule())
    }
}

struct StoreButtonStyle: ButtonStyle {
    var isProminent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .rounded, weight: .bold))
            .foregroundStyle(isProminent ? Color.black : TYTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isProminent ? TYTheme.accent : TYTheme.panelElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isProminent ? Color.clear : TYTheme.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct SkinBlockView: View {
    let skin: BlockSkin

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        skin.style.highlightColor,
                        skin.style.baseColor,
                        skin.style.shadowColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                SkinPatternOverlay(pattern: skin.style.pattern)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(skin.style.strokeColor.opacity(0.70), lineWidth: 1.2)
            )
            .shadow(color: skin.style.glowColor, radius: skin.style.glowRadius, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 3)
    }

    private var cornerRadius: CGFloat {
        switch skin.style.pattern {
        case .brick, .grain:
            4
        case .glass, .neon, .metallic:
            7
        case .aggregate:
            5
        }
    }
}

struct SkinStackPreview: View {
    let skin: BlockSkin

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(TowerYardTheme.deepSteel.opacity(0.82))
                .overlay(
                    BlueprintGridShape(spacing: 14)
                        .stroke(TowerYardTheme.beamBlue.opacity(0.24), lineWidth: 0.5)
                )

            VStack(spacing: -2) {
                SkinBlockView(skin: skin)
                    .frame(width: 54, height: 24)
                    .offset(x: 8)
                SkinBlockView(skin: skin)
                    .frame(width: 72, height: 24)
                    .offset(x: -6)
                SkinBlockView(skin: skin)
                    .frame(width: 88, height: 24)
            }
            .padding(.bottom, 9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(skin.style.strokeColor.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: skin.style.glowColor, radius: skin.style.glowRadius, x: 0, y: 0)
    }
}

private struct SkinPatternOverlay: View {
    let pattern: BlockSkinPattern

    var body: some View {
        GeometryReader { geometry in
            switch pattern {
            case .brick:
                brickPattern(size: geometry.size)
            case .aggregate:
                aggregatePattern(size: geometry.size)
            case .glass:
                glassPattern(size: geometry.size)
            case .grain:
                woodPattern(size: geometry.size)
            case .neon:
                neonPattern(size: geometry.size)
            case .metallic:
                metalPattern(size: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func brickPattern(size: CGSize) -> some View {
        ZStack {
            ForEach(1..<3, id: \.self) { row in
                Rectangle()
                    .fill(Color.white.opacity(0.24))
                    .frame(height: 1)
                    .position(x: size.width / 2, y: size.height * CGFloat(row) / 3)
            }
            ForEach(0..<3, id: \.self) { column in
                Rectangle()
                    .fill(Color.black.opacity(0.14))
                    .frame(width: 1, height: size.height / 3)
                    .position(
                        x: size.width * (CGFloat(column) + 0.5) / 3,
                        y: column.isMultiple(of: 2) ? size.height * 0.17 : size.height * 0.83
                    )
            }
        }
    }

    private func aggregatePattern(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.16) : Color.black.opacity(0.12))
                    .frame(width: 3 + CGFloat(index % 3), height: 3 + CGFloat(index % 3))
                    .position(
                        x: size.width * CGFloat((index * 23) % 100) / 100,
                        y: size.height * CGFloat((index * 37) % 100) / 100
                    )
            }
        }
    }

    private func glassPattern(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.white.opacity(0.26))
                .frame(width: size.width * 0.18)
                .rotationEffect(.degrees(22))
                .offset(x: size.width * 0.18, y: -size.height * 0.45)
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: size.width * 0.10)
                .rotationEffect(.degrees(22))
                .offset(x: size.width * 0.64, y: -size.height * 0.28)
        }
    }

    private func woodPattern(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: size.width * (0.32 + CGFloat(index) * 0.08), height: 2)
                    .position(
                        x: size.width * (0.22 + CGFloat(index) * 0.18),
                        y: size.height * (0.24 + CGFloat(index % 2) * 0.34)
                    )
            }
        }
    }

    private func neonPattern(size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.cyan.opacity(0.74))
                .frame(height: 2)
                .position(x: size.width / 2, y: size.height * 0.26)
            Rectangle()
                .fill(Color.pink.opacity(0.70))
                .frame(height: 2)
                .position(x: size.width / 2, y: size.height * 0.74)
        }
    }

    private func metalPattern(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.white.opacity(0.24))
                .frame(width: size.width * 0.32)
                .rotationEffect(.degrees(18))
                .offset(x: size.width * 0.52, y: -size.height * 0.32)
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
                .position(x: size.width / 2, y: size.height * 0.68)
        }
    }
}

import SwiftUI

enum TowerYardTheme {
    static let blueprint = Color(red: 0.04, green: 0.12, blue: 0.18)
    static let steel = Color(red: 0.10, green: 0.14, blue: 0.16)
    static let deepSteel = Color(red: 0.05, green: 0.07, blue: 0.08)
    static let constructionYellow = Color(red: 0.97, green: 0.73, blue: 0.16)
    static let warningStripe = Color(red: 0.08, green: 0.08, blue: 0.07)
    static let brick = Color(red: 0.69, green: 0.23, blue: 0.16)
    static let beamBlue = Color(red: 0.22, green: 0.48, blue: 0.66)
    static let concrete = Color(red: 0.74, green: 0.77, blue: 0.75)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.77, green: 0.82, blue: 0.82)
    static let panel = Color(red: 0.09, green: 0.12, blue: 0.13).opacity(0.92)
    static let panelStroke = Color.white.opacity(0.12)

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [
                blueprint,
                steel,
                deepSteel,
                brick.opacity(0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AppShellMetrics {
    static let tabBarHorizontalPadding: CGFloat = 6
    static let tabBarTopPadding: CGFloat = 8
    static let tabBarBottomPadding: CGFloat = 6
    static let tabBarButtonHeight: CGFloat = 54
    static let tabBarHeight: CGFloat = tabBarButtonHeight + tabBarTopPadding + tabBarBottomPadding
    static let contentBottomClearance: CGFloat = 24
    static let scrollContentBottomClearance: CGFloat = tabBarHeight + contentBottomClearance
}

struct YardScreen<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            BlueprintGridBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .appShellScrollContentBottomClearance()
        }
        .scrollContentBackground(.hidden)
        .background(TowerYardTheme.deepSteel)
    }
}

struct BlueprintGridBackground: View {
    var body: some View {
        ZStack {
            TowerYardTheme.screenGradient

            BlueprintGridShape(spacing: 28)
                .stroke(TowerYardTheme.beamBlue.opacity(0.24), lineWidth: 0.6)

            BlueprintGridShape(spacing: 112)
                .stroke(TowerYardTheme.constructionYellow.opacity(0.18), lineWidth: 1)
        }
        .ignoresSafeArea()
    }
}

struct BlueprintGridShape: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }

        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }

        return path
    }
}

struct YardPanelModifier: ViewModifier {
    var stroke: Color = TowerYardTheme.panelStroke

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TowerYardTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 12, x: 0, y: 8)
    }
}

extension View {
    func yardPanel(stroke: Color = TowerYardTheme.panelStroke) -> some View {
        modifier(YardPanelModifier(stroke: stroke))
    }

    func appShellScrollContentBottomClearance(_ clearance: CGFloat = AppShellMetrics.scrollContentBottomClearance) -> some View {
        contentMargins(.bottom, clearance, for: .scrollContent)
    }
}

struct YardSectionHeader: View {
    var title: String
    var subtitle: String?
    var systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(TowerYardTheme.constructionYellow)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(TowerYardTheme.warningStripe)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                    .lineLimit(2)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(TowerYardTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct FeatureStatusBanner: View {
    var status: TowerFeatureStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.isConnected ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(status.isConnected ? .green : TowerYardTheme.constructionYellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.title)
                    .font(.headline)
                    .foregroundStyle(TowerYardTheme.textPrimary)

                Text(status.message)
                    .font(.subheadline)
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .yardPanel(stroke: status.isConnected ? .green.opacity(0.45) : TowerYardTheme.constructionYellow.opacity(0.45))
    }
}

struct StatPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(TowerYardTheme.warningStripe)
                .frame(width: 24, height: 24)
                .background(Circle().fill(TowerYardTheme.constructionYellow))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(TowerYardTheme.deepSteel.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
        )
    }
}

struct YardMetricCard: View {
    var title: String
    var value: String
    var footnote: String?
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.constructionYellow)
                Spacer()
            }

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(TowerYardTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TowerYardTheme.textSecondary)
                .lineLimit(2)

            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(TowerYardTheme.concrete)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .yardPanel(stroke: TowerYardTheme.beamBlue.opacity(0.35))
    }
}

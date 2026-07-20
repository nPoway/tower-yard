import SwiftUI

struct NoInternetView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let message: String
    let retryAction: () -> Void

    var body: some View {
        ZStack {
            BlueprintGridBackground()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    Group {
                        if verticalSizeClass == .compact {
                            compactLayout
                        } else {
                            regularLayout
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .padding(.horizontal, 24)
                    .padding(.vertical, verticalSizeClass == .compact ? 12 : 24)
                }
            }
        }
        .background(TowerYardTheme.deepSteel)
    }

    private var regularLayout: some View {
        VStack(spacing: 18) {
            statusIcon(size: 82, symbolSize: 42)
            messageBlock
            retryButton
                .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: 420)
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.5))
    }

    private var compactLayout: some View {
        HStack(spacing: 22) {
            statusIcon(size: 70, symbolSize: 34)

            VStack(spacing: 14) {
                messageBlock
                retryButton
            }
            .frame(maxWidth: 420)
        }
        .padding(18)
        .frame(maxWidth: 620)
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.5))
    }

    private func statusIcon(size: CGFloat, symbolSize: CGFloat) -> some View {
        Image(systemName: "wifi.slash")
            .font(.system(size: symbolSize, weight: .bold))
            .foregroundStyle(TowerYardTheme.constructionYellow)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TowerYardTheme.warningStripe)
            )
            .accessibilityHidden(true)
    }

    private var messageBlock: some View {
        VStack(spacing: 8) {
            Text("No internet connection")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(TowerYardTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(verticalSizeClass == .compact ? .subheadline : .body)
                .foregroundStyle(TowerYardTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var retryButton: some View {
        Button(action: retryAction) {
            Label("Try Again", systemImage: "arrow.clockwise")
        }
        .buttonStyle(NoInternetButtonStyle())
    }
}

private struct NoInternetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(TowerYardTheme.warningStripe)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(TowerYardTheme.constructionYellow)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

#Preview {
    NoInternetView(message: "Connect to the internet and try again.", retryAction: {})
}

import SwiftUI

struct NotificationOptInView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let allowAction: () -> Void
    let skipAction: () -> Void

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
                    .padding(.horizontal, verticalSizeClass == .compact ? 20 : 24)
                    .padding(.vertical, verticalSizeClass == .compact ? 14 : 24)
                }
            }
        }
        .background(TowerYardTheme.deepSteel)
    }

    private var regularLayout: some View {
        VStack(spacing: 18) {
            logo(width: 180)
            message(compact: false)
            actions
                .padding(.top, 8)
        }
        .frame(maxWidth: 560)
    }

    private var compactLayout: some View {
        HStack(spacing: 24) {
            logo(width: 132)

            VStack(spacing: 14) {
                message(compact: true)
                actions
            }
            .frame(maxWidth: 440)
        }
        .frame(maxWidth: 720)
    }

    private func logo(width: CGFloat) -> some View {
        Image("towerLogo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: TowerYardTheme.constructionYellow.opacity(0.35), radius: 20)
            .accessibilityHidden(true)
    }

    private func message(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 10) {
            Text("Get build alerts")
                .font(.system(compact ? .title2 : .largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(TowerYardTheme.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)

            Text("Enable notifications to receive bonus drops, build updates, and quick access back to your tower.")
                .font(compact ? .subheadline : .body)
                .foregroundStyle(TowerYardTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, compact ? 0 : 12)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: allowAction) {
                Label("Yes, I Want Bonuses!", systemImage: "bell.badge.fill")
            }
            .buttonStyle(NotificationPrimaryButtonStyle())

            Button(action: skipAction) {
                Text("Skip")
            }
            .buttonStyle(NotificationSecondaryButtonStyle())
        }
    }
}

private struct NotificationPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(TowerYardTheme.warningStripe)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(TowerYardTheme.constructionYellow)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

private struct NotificationSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(TowerYardTheme.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(TowerYardTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

#Preview {
    NotificationOptInView(allowAction: {}, skipAction: {})
}

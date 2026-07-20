import SwiftUI

struct LaunchSplashView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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
                    .padding(.horizontal, 28)
                    .padding(.vertical, verticalSizeClass == .compact ? 12 : 24)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tower Yard is loading")
    }

    private var regularLayout: some View {
        VStack(spacing: 20) {
            logo(size: 164)
            titleBlock
            loadingIndicator
                .padding(.top, 6)
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 28) {
            logo(size: 124)

            VStack(spacing: 14) {
                titleBlock
                loadingIndicator
            }
        }
        .frame(maxWidth: 620)
    }

    private func logo(size: CGFloat) -> some View {
        Image("towerLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.17, style: .continuous))
            .shadow(color: TowerYardTheme.constructionYellow.opacity(0.22), radius: 26, x: 0, y: 12)
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text("Tower Yard")
                .font(.system(size: verticalSizeClass == .compact ? 30 : 34, weight: .black, design: .rounded))
                .foregroundStyle(TowerYardTheme.textPrimary)
                .minimumScaleFactor(0.8)

            Text("Build higher. Keep it steady.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TowerYardTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loadingIndicator: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(TowerYardTheme.constructionYellow)
            .controlSize(.large)
    }
}

#Preview {
    LaunchSplashView()
}

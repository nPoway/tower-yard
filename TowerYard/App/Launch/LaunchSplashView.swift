import SwiftUI

struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            BlueprintGridBackground()

            VStack(spacing: 20) {
                Image("towerLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 164, height: 164)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: TowerYardTheme.constructionYellow.opacity(0.22), radius: 26, x: 0, y: 12)

                VStack(spacing: 6) {
                    Text("Tower Yard")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(TowerYardTheme.textPrimary)

                    Text("Build higher. Keep it steady.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TowerYardTheme.textSecondary)
                }
            }
            .padding(.horizontal, 28)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tower Yard is loading")
    }
}

#Preview {
    LaunchSplashView()
}

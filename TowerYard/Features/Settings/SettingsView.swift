import SwiftUI

struct SettingsView: View {
    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "Settings",
                subtitle: "Reference links for Tower Yard: Skyline Builder.",
                systemImage: "gearshape.fill"
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Legal")
                    .font(.headline)
                    .foregroundStyle(TowerYardTheme.textPrimary)

                VStack(spacing: 0) {
                    SettingsLegalLinkRow(
                        title: "Privacy Policy",
                        subtitle: "How TowerYard handles privacy information.",
                        systemImage: "hand.raised.fill",
                        destination: TowerYardLegalLinks.privacyPolicy
                    )

                    SettingsDivider()

                    SettingsLegalLinkRow(
                        title: "Support",
                        subtitle: "Contact and support information.",
                        systemImage: "questionmark.circle.fill",
                        destination: TowerYardLegalLinks.support
                    )
                }
                .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.42))
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum TowerYardLegalLinks {
    static let privacyPolicy = URL(string: "https://toweryardskylinebuilder.com/privacy-policy.html")!
    static let support = URL(string: "https://toweryardskylinebuilder.com/support.html")!
}

private struct SettingsLegalLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.warningStripe)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TowerYardTheme.constructionYellow)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(TowerYardTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(TowerYardTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.constructionYellow)
                    .frame(width: 28, height: 28)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(TowerYardTheme.panelStroke)
            .frame(height: 1)
            .padding(.leading, 50)
            .padding(.vertical, 10)
    }
}

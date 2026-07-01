import SwiftUI

struct PlayHubView: View {
    @EnvironmentObject private var yardStore: TowerYardStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "Tower Yard",
                subtitle: "Choose a build route, track yard progress, and keep every saved tower result in one place.",
                systemImage: "building.2.crop.circle"
            )

            PlayHudView()

            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Launch")
                    .font(.headline)
                    .foregroundStyle(TowerYardTheme.textPrimary)

                LazyVGrid(columns: columns, spacing: 12) {
                    QuickLaunchCard(
                        mode: .contracts,
                        systemImage: "doc.text.fill",
                        borderColor: TowerYardTheme.constructionYellow.opacity(0.45)
                    ) {
                        ContractsHubView()
                            .navigationTitle(YardPlayMode.contracts.title)
                    }

                    QuickLaunchCard(
                        mode: .endlessTower,
                        systemImage: "arrow.up.to.line.compact",
                        borderColor: TowerYardTheme.beamBlue.opacity(0.50)
                    ) {
                        GameView(store: yardStore)
                            .navigationTitle(YardPlayMode.endlessTower.title)
                    }
                }
            }

            LatestResultPanel()
        }
    }
}

private struct PlayHudView: View {
    @EnvironmentObject private var yardStore: TowerYardStore
    @EnvironmentObject private var profileStore: TowerYardProfileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatPill(title: "Coins", value: "\(yardStore.coins)", systemImage: "bitcoinsign.circle.fill")
                StatPill(title: "Level", value: "\(profileStore.profile.builderLevel)", systemImage: "hammer.fill")
            }

            HStack(spacing: 10) {
                StatPill(title: "Rank", value: profileStore.profile.rankTitle, systemImage: "person.crop.square.fill")
                StatPill(title: "Best", value: "\(max(yardStore.bestHeight, profileStore.bestRecord)) m", systemImage: "arrow.up.right")
            }
        }
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.5))
    }
}

private struct QuickLaunchCard<Destination: View>: View {
    private let mode: YardPlayMode
    private let systemImage: String
    private let borderColor: Color
    private let destination: () -> Destination

    init(
        mode: YardPlayMode,
        systemImage: String,
        borderColor: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.mode = mode
        self.systemImage = systemImage
        self.borderColor = borderColor
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TowerYardTheme.warningStripe)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TowerYardTheme.constructionYellow)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(TowerYardTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(TowerYardTheme.textSecondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)

                HStack {
                    Text("Open")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TowerYardTheme.constructionYellow)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TowerYardTheme.constructionYellow)
                }
            }
            .frame(minHeight: 168, alignment: .topLeading)
            .yardPanel(stroke: borderColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(mode.title)")
    }
}

private struct LatestResultPanel: View {
    @EnvironmentObject private var profileStore: TowerYardProfileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Tower")
                    .font(.headline)
                    .foregroundStyle(TowerYardTheme.textPrimary)

                Spacer()

                NavigationLink("Gallery") {
                    GalleryView()
                        .navigationTitle("Gallery")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TowerYardTheme.constructionYellow)
            }

            if let latest = profileStore.latestTowerResult {
                TowerResultCompactCard(result: latest)
            } else {
                EmptyGalleryState()
            }
        }
    }
}

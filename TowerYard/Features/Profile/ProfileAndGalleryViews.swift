import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileStore: TowerYardProfileStore
    @EnvironmentObject private var progressStore: TowerProgressStore
    @EnvironmentObject private var yardStore: TowerYardStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        YardScreen {
            ProfileHeaderView()

            LazyVGrid(columns: columns, spacing: 12) {
                YardMetricCard(
                    title: "Total Towers Built",
                    value: "\(totalTowersBuilt)",
                    footnote: nil,
                    systemImage: "building.2.fill"
                )

                YardMetricCard(
                    title: "Highest Tower",
                    value: "\(highestTower) m",
                    footnote: "Best record: \(highestTower) m",
                    systemImage: "arrow.up.to.line"
                )

                YardMetricCard(
                    title: "Contracts Completed",
                    value: "\(progressStore.profileStats.contractsCompleted)",
                    footnote: nil,
                    systemImage: "checklist.checked"
                )

                YardMetricCard(
                    title: "Perfect Blocks",
                    value: "\(profileStore.profile.perfectBlocks)",
                    footnote: nil,
                    systemImage: "square.stack.3d.up.fill"
                )

                YardMetricCard(
                    title: "Tools Used",
                    value: "\(profileStore.profile.toolsUsed)",
                    footnote: nil,
                    systemImage: "wrench.and.screwdriver.fill"
                )

                YardMetricCard(
                    title: "Favorite Material",
                    value: profileStore.favoriteMaterial ?? "Not set",
                    footnote: favoriteSkin.map { "Skin: \($0)" },
                    systemImage: "shippingbox.fill"
                )
            }

            ProfileGalleryPreview()
        }
    }

    private var totalTowersBuilt: Int {
        max(yardStore.completedRuns, profileStore.profile.totalTowersBuilt, progressStore.profileStats.contractsPlayed)
    }

    private var highestTower: Int {
        max(yardStore.bestHeight, profileStore.profile.highestTower, progressStore.profileStats.maximumHeight)
    }

    private var favoriteSkin: String? {
        yardStore.favoriteSkin ?? profileStore.favoriteSkin
    }
}

private struct ProfileHeaderView: View {
    @EnvironmentObject private var yardStore: TowerYardStore

    var body: some View {
        let profile = yardStore.profile

        VStack(alignment: .leading, spacing: 14) {
            YardSectionHeader(
                title: "Builder Profile",
                subtitle: "\(profile.rankTitle) with \(yardStore.coins) coins in the yard bank.",
                systemImage: "person.crop.square.fill"
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Builder Level")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TowerYardTheme.textSecondary)
                            .textCase(.uppercase)

                        Text("\(profile.builderLevel)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(TowerYardTheme.constructionYellow)
                    }

                    Spacer()

                    Text(profile.rankTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TowerYardTheme.textPrimary)
                        .multilineTextAlignment(.trailing)
                }

                ProgressView(value: profile.progressToNextLevel)
                    .tint(TowerYardTheme.constructionYellow)
                    .background(TowerYardTheme.deepSteel.opacity(0.75))

                Text("\(profile.experienceIntoLevel) / \(profile.experienceNeededForNextLevel) XP to next level")
                    .font(.caption)
                    .foregroundStyle(TowerYardTheme.textSecondary)
            }
            .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.5))
        }
    }
}

private struct ProfileGalleryPreview: View {
    @EnvironmentObject private var store: TowerYardProfileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tower Gallery")
                    .font(.headline)
                    .foregroundStyle(TowerYardTheme.textPrimary)

                Spacer()

                NavigationLink("View All") {
                    GalleryView()
                        .navigationTitle("Gallery")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TowerYardTheme.constructionYellow)
            }

            if let latest = store.latestTowerResult {
                TowerResultCompactCard(result: latest)
            } else {
                EmptyGalleryState()
            }
        }
    }
}

struct GalleryView: View {
    @EnvironmentObject private var store: TowerYardProfileStore

    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "Tower Gallery",
                subtitle: "Recent saved tower results from connected play flows.",
                systemImage: "photo.on.rectangle.angled"
            )

            if store.towerResults.isEmpty {
                EmptyGalleryState()
            } else {
                VStack(spacing: 12) {
                    ForEach(store.towerResults) { result in
                        NavigationLink {
                            TowerResultDetailView(result: result)
                                .navigationTitle("Tower Result")
                        } label: {
                            TowerResultCompactCard(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct TowerResultDetailView: View {
    var result: TowerResultCard

    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "\(result.mode.title) Result",
                subtitle: result.date.formatted(date: .abbreviated, time: .shortened),
                systemImage: "building.columns.fill"
            )

            VStack(alignment: .leading, spacing: 16) {
                ResultBlueprintCard(result: result)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    YardMetricCard(title: "Mode", value: result.mode.title, footnote: nil, systemImage: "play.rectangle.fill")
                    YardMetricCard(title: "Height", value: "\(result.height) m", footnote: nil, systemImage: "arrow.up")
                    YardMetricCard(title: "Weather", value: result.weather.title, footnote: nil, systemImage: "cloud.sun.fill")
                    YardMetricCard(title: "Material", value: result.material, footnote: result.skin.map { "Skin: \($0)" }, systemImage: "shippingbox.fill")
                    YardMetricCard(title: "Result", value: result.outcome.title, footnote: "Score: \(result.score)", systemImage: "flag.checkered")
                    YardMetricCard(title: "Perfect Blocks", value: "\(result.perfectBlocks)", footnote: "Tools used: \(result.toolsUsed)", systemImage: "square.stack.3d.up.fill")
                }
            }
        }
    }
}

struct TowerResultCompactCard: View {
    var result: TowerResultCard

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ResultBlueprintThumbnail(result: result)
                .frame(width: 76, height: 94)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.mode.title)
                        .font(.headline)
                        .foregroundStyle(TowerYardTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer()

                    Text("\(result.height) m")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TowerYardTheme.constructionYellow)
                }

                Text("\(result.weather.title) | \(result.material)")
                    .font(.subheadline)
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .lineLimit(1)

                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(TowerYardTheme.concrete)

                HStack(spacing: 8) {
                    Label(result.outcome.title, systemImage: "flag.fill")
                    Label("\(result.perfectBlocks) perfect", systemImage: "square.stack.3d.up.fill")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(TowerYardTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .yardPanel(stroke: TowerYardTheme.beamBlue.opacity(0.40))
    }
}

struct EmptyGalleryState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title2.weight(.bold))
                .foregroundStyle(TowerYardTheme.constructionYellow)

            Text("No saved tower results yet")
                .font(.headline)
                .foregroundStyle(TowerYardTheme.textPrimary)

            Text("When a real build flow records a tower result, this gallery will show the mode, height, weather, date, material, skin, and outcome.")
                .font(.subheadline)
                .foregroundStyle(TowerYardTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .yardPanel()
    }
}

private struct ResultBlueprintCard: View {
    var result: TowerResultCard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ResultBlueprintThumbnail(result: result)
                .frame(height: 220)

            HStack {
                Text(result.outcome.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.constructionYellow)

                Spacer()

                Text("Score \(result.score)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TowerYardTheme.textPrimary)
            }
        }
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.45))
    }
}

private struct ResultBlueprintThumbnail: View {
    var result: TowerResultCard

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TowerYardTheme.blueprint.opacity(0.88))
                    .overlay(
                        BlueprintGridShape(spacing: 14)
                            .stroke(TowerYardTheme.beamBlue.opacity(0.28), lineWidth: 0.6)
                    )

                VStack(spacing: 2) {
                    ForEach(0..<blockCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(blockColor(for: index))
                            .frame(
                                width: max(20, size.width * widthRatio(for: index)),
                                height: max(6, min(16, size.height / CGFloat(blockCount + 4)))
                            )
                    }
                }
                .padding(.bottom, 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
            )
        }
    }

    private var blockCount: Int {
        max(4, min(16, result.height / 8 + 4))
    }

    private func widthRatio(for index: Int) -> CGFloat {
        let drift = CGFloat((index % 4) - 1) * 0.025
        return max(0.46, min(0.88, 0.74 - CGFloat(index) * 0.012 + drift))
    }

    private func blockColor(for index: Int) -> Color {
        if index.isMultiple(of: 3) {
            return TowerYardTheme.constructionYellow
        }

        if index.isMultiple(of: 2) {
            return TowerYardTheme.brick
        }

        return TowerYardTheme.concrete
    }
}

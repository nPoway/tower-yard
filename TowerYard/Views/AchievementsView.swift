import SwiftUI

struct AchievementsView: View {
    @ObservedObject var store: TowerProgressStore
    @EnvironmentObject private var yardStore: TowerYardStore

    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "Achievements",
                subtitle: "Milestones unlock from saved construction results and pay their coin reward once.",
                systemImage: "trophy.fill"
            )

            AchievementSummaryPanel(store: store, yardCoins: yardStore.coins)

            Text("Milestone Ledger")
                .font(.headline)
                .foregroundStyle(TowerYardTheme.textPrimary)

            LazyVStack(spacing: 12) {
                ForEach(AchievementCatalog.all) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        state: store.achievementState(for: achievement),
                        progress: store.achievementProgress(for: achievement)
                    )
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AchievementSummaryPanel: View {
    @ObservedObject var store: TowerProgressStore
    let yardCoins: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                StatPill(title: "Coins", value: "\(yardCoins)", systemImage: "bitcoinsign.circle.fill")
                StatPill(title: "Unlocked", value: "\(store.unlockedAchievementCount)/\(AchievementCatalog.all.count)", systemImage: "medal.fill")
            }

            StatPill(title: "Buildings", value: "\(store.unlockedBuildingCount)/\(BuildingCollectionCatalog.all.count)", systemImage: "building.2.fill")
        }
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.45))
    }
}

private struct AchievementRow: View {
    let achievement: AchievementDefinition
    let state: AchievementState
    let progress: AchievementProgress

    private var isUnlocked: Bool {
        state.unlockedAt != nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(isUnlocked ? .green : TowerYardTheme.concrete.opacity(0.82))
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isUnlocked ? Color.green.opacity(0.18) : TowerYardTheme.deepSteel.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(cardStroke.opacity(isUnlocked ? 0.70 : 1), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? TowerYardTheme.textPrimary : TowerYardTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    RewardBadge(coins: achievement.rewardCoins)
                }

                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(achievement.condition.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TowerYardTheme.concrete)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text(isUnlocked ? "Complete" : progress.label)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(progressTint)
                    }

                    AchievementProgressBar(progress: progress.fraction, tint: progressTint)

                    if isUnlocked {
                        Label(unlockedLabel, systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TowerYardTheme.textSecondary)
                    }
                }
            }
        }
        .yardPanel(stroke: cardStroke)
    }

    private var unlockedLabel: String {
        guard let unlockedAt = state.unlockedAt else {
            return "Locked"
        }
        return "Unlocked \(unlockedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private var progressTint: Color {
        isUnlocked ? .green : TowerYardTheme.constructionYellow
    }

    private var cardStroke: Color {
        isUnlocked ? Color.green.opacity(0.45) : TowerYardTheme.panelStroke
    }
}

private struct RewardBadge: View {
    let coins: Int

    var body: some View {
        Label("\(coins)", systemImage: "bitcoinsign.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(TowerYardTheme.constructionYellow)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(TowerYardTheme.warningStripe.opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(TowerYardTheme.constructionYellow.opacity(0.42), lineWidth: 1)
            )
            .accessibilityLabel("\(coins) reward coins")
    }
}

private struct AchievementProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let clamped = max(0, min(1, progress))

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(TowerYardTheme.deepSteel.opacity(0.86))

                if clamped > 0 {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint, TowerYardTheme.constructionYellow.opacity(0.92)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * CGFloat(clamped))
                }

                BlueprintGridShape(spacing: 10)
                    .stroke(TowerYardTheme.beamBlue.opacity(0.18), lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
            )
        }
        .frame(height: 9)
    }
}

#Preview {
    NavigationStack {
        AchievementsView(store: .preview(sampleData: true))
            .environmentObject(TowerYardStore.preview)
    }
}

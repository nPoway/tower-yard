import SwiftUI

struct DailyContractView: View {
    @ObservedObject var progressStore: TowerProgressStore
    let onLaunch: (DailyContract) -> Void

    private var dailyContract: DailyContract {
        DailyContract.generate(for: Date())
    }

    var body: some View {
        let progress = progressStore.dailyProgress(for: dailyContract)
        let streak = progressStore.dailyStreakStatus(for: dailyContract)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Contract")
                                .font(.title2.weight(.bold))
                            Text(dailyContract.dateKey)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        DailyStatusBadge(completed: progress.completed)
                    }

                    Text(dailyContract.goal)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        DetailPill(title: "\(dailyContract.targetHeight) floors", systemImage: "arrow.up.to.line.compact", color: .blue)
                        DetailPill(title: dailyContract.weather.displayName, systemImage: dailyContract.weather.symbolName, color: .teal)
                    }

                    HStack(spacing: 8) {
                        DetailPill(title: dailyContract.material.displayName, systemImage: "square.stack.3d.up.fill", color: .purple)
                        RewardPill(reward: dailyContract.coinReward)
                        DetailPill(title: "Best \(progress.bestHeight)", systemImage: "chart.bar.fill", color: .green)
                    }

                    DailyModifierCard(modifier: dailyContract.modifier)

                    DailyStreakCard(streak: streak)

                    Button {
                        onLaunch(dailyContract)
                    } label: {
                        Label(progress.completed ? "Replay Daily" : "Start Daily", systemImage: progress.completed ? "arrow.clockwise" : "calendar.badge.clock")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(16)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.headline.weight(.bold))
                    Text(progress.completed ? "Completed for today. The next daily order appears on the next calendar date." : "Reward is available until the date changes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
        }
        .appShellScrollContentBottomClearance()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Daily")
    }
}

private struct DailyModifierCard: View {
    let modifier: DailyBuildModifier

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: modifier.systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(.orange)
                .frame(width: 34, height: 34)
                .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("Daily Condition: \(modifier.title)")
                    .font(.subheadline.weight(.bold))
                Text(modifier.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DailyStreakCard: View {
    let streak: DailyStreakStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)
                    .background(Color.red.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Site Streak")
                        .font(.subheadline.weight(.bold))
                    Text(streak.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                streakMetric(title: "Current", value: "\(streak.currentDays) days", color: .red)
                streakMetric(title: "Best", value: "\(streak.bestDays) days", color: .orange)
            }

            if let milestone = streak.nextMilestone,
               let days = streak.daysUntilNextMilestone {
                Label(
                    nextBonusLabel(for: milestone, days: days),
                    systemImage: "gift.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            } else {
                Label("Current streak has reached every milestone bonus.", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private func streakMetric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private func nextBonusLabel(for milestone: DailyStreakMilestone, days: Int) -> String {
        let dayUnit = days == 1 ? "day" : "days"
        return "Next bonus: \(milestone.title) · +\(milestone.rewardCoins) coins · \(days) \(dayUnit) away"
    }
}

private struct DailyStatusBadge: View {
    let completed: Bool

    var body: some View {
        Text(completed ? "Completed" : "Open")
            .font(.caption2.weight(.bold))
            .foregroundStyle(completed ? .green : .blue)
            .textCase(.uppercase)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background((completed ? Color.green : Color.blue).opacity(0.13), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        DailyContractView(progressStore: TowerProgressStore(progress: TowerProgress()), onLaunch: { _ in })
    }
}

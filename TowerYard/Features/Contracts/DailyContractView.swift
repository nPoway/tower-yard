import SwiftUI

struct DailyContractView: View {
    @ObservedObject var progressStore: TowerProgressStore
    let onLaunch: (DailyContract) -> Void

    private var dailyContract: DailyContract {
        DailyContract.generate(for: Date())
    }

    var body: some View {
        let progress = progressStore.dailyProgress(for: dailyContract)

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

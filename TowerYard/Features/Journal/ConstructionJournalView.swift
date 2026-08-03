import SwiftUI

struct ConstructionJournalView: View {
    @ObservedObject var store: TowerProgressStore
    @EnvironmentObject private var yardStore: TowerYardStore

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ProgressHeaderView(
                        title: "Construction Journal",
                        subtitle: "The journal keeps the latest 20 recorded construction results.",
                        store: store,
                        walletCoins: yardStore.coins
                    )

                    if store.journalEntries.isEmpty {
                        EmptyJournalView()
                    } else {
                        ForEach(store.journalEntries) { entry in
                            JournalEntryRow(entry: entry)
                        }
                    }
                }
                .padding(16)
            }
            .appShellScrollContentBottomClearance()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct EmptyJournalView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No Results Yet")
                .font(.headline)
            Text("Completed construction results will appear here after the game records them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.buildingName ?? entry.mode.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Label(entry.outcome.title, systemImage: outcomeIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(outcomeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(outcomeColor.opacity(0.13))
                    )
            }

            HStack(spacing: 8) {
                JournalMetric(icon: "square.stack.3d.up.fill", title: "Height", value: "\(entry.floors) fl / \(Int(entry.heightMeters.rounded()))m")
                JournalMetric(icon: "cloud.sun.fill", title: "Weather", value: entry.weather.title)
                JournalMetric(icon: "bitcoinsign.circle.fill", title: "Reward", value: "\(entry.rewardCoins)")
            }

            if let ratingStars = entry.ratingStars, ratingStars > 0 {
                JournalRatingRow(entry: entry, stars: ratingStars)
            }

            Text(entry.mode.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var outcomeIcon: String {
        switch entry.outcome {
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .abandoned:
            return "pause.circle.fill"
        }
    }

    private var outcomeColor: Color {
        switch entry.outcome {
        case .completed:
            return .teal
        case .failed:
            return .red
        case .abandoned:
            return .orange
        }
    }
}

private struct JournalRatingRow: View {
    let entry: JournalEntry
    let stars: Int

    var body: some View {
        HStack(spacing: 8) {
            Label(
                String(repeating: "★", count: stars),
                systemImage: "star.fill"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(.orange)

            if let precision = entry.precisionScore,
               let stability = entry.stabilityScore,
               let efficiency = entry.efficiencyScore {
                Text("P \(precision) · S \(stability) · E \(efficiency)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("Build rating")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct JournalMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

#Preview {
    ConstructionJournalView(store: .preview(sampleData: true))
        .environmentObject(TowerYardStore.preview)
}

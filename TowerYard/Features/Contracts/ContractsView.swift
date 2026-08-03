import SwiftUI

struct ContractsView: View {
    @EnvironmentObject private var yardStore: TowerYardStore
    @ObservedObject var progressStore: TowerProgressStore
    let onLaunch: (TowerContract) -> Void

    var body: some View {
        YardScreen {
            YardSectionHeader(
                title: "Contracts",
                subtitle: "Take paid build orders, work through harsher weather, and replay completed jobs for better results.",
                systemImage: "doc.text.fill"
            )

            ProgressSummaryView(progressStore: progressStore, yardCoins: yardStore.coins)

            Text("Contract Board")
                .font(.headline)
                .foregroundStyle(TowerYardTheme.textPrimary)

            LazyVStack(spacing: 12) {
                ForEach(ContractCatalog.all) { contract in
                    ContractRow(
                        contract: contract,
                        status: progressStore.status(for: contract),
                        bestHeight: progressStore.bestHeight(for: contract),
                        bestRating: progressStore.bestRating(for: contract),
                        onLaunch: { onLaunch(contract) }
                    )
                }
            }
        }
        .navigationTitle("Contracts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProgressSummaryView: View {
    @ObservedObject var progressStore: TowerProgressStore
    let yardCoins: Int

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let stats = progressStore.profileStats

        LazyVGrid(columns: columns, spacing: 12) {
            YardMetricCard(
                title: "Contracts Played",
                value: "\(stats.contractsPlayed)",
                footnote: "Saved locally",
                systemImage: "hammer.fill"
            )
            YardMetricCard(
                title: "Completed",
                value: "\(stats.contractsCompleted)",
                footnote: nil,
                systemImage: "checkmark.seal.fill"
            )
            YardMetricCard(
                title: "Max Floors",
                value: "\(stats.maximumHeight)",
                footnote: "Best build height",
                systemImage: "building.2.fill"
            )
            YardMetricCard(
                title: "Yard Coins",
                value: "\(yardCoins)",
                footnote: "Available wallet",
                systemImage: "bitcoinsign.circle.fill"
            )
        }
    }
}

private struct ContractRow: View {
    let contract: TowerContract
    let status: ContractStatus
    let bestHeight: Int
    let bestRating: Int
    let onLaunch: () -> Void

    private let detailColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: status.iconName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(status.iconForeground)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(status.iconBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(status.tint.opacity(0.35), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text("#\(contract.id) \(contract.title)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(status == .locked ? TowerYardTheme.textSecondary : TowerYardTheme.textPrimary)
                        .lineLimit(2)

                    Text(contract.goal)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(status == .locked ? TowerYardTheme.concrete : TowerYardTheme.constructionYellow)
                }

                Spacer(minLength: 8)

                ContractStatusBadge(status: status)
            }

            Text(contract.rule)
                .font(.subheadline)
                .foregroundStyle(TowerYardTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: detailColumns, spacing: 8) {
                ContractInfoTile(title: "Reward", value: "\(contract.coinReward)", systemImage: "bitcoinsign.circle.fill", tint: TowerYardTheme.constructionYellow)
                ContractInfoTile(title: "Weather", value: contract.weather.displayName, systemImage: contract.weather.symbolName, tint: TowerYardTheme.beamBlue)
                ContractInfoTile(title: "Target", value: "\(contract.targetHeight) floors", systemImage: "arrow.up.to.line.compact", tint: TowerYardTheme.concrete)
                ContractInfoTile(title: "Best Result", value: bestResultText, systemImage: "chart.bar.fill", tint: .green)
            }

            Button(action: onLaunch) {
                Label(buttonTitle, systemImage: buttonIcon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(status.buttonForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(status.buttonBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(status.buttonStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(status == .locked)
        }
        .yardPanel(stroke: status.cardStroke)
        .opacity(status == .locked ? 0.78 : 1)
    }

    private var bestResultText: String {
        guard bestHeight > 0 else { return "No run" }
        let stars = bestRating > 0 ? " · \(String(repeating: "★", count: bestRating))" : ""
        return "\(bestHeight) floors\(stars)"
    }

    private var buttonTitle: String {
        switch status {
        case .locked: "Locked"
        case .available: "Start Contract"
        case .completed: "Replay Contract"
        }
    }

    private var buttonIcon: String {
        switch status {
        case .locked: "lock.fill"
        case .available: "play.fill"
        case .completed: "arrow.clockwise"
        }
    }
}

private struct ContractStatusBadge: View {
    let status: ContractStatus

    var body: some View {
        Label(status.displayName, systemImage: status.badgeIconName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(status.tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TowerYardTheme.deepSteel.opacity(0.78), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(status.tint.opacity(0.38), lineWidth: 1)
            )
    }
}

private struct ContractInfoTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(TowerYardTheme.warningStripe.opacity(0.72))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(TowerYardTheme.deepSteel.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
        )
    }
}

private extension ContractStatus {
    var tint: Color {
        switch self {
        case .locked:
            return TowerYardTheme.concrete.opacity(0.82)
        case .available:
            return TowerYardTheme.constructionYellow
        case .completed:
            return .green
        }
    }

    var cardStroke: Color {
        switch self {
        case .locked:
            return TowerYardTheme.panelStroke
        case .available:
            return TowerYardTheme.constructionYellow.opacity(0.50)
        case .completed:
            return Color.green.opacity(0.45)
        }
    }

    var iconName: String {
        switch self {
        case .locked:
            return "lock.fill"
        case .available:
            return "building.2.fill"
        case .completed:
            return "checkmark.seal.fill"
        }
    }

    var badgeIconName: String {
        switch self {
        case .locked:
            return "lock.fill"
        case .available:
            return "flag.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    var iconForeground: Color {
        self == .available ? TowerYardTheme.warningStripe : tint
    }

    var iconBackground: Color {
        switch self {
        case .locked:
            return TowerYardTheme.deepSteel.opacity(0.82)
        case .available:
            return TowerYardTheme.constructionYellow
        case .completed:
            return Color.green.opacity(0.18)
        }
    }

    var buttonBackground: Color {
        switch self {
        case .locked:
            return TowerYardTheme.concrete.opacity(0.22)
        case .available:
            return TowerYardTheme.constructionYellow
        case .completed:
            return Color.green.opacity(0.86)
        }
    }

    var buttonForeground: Color {
        switch self {
        case .locked:
            return TowerYardTheme.textSecondary
        case .available:
            return TowerYardTheme.warningStripe
        case .completed:
            return Color.white
        }
    }

    var buttonStroke: Color {
        switch self {
        case .locked:
            return TowerYardTheme.panelStroke
        case .available:
            return Color.white.opacity(0.18)
        case .completed:
            return Color.green.opacity(0.65)
        }
    }
}

#Preview {
    NavigationStack {
        ContractsView(progressStore: TowerProgressStore(progress: TowerProgress()), onLaunch: { _ in })
            .environmentObject(TowerYardStore.preview)
    }
}

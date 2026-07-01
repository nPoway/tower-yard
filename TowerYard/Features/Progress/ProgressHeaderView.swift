import SwiftUI

struct ProgressHeaderView: View {
    let title: String
    let subtitle: String
    let store: TowerProgressStore
    let walletCoins: Int?

    init(title: String, subtitle: String, store: TowerProgressStore, walletCoins: Int? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.store = store
        self.walletCoins = walletCoins
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                HeaderStatPill(icon: "bitcoinsign.circle.fill", title: "Coins", value: "\(walletCoins ?? store.walletCoins)")
                HeaderStatPill(icon: "medal.fill", title: "Achievements", value: "\(store.unlockedAchievementCount)/\(AchievementCatalog.all.count)")
                HeaderStatPill(icon: "building.2.fill", title: "Buildings", value: "\(store.unlockedBuildingCount)/\(BuildingCollectionCatalog.all.count)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct HeaderStatPill: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

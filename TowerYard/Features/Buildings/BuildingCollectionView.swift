import SwiftUI

struct BuildingCollectionView: View {
    @ObservedObject var store: TowerProgressStore
    @EnvironmentObject private var yardStore: TowerYardStore

    private let columns = [
        GridItem(.adaptive(minimum: 250), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ProgressHeaderView(
                        title: "Building Collection",
                        subtitle: "Cards unlock from completed contracts, weather wins, style completions, and height milestones.",
                        store: store,
                        walletCoins: yardStore.coins
                    )

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(BuildingCollectionCatalog.all) { building in
                            BuildingCard(
                                building: building,
                                isUnlocked: store.isBuildingUnlocked(building)
                            )
                        }
                    }
                }
                .padding(16)
            }
            .appShellScrollContentBottomClearance()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct BuildingCard: View {
    let building: BuildingDefinition
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isUnlocked ? styleColor.opacity(0.2) : Color(.tertiarySystemFill))
                        .frame(width: 48, height: 48)
                    Image(systemName: isUnlocked ? "building.2.crop.circle.fill" : "lock.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isUnlocked ? styleColor : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(building.style.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(styleColor)
                }

                Spacer(minLength: 0)
            }

            Text(building.description)
                .font(.subheadline)
                .foregroundStyle(isUnlocked ? .secondary : Color.secondary.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                InfoChip(title: "Height", value: building.heightBand)
                InfoChip(title: "Difficulty", value: String(repeating: "I", count: building.difficulty))
            }

            Divider()

            Label(isUnlocked ? "Unlocked" : building.unlockRule.title, systemImage: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isUnlocked ? .teal : .secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isUnlocked ? styleColor.opacity(0.35) : Color(.separator).opacity(0.25), lineWidth: 1)
        )
    }

    private var styleColor: Color {
        switch building.style {
        case .brick:
            return .red
        case .glass:
            return .cyan
        case .steel:
            return .blue
        case .timber:
            return .brown
        case .concrete:
            return .gray
        case .artDeco:
            return .indigo
        case .modular:
            return .teal
        case .neon:
            return .pink
        case .industrial:
            return .orange
        case .classic:
            return .mint
        case .eco:
            return .green
        case .brutalist:
            return .purple
        }
    }
}

private struct InfoChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
    BuildingCollectionView(store: .preview(sampleData: true))
        .environmentObject(TowerYardStore.preview)
}

import SwiftUI

struct ShopView: View {
    @ObservedObject var store: TowerYardStore
    @State private var selectedSection: ShopSection = .skins
    @State private var notice: ShopNotice?

    var body: some View {
        YardScreen {
            ShopHeaderPanel(coins: store.coins, equippedSkin: store.equippedSkin)

            ShopSectionPicker(selection: $selectedSection)

            if let notice {
                ShopNoticeBanner(notice: notice)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            switch selectedSection {
            case .skins:
                skinsList
            case .tools:
                toolsList
            }
        }
        .animation(.easeInOut(duration: 0.18), value: notice)
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var skinsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(TowerYardCatalog.shopSkins) { skin in
                SkinShopCard(
                    skin: skin,
                    state: store.skinState(for: skin.id),
                    missingCoins: store.coinsNeeded(for: skin.price),
                    onBuy: { buySkin(skin) },
                    onEquip: { equipSkin(skin) }
                )
            }
        }
    }

    private var toolsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(TowerYardCatalog.shopTools) { tool in
                ToolShopCard(
                    tool: tool,
                    count: store.toolCount(for: tool.id),
                    missingCoins: store.coinsNeeded(for: tool.price),
                    onBuy: { buyTool(tool) }
                )
            }
        }
    }

    private func buySkin(_ skin: BlockSkin) {
        switch store.purchaseSkin(skin.id) {
        case .success:
            showNotice(.success("\(skin.name) unlocked. \(store.coins) coins left."))
        case .alreadyOwned:
            showNotice(.warning("\(skin.name) is already owned."))
        case .notOwned:
            showNotice(.warning("Unlock \(skin.name) before equipping it."))
        case .insufficientCoins(let missing):
            showNotice(.warning("Need \(missing) more coins for \(skin.name)."))
        }
    }

    private func equipSkin(_ skin: BlockSkin) {
        switch store.equipOwnedSkin(skin.id) {
        case .success:
            showNotice(.success("\(skin.name) equipped."))
        case .alreadyOwned:
            showNotice(.warning("\(skin.name) is already owned."))
        case .notOwned:
            showNotice(.warning("Unlock \(skin.name) before equipping it."))
        case .insufficientCoins:
            showNotice(.warning("Unlock \(skin.name) before equipping it."))
        }
    }

    private func buyTool(_ tool: GameToolDefinition) {
        switch store.purchaseTool(tool.id) {
        case .success:
            showNotice(.success("\(tool.name) added. Count: \(store.toolCount(for: tool.id))."))
        case .alreadyOwned:
            showNotice(.warning("\(tool.name) is a consumable tool."))
        case .notOwned:
            showNotice(.warning("\(tool.name) is not available."))
        case .insufficientCoins(let missing):
            showNotice(.warning("Need \(missing) more coins for \(tool.name)."))
        }
    }

    private func showNotice(_ notice: ShopNotice) {
        withAnimation(.easeInOut(duration: 0.18)) {
            self.notice = notice
        }
    }
}

private enum ShopSection: String, CaseIterable, Identifiable {
    case skins = "Skins"
    case tools = "Tools"

    var id: String { rawValue }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .skins:
            "square.stack.3d.up.fill"
        case .tools:
            "wrench.and.screwdriver.fill"
        }
    }
}

private enum ShopNotice: Equatable {
    case success(String)
    case warning(String)

    var message: String {
        switch self {
        case .success(let message), .warning(let message):
            message
        }
    }

    var systemImage: String {
        switch self {
        case .success:
            "checkmark.seal.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            TYTheme.teal
        case .warning:
            TYTheme.accent
        }
    }
}

private struct ShopHeaderPanel: View {
    let coins: Int
    let equippedSkin: BlockSkin

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            YardSectionHeader(
                title: "Yard Shop",
                subtitle: "Spend earned coins on block skins and one-use construction tools.",
                systemImage: "cart.fill"
            )

            HStack(spacing: 10) {
                StatPill(title: "Balance", value: "\(coins)", systemImage: "bitcoinsign.circle.fill")
                StatPill(title: "Equipped", value: equippedSkin.name, systemImage: "paintpalette.fill")
            }
        }
        .yardPanel(stroke: TYTheme.accent.opacity(0.45))
    }
}

private struct ShopSectionPicker: View {
    @Binding var selection: ShopSection

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ShopSection.allCases) { section in
                Button {
                    selection = section
                } label: {
                    Label(section.title, systemImage: section.systemImage)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(selection == section ? TYTheme.background : TYTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(selection == section ? TYTheme.accent : TYTheme.panelElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selection == section ? Color.clear : TYTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(TowerYardTheme.warningStripe.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(TYTheme.border, lineWidth: 1)
        )
    }
}

private struct ShopNoticeBanner: View {
    let notice: ShopNotice

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: notice.systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(notice.tint)
                .frame(width: 28, height: 28)

            Text(notice.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TYTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(TYTheme.panelElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(notice.tint.opacity(0.58), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct SkinShopCard: View {
    let skin: BlockSkin
    let state: SkinOwnershipState
    let missingCoins: Int
    let onBuy: () -> Void
    let onEquip: () -> Void

    private var canAfford: Bool {
        missingCoins == 0
    }

    private var isActionDisabled: Bool {
        state == .equipped || (state == .locked && !canAfford)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SkinStackPreview(skin: skin)
                    .frame(width: 94, height: 88)

                VStack(alignment: .leading, spacing: 8) {
                    Text(skin.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(TYTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(skin.description)
                        .font(.subheadline)
                        .foregroundStyle(TYTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        SkinStatusPill(state: state)
                        PricePill(price: skin.price)
                    }
                }
            }

            Button(actionTitle) {
                switch state {
                case .locked:
                    onBuy()
                case .owned:
                    onEquip()
                case .equipped:
                    break
                }
            }
            .buttonStyle(StoreButtonStyle(isProminent: !isActionDisabled))
            .disabled(isActionDisabled)
            .opacity(isActionDisabled ? 0.62 : 1)

            if state == .locked && !canAfford {
                Label("Need \(missingCoins) more coins", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TYTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .yardPanel(stroke: cardStroke)
    }

    private var actionTitle: String {
        switch state {
        case .locked:
            "Buy"
        case .owned:
            "Equip"
        case .equipped:
            "Equipped"
        }
    }

    private var cardStroke: Color {
        switch state {
        case .locked:
            TYTheme.border
        case .owned:
            TYTheme.teal.opacity(0.48)
        case .equipped:
            TYTheme.accent.opacity(0.62)
        }
    }
}

private struct SkinStatusPill: View {
    let state: SkinOwnershipState

    var body: some View {
        Label(statusText, systemImage: systemImage)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(TowerYardTheme.warningStripe.opacity(0.58))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.34), lineWidth: 1)
            )
    }

    private var statusText: String {
        switch state {
        case .locked:
            "Locked"
        case .owned:
            "Owned"
        case .equipped:
            "Equipped"
        }
    }

    private var systemImage: String {
        switch state {
        case .locked:
            "lock.fill"
        case .owned:
            "checkmark.circle.fill"
        case .equipped:
            "checkmark.seal.fill"
        }
    }

    private var tint: Color {
        switch state {
        case .locked:
            TYTheme.textSecondary
        case .owned:
            TYTheme.teal
        case .equipped:
            TYTheme.accent
        }
    }
}

private struct ToolShopCard: View {
    let tool: GameToolDefinition
    let count: Int
    let missingCoins: Int
    let onBuy: () -> Void

    private var canAfford: Bool {
        missingCoins == 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ToolIcon(systemImage: tool.systemImage)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(tool.name)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(TYTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }

                    Text(tool.description)
                        .font(.subheadline)
                        .foregroundStyle(TYTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(tool.application)
                        .font(.caption)
                        .foregroundStyle(TYTheme.textSecondary.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                ToolCountBadge(count: count)
                PricePill(price: tool.price)

                Spacer(minLength: 0)
            }

            Button("Buy") {
                onBuy()
            }
            .buttonStyle(StoreButtonStyle(isProminent: canAfford))
            .disabled(!canAfford)
            .opacity(canAfford ? 1 : 0.62)

            if !canAfford {
                Label("Need \(missingCoins) more coins", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TYTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .yardPanel(stroke: canAfford ? TYTheme.accent.opacity(0.34) : TYTheme.border)
    }
}

private struct ToolIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(TYTheme.accent)
            .frame(width: 48, height: 48)
            .background(TowerYardTheme.warningStripe.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(TYTheme.accent.opacity(0.42), lineWidth: 1)
            )
    }
}

private struct ToolCountBadge: View {
    let count: Int

    var body: some View {
        Label("Count \(count)", systemImage: "shippingbox.fill")
            .font(.system(.caption, design: .rounded, weight: .bold))
            .foregroundStyle(TYTheme.teal)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(TowerYardTheme.warningStripe.opacity(0.58))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(TYTheme.teal.opacity(0.36), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        ShopView(store: .preview)
    }
}

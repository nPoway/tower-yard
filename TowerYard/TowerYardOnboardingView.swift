import SwiftUI

struct TowerYardOnboardingView: View {
    let onComplete: () -> Void

    @State private var selection = 0

    private let steps = OnboardingStep.all

    var body: some View {
        ZStack {
            BlueprintGridBackground()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $selection) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        OnboardingStepView(step: step)
                            .tag(index)
                            .padding(.horizontal, 22)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
        }
    }

    private var topBar: some View {
        HStack {
            Image("towerLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Tower Yard")
                    .font(.headline.weight(.black))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                Text("Crane building arcade")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TowerYardTheme.textSecondary)
            }

            Spacer()

            Button("Skip") {
                onComplete()
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(TowerYardTheme.constructionYellow)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selection ? TowerYardTheme.constructionYellow : TowerYardTheme.concrete.opacity(0.32))
                        .frame(width: index == selection ? 28 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.18), value: selection)
                }
            }

            Button {
                if selection == steps.count - 1 {
                    onComplete()
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selection += 1
                    }
                }
            } label: {
                HStack {
                    Text(selection == steps.count - 1 ? "Start Building" : "Continue")
                        .font(.headline.weight(.bold))
                    Image(systemName: selection == steps.count - 1 ? "play.fill" : "chevron.right")
                        .font(.headline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(TowerYardTheme.warningStripe)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(TowerYardTheme.constructionYellow)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selection == steps.count - 1 ? "Start Building" : "Continue onboarding")
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 24)
    }
}

private struct OnboardingStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 18)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TowerYardTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(step.tint.opacity(0.48), lineWidth: 1)
                    )

                visualView
                    .padding(24)
            }
            .frame(maxWidth: 360)
            .frame(height: 280)
            .shadow(color: .black.opacity(0.26), radius: 20, x: 0, y: 14)

            VStack(spacing: 10) {
                Label(step.kicker, systemImage: step.systemImage)
                    .font(.caption.weight(.black))
                    .textCase(.uppercase)
                    .foregroundStyle(step.tint)

                Text(step.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(step.subtitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 360)

            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var visualView: some View {
        switch step.visual {
        case .crane:
            OnboardingCraneVisual()
        case .tower:
            OnboardingTowerVisual()
        case .progress:
            OnboardingProgressVisual()
        }
    }
}

private struct OnboardingStep: Identifiable {
    let id: String
    let kicker: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let visual: OnboardingVisualKind

    static let all: [OnboardingStep] = [
        OnboardingStep(
            id: "place",
            kicker: "Crane Control",
            title: "Place clean blocks",
            subtitle: "Time each drop around the center line and the stack stays easier to control.",
            systemImage: "arrow.down.to.line",
            tint: TowerYardTheme.constructionYellow,
            visual: .crane
        ),
        OnboardingStep(
            id: "balance",
            kicker: "Stability",
            title: "Build for balance",
            subtitle: "Wide bases, lighter tops, and steady alignment help the tower survive tougher jobs.",
            systemImage: "scalemass.fill",
            tint: TowerYardTheme.beamBlue,
            visual: .tower
        ),
        OnboardingStep(
            id: "progress",
            kicker: "Yard Progress",
            title: "Earn and upgrade",
            subtitle: "Complete contracts, collect coins, unlock skins, and push for a higher endless run.",
            systemImage: "bitcoinsign.circle.fill",
            tint: .green,
            visual: .progress
        )
    ]
}

private enum OnboardingVisualKind {
    case crane
    case tower
    case progress
}

private struct OnboardingCraneVisual: View {
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(TowerYardTheme.constructionYellow)
                    .frame(height: 12)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(TowerYardTheme.warningStripe.opacity(0.72))
                            .frame(height: 2)
                            .offset(y: 5)
                    }

                Rectangle()
                    .fill(TowerYardTheme.concrete.opacity(0.78))
                    .frame(width: 3, height: 86)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(TowerYardTheme.brick)
                    .frame(width: 118, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(TowerYardTheme.constructionYellow.opacity(0.45), lineWidth: 1)
                    )
            }

            Image(systemName: "arrow.down")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(TowerYardTheme.textPrimary)
                .offset(y: -8)
        }
    }
}

private struct OnboardingTowerVisual: View {
    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color(for: index))
                    .frame(width: width(for: index), height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.white.opacity(0.20), lineWidth: 1)
                    )
            }

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(TowerYardTheme.concrete.opacity(0.88))
                .frame(width: 188, height: 14)
        }
    }

    private func width(for index: Int) -> CGFloat {
        [92, 108, 128, 146, 164, 182][index]
    }

    private func color(for index: Int) -> Color {
        [TowerYardTheme.constructionYellow, TowerYardTheme.beamBlue, TowerYardTheme.concrete, TowerYardTheme.brick, TowerYardTheme.brick, TowerYardTheme.concrete][index]
    }
}

private struct OnboardingProgressVisual: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("towerLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 12) {
                progressBadge("Coins", "120", "bitcoinsign.circle.fill", TowerYardTheme.constructionYellow)
                progressBadge("Best", "18 m", "arrow.up.right", TowerYardTheme.beamBlue)
            }
        }
    }

    private func progressBadge(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(TowerYardTheme.textPrimary)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(TowerYardTheme.textSecondary)
        }
        .frame(width: 92, height: 76)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(TowerYardTheme.deepSteel.opacity(0.74))
        )
    }
}

#Preview {
    TowerYardOnboardingView {}
}

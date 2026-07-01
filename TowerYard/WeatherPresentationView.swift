//
//  WeatherPresentationView.swift
//  TowerYard
//
//  Created by Codex on 30.06.2026.
//

import SwiftUI

struct WeatherPresentationView: View {
    @State private var weather = WeatherState(condition: .clear, difficulty: 0.35)

    private let adviceService = ForemanAdviceService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weather")
                        .font(.largeTitle.bold())
                    Text("Reusable visual overlay and gameplay values for tower sessions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                WeatherPreviewSurface(weather: weather)
                    .frame(height: 310)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.26), lineWidth: 1)
                    }

                WeatherSelectionPanel(weather: $weather)

                WeatherEffectsPanel(effects: weather.gameplayEffects)

                WeatherContextTipCard(
                    advice: adviceService.contextualTip(
                        mode: .endlessTower,
                        weather: weather,
                        failureReason: weather.condition == .wind ? .wind : nil
                    )
                )
            }
            .padding(20)
        }
        .background(TowerYardPalette.background)
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WeatherPreviewSurface: View {
    let weather: WeatherState

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    weather.condition.skyTopColor,
                    weather.condition.skyBottomColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            WeatherSkyObject(condition: weather.condition)
                .padding(26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.31, green: 0.43, blue: 0.27),
                            Color(red: 0.15, green: 0.22, blue: 0.17)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 70)

            WeatherTowerPreview(weather: weather)
                .padding(.bottom, 44)

            VStack {
                HStack {
                    Label(weather.condition.title, systemImage: weather.condition.symbolName)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
        }
        .weatherOverlay(weather)
        .accessibilityLabel("Weather preview \(weather.condition.title)")
    }
}

private struct WeatherSkyObject: View {
    let condition: WeatherCondition

    var body: some View {
        Circle()
            .fill(condition == .night ? Color.white.opacity(0.78) : Color.yellow.opacity(0.9))
            .frame(width: 56, height: 56)
            .shadow(
                color: condition == .night ? .white.opacity(0.2) : .yellow.opacity(0.35),
                radius: 26
            )
            .opacity(condition == .fog ? 0.25 : 1)
    }
}

private struct WeatherTowerPreview: View {
    let weather: WeatherState

    private var lean: Double {
        weather.condition == .wind ? weather.difficulty * 2.8 : 0
    }

    var body: some View {
        VStack(spacing: 5) {
            TriangleRoof()
                .fill(Color(red: 0.55, green: 0.18, blue: 0.16))
                .frame(width: 88, height: 40)

            PreviewBlock(width: 82, color: Color(red: 0.86, green: 0.43, blue: 0.31), hasWindow: true)
                .offset(x: weather.condition == .wind ? 8 * weather.difficulty : 0)

            PreviewBlock(width: 118, color: Color(red: 0.91, green: 0.67, blue: 0.37), hasWindow: true)
                .offset(x: weather.condition == .wind ? -5 * weather.difficulty : 0)

            PreviewBeam()
                .frame(width: 140, height: 24)

            PreviewBlock(width: 156, color: Color(red: 0.42, green: 0.65, blue: 0.76), hasWindow: false)
            PreviewBlock(width: 188, color: Color(red: 0.72, green: 0.57, blue: 0.42), hasWindow: true)
        }
        .rotationEffect(.degrees(lean), anchor: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: lean)
    }
}

private struct PreviewBlock: View {
    let width: CGFloat
    let color: Color
    let hasWindow: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.18))
                        .frame(height: 8)
                }
                .shadow(color: .black.opacity(0.14), radius: 4, y: 2)

            if hasWindow {
                HStack(spacing: 16) {
                    PreviewWindow()
                    PreviewWindow()
                }
            }
        }
        .frame(width: width, height: 42)
    }
}

private struct PreviewWindow: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Color.white.opacity(0.55))
            .frame(width: 18, height: 20)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            }
    }
}

private struct PreviewBeam: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(Color(red: 0.45, green: 0.28, blue: 0.18))
            .overlay {
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 4)
                    }
                }
            }
            .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
    }
}

private struct TriangleRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct WeatherSelectionPanel: View {
    @Binding var weather: WeatherState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Conditions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 10)], spacing: 10) {
                ForEach(WeatherCondition.allCases) { condition in
                    Button {
                        weather.condition = condition
                    } label: {
                        Label(condition.title, systemImage: condition.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 38)
                    }
                    .buttonStyle(WeatherConditionButtonStyle(isSelected: weather.condition == condition))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weather Difficulty")
                    Spacer()
                    Text(weather.difficulty.formatted(.percent.precision(.fractionLength(0))))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.semibold))

                Slider(value: $weather.difficulty, in: 0...1)
                    .tint(weather.condition.accentColor)
            }
        }
        .padding(16)
        .background(TowerYardPalette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WeatherConditionButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct WeatherEffectsPanel: View {
    let effects: WeatherGameplayEffects

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gameplay Values")
                .font(.headline)

            HStack(spacing: 10) {
                WeatherMetricView(title: "Wind Load", value: effects.windLoad, isRiskMetric: true)
                WeatherMetricView(title: "Grip", value: effects.materialGrip, isRiskMetric: false)
            }

            HStack(spacing: 10) {
                WeatherMetricView(title: "Visibility", value: effects.visibility, isRiskMetric: false)
                WeatherMetricView(title: "Tolerance", value: effects.placementTolerance, isRiskMetric: false)
            }
        }
        .padding(16)
        .background(TowerYardPalette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WeatherMetricView: View {
    let title: String
    let value: Double
    let isRiskMetric: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ProgressView(value: value, total: 1)
                .tint(metricColor)

            Text(value.formatted(.number.precision(.fractionLength(2))))
                .font(.footnote.monospacedDigit())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var metricColor: Color {
        if isRiskMetric {
            return value > 0.7 ? .orange : .green
        }

        return value < 0.55 ? .orange : .green
    }
}

private struct WeatherContextTipCard: View {
    let advice: ForemanAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Context Tip", systemImage: "lightbulb")
                .font(.headline)
            Text(advice.message)
                .font(.body)
            Text(advice.topic.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(TowerYardPalette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    WeatherPresentationView()
}

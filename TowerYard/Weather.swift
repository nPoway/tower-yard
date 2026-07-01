//
//  Weather.swift
//  TowerYard
//
//  Created by Codex on 30.06.2026.
//

import SwiftUI

enum WeatherCondition: String, CaseIterable, Identifiable {
    case clear = "Clear"
    case wind = "Wind"
    case rain = "Rain"
    case night = "Night"
    case fog = "Fog"

    var id: String { rawValue }
    var title: String { rawValue }

    var symbolName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .wind:
            return "wind"
        case .rain:
            return "cloud.rain.fill"
        case .night:
            return "moon.stars.fill"
        case .fog:
            return "cloud.fog.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .clear:
            return .yellow
        case .wind:
            return .cyan
        case .rain:
            return .blue
        case .night:
            return .indigo
        case .fog:
            return .gray
        }
    }

    var skyTopColor: Color {
        switch self {
        case .clear:
            return Color(red: 0.40, green: 0.72, blue: 0.96)
        case .wind:
            return Color(red: 0.56, green: 0.74, blue: 0.84)
        case .rain:
            return Color(red: 0.30, green: 0.42, blue: 0.53)
        case .night:
            return Color(red: 0.06, green: 0.08, blue: 0.20)
        case .fog:
            return Color(red: 0.66, green: 0.70, blue: 0.70)
        }
    }

    var skyBottomColor: Color {
        switch self {
        case .clear:
            return Color(red: 0.78, green: 0.91, blue: 1.0)
        case .wind:
            return Color(red: 0.78, green: 0.88, blue: 0.90)
        case .rain:
            return Color(red: 0.42, green: 0.50, blue: 0.56)
        case .night:
            return Color(red: 0.14, green: 0.16, blue: 0.32)
        case .fog:
            return Color(red: 0.82, green: 0.84, blue: 0.80)
        }
    }
}

struct WeatherState: Equatable {
    var condition: WeatherCondition
    var difficulty: Double

    init(condition: WeatherCondition, difficulty: Double = 0) {
        self.condition = condition
        self.difficulty = min(max(difficulty, 0), 1)
    }

    var intensity: Double {
        min(max(difficulty, 0), 1)
    }

    var gameplayEffects: WeatherGameplayEffects {
        let value = intensity

        switch condition {
        case .clear:
            return WeatherGameplayEffects(
                windLoad: 0,
                materialGrip: 1,
                visibility: 1,
                placementTolerance: 1
            )
        case .wind:
            return WeatherGameplayEffects(
                windLoad: 0.25 + value * 0.75,
                materialGrip: 0.95 - value * 0.10,
                visibility: 0.96 - value * 0.10,
                placementTolerance: 0.88 - value * 0.32
            )
        case .rain:
            return WeatherGameplayEffects(
                windLoad: 0.10 + value * 0.12,
                materialGrip: 0.82 - value * 0.38,
                visibility: 0.88 - value * 0.26,
                placementTolerance: 0.90 - value * 0.24
            )
        case .night:
            return WeatherGameplayEffects(
                windLoad: 0.04,
                materialGrip: 0.92,
                visibility: 0.70 - value * 0.34,
                placementTolerance: 0.84 - value * 0.24
            )
        case .fog:
            return WeatherGameplayEffects(
                windLoad: 0.06 + value * 0.10,
                materialGrip: 0.90,
                visibility: 0.72 - value * 0.42,
                placementTolerance: 0.86 - value * 0.30
            )
        }
    }
}

struct WeatherGameplayEffects: Equatable {
    let windLoad: Double
    let materialGrip: Double
    let visibility: Double
    let placementTolerance: Double
}

struct WeatherOverlay: View {
    let weather: WeatherState

    var body: some View {
        ZStack {
            WeatherTintLayer(weather: weather)
            weatherEffect
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var weatherEffect: some View {
        switch weather.condition {
        case .clear:
            ClearGlowLayer(weather: weather)
        case .wind:
            WindStreakLayer(weather: weather)
        case .rain:
            RainLayer(weather: weather)
        case .night:
            NightLayer(weather: weather)
        case .fog:
            FogLayer(weather: weather)
        }
    }
}

extension View {
    func weatherOverlay(_ weather: WeatherState) -> some View {
        overlay {
            WeatherOverlay(weather: weather)
        }
    }
}

private struct WeatherTintLayer: View {
    let weather: WeatherState

    var body: some View {
        switch weather.condition {
        case .clear:
            LinearGradient(
                colors: [.yellow.opacity(0.08 + weather.intensity * 0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .wind:
            Color.cyan.opacity(0.06 + weather.intensity * 0.08)
        case .rain:
            Color.blue.opacity(0.12 + weather.intensity * 0.18)
        case .night:
            Color.black.opacity(0.28 + weather.intensity * 0.30)
        case .fog:
            Color.white.opacity(0.18 + weather.intensity * 0.20)
        }
    }
}

private struct ClearGlowLayer: View {
    let weather: WeatherState

    var body: some View {
        Circle()
            .fill(.yellow.opacity(0.10 + weather.intensity * 0.10))
            .frame(width: 180, height: 180)
            .blur(radius: 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(-20)
    }
}

private struct WindStreakLayer: View {
    let weather: WeatherState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let speed = 0.35 + weather.intensity * 0.70
                let count = 12 + Int(weather.intensity * 16)

                for index in 0..<count {
                    let phase = (time * speed + Double(index) * 0.12).truncatingRemainder(dividingBy: 1)
                    let y = CGFloat(Double((index * 23) % 100) / 100.0) * size.height
                    let x = CGFloat(phase) * (size.width + 120) - 80
                    let length = CGFloat(40 + weather.intensity * 46)

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + length, y: y - length * 0.18))
                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.28 + weather.intensity * 0.22)),
                        style: StrokeStyle(lineWidth: 1.2 + weather.intensity * 1.3, lineCap: .round)
                    )
                }
            }
        }
    }
}

private struct RainLayer: View {
    let weather: WeatherState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let speed = 0.58 + weather.intensity * 1.10
                let count = 28 + Int(weather.intensity * 34)

                for index in 0..<count {
                    let phase = (time * speed + Double(index) * 0.041).truncatingRemainder(dividingBy: 1)
                    let x = CGFloat(Double((index * 37) % 100) / 100.0) * (size.width + 70) - 35
                    let y = CGFloat(phase) * (size.height + 90) - 45
                    let drop = CGFloat(24 + weather.intensity * 28)

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - drop * 0.22, y: y + drop))
                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.34 + weather.intensity * 0.28)),
                        style: StrokeStyle(lineWidth: 1 + weather.intensity * 1.2, lineCap: .round)
                    )
                }
            }
        }
    }
}

private struct NightLayer: View {
    let weather: WeatherState

    var body: some View {
        Canvas { context, size in
            let count = 18 + Int(weather.intensity * 12)

            for index in 0..<count {
                let x = CGFloat(Double((index * 41) % 100) / 100.0) * size.width
                let y = CGFloat(Double((index * 29) % 58) / 100.0) * size.height
                let diameter = CGFloat(1.6 + Double(index % 3) * 0.8)
                let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.45)))
            }
        }
    }
}

private struct FogLayer: View {
    let weather: WeatherState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            GeometryReader { proxy in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let intensity = CGFloat(weather.intensity)

                ForEach(0..<6, id: \.self) { index in
                    let phase = CGFloat((time * (0.025 + weather.intensity * 0.035) + Double(index) * 0.16).truncatingRemainder(dividingBy: 1))
                    let travel = proxy.size.width * 0.5
                    let y = proxy.size.height * CGFloat(index + 1) / 7

                    Capsule()
                        .fill(.white.opacity(0.16 + weather.intensity * 0.12))
                        .frame(
                            width: proxy.size.width * (0.60 + CGFloat(index % 3) * 0.14),
                            height: 34 + intensity * 28
                        )
                        .blur(radius: 16 + intensity * 12)
                        .offset(x: phase * travel - travel / 2, y: y)
                }
            }
        }
    }
}

struct YardWeatherDemoView: View {
    @State private var selectedCondition: WeatherCondition = .wind

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        selectedCondition.skyTopColor,
                        selectedCondition.skyBottomColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .weatherOverlay(WeatherState(condition: selectedCondition, difficulty: 0.65))

                VStack(alignment: .leading, spacing: 6) {
                    Label(selectedCondition.title, systemImage: selectedCondition.symbolName)
                        .font(.headline.weight(.bold))
                    Text("Weather preview")
                        .font(.subheadline)
                }
                .foregroundStyle(.white)
                .shadow(radius: 4)
                .padding(16)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Picker("Weather", selection: $selectedCondition) {
                ForEach(WeatherCondition.allCases) { condition in
                    Text(condition.title).tag(condition)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
    }
}

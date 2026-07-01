//
//  ForemanAdvice.swift
//  TowerYard
//
//  Created by Codex on 30.06.2026.
//

import Foundation

enum ForemanAdviceTopic: String, CaseIterable, Identifiable {
    case foundation = "Foundation"
    case wind = "Wind"
    case roofCap = "Roof Cap"
    case windows = "Windows"
    case beams = "Beams"
    case stability = "Stability"
    case contracts = "Contracts"
    case endlessMode = "Endless"
    case tools = "Tools"
    case balance = "Balance"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .foundation:
            "rectangle.split.3x1.fill"
        case .wind:
            "wind"
        case .roofCap:
            "house.fill"
        case .windows:
            "square.grid.2x2.fill"
        case .beams:
            "line.3.horizontal"
        case .stability:
            "exclamationmark.triangle.fill"
        case .contracts:
            "doc.text.fill"
        case .endlessMode:
            "infinity"
        case .tools:
            "wrench.and.screwdriver.fill"
        case .balance:
            "scalemass.fill"
        }
    }

    var keywords: [String] {
        switch self {
        case .foundation:
            ["foundation", "base", "footing", "corner", "start", "ground"]
        case .wind:
            ["wind", "gust", "storm", "weather", "sway", "push"]
        case .roofCap:
            ["roof", "cap", "top", "crown"]
        case .windows:
            ["window", "windows", "glass", "pane", "openings", "facade"]
        case .beams:
            ["beam", "beams", "steel", "wood", "timber", "frame", "support", "brace"]
        case .stability:
            ["stable", "stability", "wobble", "wobbling", "lean", "tilt", "collapse", "topple"]
        case .contracts:
            ["contract", "contracts", "job", "client", "objective", "deadline", "bonus"]
        case .endlessMode:
            ["endless", "record", "high", "height", "streak", "run"]
        case .tools:
            ["tool", "tools", "hammer", "wrench", "level", "leveling", "boost"]
        case .balance:
            ["balance", "center", "weight", "heavy", "counterweight", "load"]
        }
    }
}

enum TowerGameMode: String, CaseIterable, Identifiable {
    case endlessTower = "Endless Tower"
    case contractBuild = "Contract Build"

    var id: String { rawValue }
}

enum TowerFailureReason {
    case unstableBase
    case leaningStack
    case wind
    case rainSlip
    case lowVisibility
    case weakMaterial
    case missedContractGoal
    case toolMisuse
    case heightPressure
}

struct ForemanAdvice: Identifiable, Hashable {
    let id: String
    let topic: ForemanAdviceTopic
    let message: String
}

struct ForemanAdviceService {
    var advice: [ForemanAdvice] = Self.defaultAdvice

    func messages(for topic: ForemanAdviceTopic) -> [ForemanAdvice] {
        advice.filter { $0.topic == topic }
    }

    func message(for topic: ForemanAdviceTopic, offset: Int) -> ForemanAdvice {
        let topicAdvice = messages(for: topic)
        guard !topicAdvice.isEmpty else {
            return tip(id: "foundation-flat")
        }

        return topicAdvice[offset % topicAdvice.count]
    }

    func generalAdvice(offset: Int) -> ForemanAdvice {
        let generalIDs = [
            "foundation-flat",
            "balance-heavy-base",
            "stability-counter-lean",
            "tools-save"
        ]
        return tip(id: generalIDs[offset % generalIDs.count])
    }

    func topic(for prompt: String) -> ForemanAdviceTopic? {
        let normalized = prompt
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        return ForemanAdviceTopic.allCases.first { topic in
            topic.keywords.contains { normalized.contains($0) }
        }
    }

    func contextualTip(
        mode: TowerGameMode? = nil,
        weather: WeatherState? = nil,
        failureReason: TowerFailureReason? = nil
    ) -> ForemanAdvice {
        if let failureReason {
            return tip(forFailureReason: failureReason)
        }

        if let weather {
            switch weather.condition {
            case .clear:
                break
            case .wind:
                return tip(id: "wind-wide-base")
            case .rain:
                return tip(id: "beams-wet-steel")
            case .night:
                return tip(id: "windows-after-frame")
            case .fog:
                return tip(id: "foundation-corners")
            }
        }

        if let mode {
            switch mode {
            case .endlessTower:
                return tip(id: "endless-first-five")
            case .contractBuild:
                return tip(id: "contracts-objective-first")
            }
        }

        return tip(id: "balance-heavy-base")
    }

    func contextualMessage(
        mode: TowerGameMode? = nil,
        weather: WeatherState? = nil,
        failureReason: TowerFailureReason? = nil
    ) -> String {
        contextualTip(mode: mode, weather: weather, failureReason: failureReason).message
    }

    private func tip(forFailureReason reason: TowerFailureReason) -> ForemanAdvice {
        switch reason {
        case .unstableBase:
            return tip(id: "foundation-flat")
        case .leaningStack:
            return tip(id: "stability-counter-lean")
        case .wind:
            return tip(id: "wind-wide-base")
        case .rainSlip:
            return tip(id: "beams-wet-steel")
        case .lowVisibility:
            return tip(id: "windows-after-frame")
        case .weakMaterial:
            return tip(id: "beams-frame-first")
        case .missedContractGoal:
            return tip(id: "contracts-objective-first")
        case .toolMisuse:
            return tip(id: "tools-save")
        case .heightPressure:
            return tip(id: "endless-first-five")
        }
    }

    private func tip(id: String) -> ForemanAdvice {
        advice.first { $0.id == id } ?? Self.defaultAdvice[0]
    }
}

extension ForemanAdviceService {
    static let defaultAdvice: [ForemanAdvice] = [
        ForemanAdvice(
            id: "foundation-flat",
            topic: .foundation,
            message: "Start with a flat, wide foundation. A clean first row buys you more height than any late correction."
        ),
        ForemanAdvice(
            id: "foundation-corners",
            topic: .foundation,
            message: "Check both base corners after every heavy drop. One twisted corner will pull the whole tower off line."
        ),
        ForemanAdvice(
            id: "wind-wide-base",
            topic: .wind,
            message: "When wind picks up, build wider before you build taller. Extra width is your best counterweight."
        ),
        ForemanAdvice(
            id: "roof-light-cap",
            topic: .roofCap,
            message: "Cap the roof with a light piece once the last floor is level. Do not use the cap to fix a lean."
        ),
        ForemanAdvice(
            id: "roof-finish-low-risk",
            topic: .roofCap,
            message: "If the tower is already shaking, finish with the safest cap instead of chasing one more perfect floor."
        ),
        ForemanAdvice(
            id: "windows-after-frame",
            topic: .windows,
            message: "Place windows after the frame is steady. Glass looks good, but it should never carry the load."
        ),
        ForemanAdvice(
            id: "windows-even-spacing",
            topic: .windows,
            message: "Keep window rows even on both sides. Uneven glass placement makes a light floor feel off balance."
        ),
        ForemanAdvice(
            id: "beams-frame-first",
            topic: .beams,
            message: "Set beams before decorative blocks. A frame-first floor survives bad weather and rushed drops."
        ),
        ForemanAdvice(
            id: "beams-crossbrace",
            topic: .beams,
            message: "Use cross beams when the middle starts to flex. Support the span before stacking more weight above it."
        ),
        ForemanAdvice(
            id: "beams-wet-steel",
            topic: .beams,
            message: "In rain, treat heavy beams like permanent choices. Place them low, centered, and only once."
        ),
        ForemanAdvice(
            id: "stability-counter-lean",
            topic: .stability,
            message: "If the tower leans right, place the next solid block slightly left of center and let the stack settle."
        ),
        ForemanAdvice(
            id: "contracts-objective-first",
            topic: .contracts,
            message: "For contracts, build to the job objective first. Extra height is only worth it after the requirement is safe."
        ),
        ForemanAdvice(
            id: "endless-first-five",
            topic: .endlessMode,
            message: "In Endless, the first five blocks decide most of the run. Use them to make a base you can trust."
        ),
        ForemanAdvice(
            id: "tools-save",
            topic: .tools,
            message: "Save one tool for late trouble. Most runs fail right after the tower starts to feel easy."
        ),
        ForemanAdvice(
            id: "balance-heavy-base",
            topic: .balance,
            message: "Keep heavy materials low and centered. Balance starts at the base, not at the floor that is wobbling."
        )
    ]
}

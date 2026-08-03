import Combine
import Foundation
import SwiftUI

@MainActor
final class YardGameStore: ObservableObject {
    @Published private(set) var mode: YardRunMode
    @Published private(set) var configuration: YardGameConfiguration
    @Published private(set) var blocks: [YardPlacedPiece] = []
    @Published private(set) var nextPiece: YardPiece = .placeholder
    @Published private(set) var phase: YardRoundPhase = .playing
    @Published private(set) var score = 0
    @Published private(set) var coins = 0
    @Published private(set) var perfectBlocks = 0
    @Published private(set) var wind: CGFloat = 0
    @Published private(set) var instability: CGFloat = 0
    @Published private(set) var lean: CGFloat = 0
    @Published private(set) var usedToolIDs: [GameToolID] = []
    @Published private(set) var safetyNetArmed = false
    @Published private(set) var foundationAssistDropsRemaining = 0
    @Published private(set) var craneSlowdownDropsRemaining = 0
    @Published private(set) var activeToolMessage: String?
    @Published private(set) var lastResult: YardGameResult?
    @Published private(set) var lastPlacementFeedback: YardPlacementFeedback?

    private let resultKey = "towerYard.gameResults.v1"
    private let defaults: UserDefaults

    init(
        configuration: YardGameConfiguration,
        mode: YardRunMode = .contracts,
        defaults: UserDefaults = .standard
    ) {
        self.configuration = configuration
        self.mode = mode
        self.defaults = defaults
        resetRound()
    }

    var height: Int {
        blocks.count
    }

    var targetHeight: Int? {
        mode == .contracts ? configuration.targetHeight : nil
    }

    var targetLabel: String {
        switch mode {
        case .contracts:
            "Goal \(configuration.targetHeight)"
        case .endless:
            "Record Run"
        case .zen:
            "Saved Build"
        }
    }

    var title: String {
        switch mode {
        case .contracts:
            configuration.title
        case .endless:
            "Endless Tower"
        case .zen:
            "Legacy Build"
        }
    }

    var goal: String {
        switch mode {
        case .contracts:
            configuration.goal
        case .endless:
            "Build as high as possible before the tower reaches a critical lean."
        case .zen:
            "Saved free-build result from an earlier app version."
        }
    }

    var towerVisualHeight: CGFloat {
        blocks.reduce(0) { $0 + $1.height }
    }

    var supportCenterOffset: CGFloat {
        blocks.last?.centerOffset ?? 0
    }

    var supportWidth: CGFloat {
        max(96, blocks.last?.width ?? 164)
    }

    var tiltDangerLevel: CGFloat {
        let leanPressure = abs(lean) / 1.22
        let swayPressure = instability / 3.05
        return min(1, max(leanPressure, swayPressure))
    }

    var usedTools: [String] {
        GameToolID.allCases.compactMap { toolID in
            let useCount = usedToolIDs.filter { $0 == toolID }.count
            guard useCount > 0 else { return nil }

            let name = TowerYardCatalog.tool(for: toolID).shortName
            return useCount == 1 ? name : "\(name) ×\(useCount)"
        }
    }

    var helperToolsAllowed: Bool {
        configuration.helperToolsAllowed
    }

    var activeToolStatus: String? {
        if safetyNetArmed {
            return "Safety Net armed"
        }
        if foundationAssistDropsRemaining > 0 {
            return "Foundation Booster: \(foundationAssistDropsRemaining) drops left"
        }
        if craneSlowdownDropsRemaining > 0 {
            return "Crane Slowdown: \(craneSlowdownDropsRemaining) drops left"
        }
        return activeToolMessage
    }

    func configure(for session: GameSession) {
        recordZenSnapshotIfNeeded()
        configuration = .session(session)
        mode = .contracts
        resetRound()
    }

    func setMode(_ newMode: YardRunMode) {
        guard newMode != mode else { return }
        recordZenSnapshotIfNeeded()
        mode = newMode
        resetRound()
    }

    func togglePause() {
        guard !phase.isTerminal else { return }

        switch phase {
        case .playing:
            phase = .paused
        case .paused:
            phase = .playing
        case .won, .lost:
            break
        }
    }

    func restartRound() {
        recordZenSnapshotIfNeeded()
        resetRound()
    }

    func canUseTool(_ toolID: GameToolID) -> Bool {
        guard case .playing = phase, helperToolsAllowed else {
            return false
        }

        switch toolID {
        case .levelingHammer:
            return !blocks.isEmpty
        case .safetyNet:
            return !safetyNetArmed
        case .foundationBooster:
            return foundationAssistDropsRemaining == 0 && height < 7
        case .craneSlowdown:
            return craneSlowdownDropsRemaining == 0
        }
    }

    @discardableResult
    func useTool(_ toolID: GameToolID) -> YardToolUseResult {
        guard case .playing = phase else {
            return .unavailable("Finish or restart the current build before using a tool.")
        }

        guard helperToolsAllowed else {
            return .unavailable("Helper tools are restricted for this order.")
        }

        guard canUseTool(toolID) else {
            return .unavailable(unavailableToolMessage(for: toolID))
        }

        switch toolID {
        case .levelingHammer:
            levelLastBlock()
            registerToolUse(toolID, message: "Leveling Hammer straightened the last block.")
        case .safetyNet:
            safetyNetArmed = true
            registerToolUse(toolID, message: "Safety Net armed for the next failed drop.")
        case .foundationBooster:
            foundationAssistDropsRemaining = 4
            registerToolUse(toolID, message: "Foundation Booster is protecting the next four drops.")
        case .craneSlowdown:
            craneSlowdownDropsRemaining = 5
            registerToolUse(toolID, message: "Crane movement slowed for the next five drops.")
        }

        return .applied(activeToolMessage ?? "Tool applied.")
    }

    func craneOffset(stageWidth: CGFloat, at date: Date) -> CGFloat {
        let travel = max(40, (stageWidth - nextPiece.width) * 0.37)
        let time = CGFloat(date.timeIntervalSinceReferenceDate)
        let craneModifier = configuration.dailyModifier?.craneSpeedMultiplier ?? 1
        let slowdownMultiplier: CGFloat = craneSlowdownDropsRemaining > 0 ? 0.56 : 1
        let speed = (0.72 + min(CGFloat(height) * 0.026, 0.44) + abs(wind) * 0.035) * craneModifier * slowdownMultiplier
        let phaseOffset = CGFloat(height) * 0.58 + CGFloat(configuration.contractIndex) * 0.31
        let drift = wind * 12
        return sin(time * speed + phaseOffset) * travel + drift
    }

    func towerRotation(at date: Date) -> Double {
        guard !blocks.isEmpty else { return 0 }

        let time = date.timeIntervalSinceReferenceDate
        let stress = min(1.2, Double(abs(lean) + instability * 0.22 + abs(wind) * 0.15))
        let oscillation = sin(time * (1.45 + Double(abs(wind)) * 0.22))
        let leanBias = Double(lean) * 3.8
        return leanBias + oscillation * stress * 3.4
    }

    func placeCurrentBlockFromCrane(stageWidth: CGFloat, at date: Date) {
        placeCurrentBlock(centerOffset: craneOffset(stageWidth: stageWidth, at: date))
    }

    private func placeCurrentBlock(centerOffset: CGFloat) {
        guard case .playing = phase else { return }

        var metrics = placementMetrics(for: nextPiece, centerOffset: centerOffset)
        var placementCenter = centerOffset
        var placementQuality = metrics.quality
        var feedbackMessage = metrics.feedbackMessage
        var safetyNetCaughtDrop = false

        if mode != .zen, metrics.failed, safetyNetArmed {
            safetyNetArmed = false
            safetyNetCaughtDrop = true
            placementCenter = blocks.last?.centerOffset ?? 0
            metrics = placementMetrics(for: nextPiece, centerOffset: placementCenter)
            placementQuality = .good
            feedbackMessage = "Safety Net caught the drop"
            activeToolMessage = "Safety Net used. The tower is still standing."
        }

        let placed = YardPlacedPiece(
            width: nextPiece.width,
            height: nextPiece.height,
            weight: nextPiece.weight,
            material: nextPiece.material,
            kind: nextPiece.kind,
            centerOffset: placementCenter,
            perfect: placementQuality == .perfect,
            quality: placementQuality
        )

        blocks.append(placed)
        perfectBlocks += placementQuality == .perfect ? 1 : 0
        score += scoreForPlacement(normalizedOffset: metrics.normalizedOffset, quality: placementQuality)
        coins += coinsForPlacement(normalizedOffset: metrics.normalizedOffset, quality: placementQuality)
        instability = mode == .zen ? min(metrics.instability, 2.15) : metrics.instability
        lean = mode == .zen ? min(max(metrics.lean, -1.2), 1.2) : metrics.lean
        lastPlacementFeedback = YardPlacementFeedback(
            quality: placementQuality,
            message: feedbackMessage,
            stabilityLevel: tiltDangerLevel
        )
        consumeActiveToolCharges()

        if mode != .zen, metrics.failed, !safetyNetCaughtDrop {
            finish(.lost(reason: metrics.reason), outcome: .defeat)
            return
        }

        if mode == .contracts, let targetHeight, height >= targetHeight {
            let modifierBonus = configuration.dailyModifier?.completionBonus(
                perfectBlocks: perfectBlocks,
                helperToolUses: usedToolIDs.count
            ) ?? 0
            coins += perfectBlocks + modifierBonus
            score += 80 + configuration.targetHeight * 8
            finish(.won, outcome: .victory)
            return
        }

        wind = windForHeight(height)
        nextPiece = makePiece(for: height)
    }

    private func resetRound() {
        blocks = []
        phase = .playing
        score = 0
        coins = 0
        perfectBlocks = 0
        instability = 0
        lean = 0
        usedToolIDs = []
        safetyNetArmed = false
        foundationAssistDropsRemaining = 0
        craneSlowdownDropsRemaining = 0
        activeToolMessage = nil
        lastPlacementFeedback = nil
        wind = windForHeight(0)
        nextPiece = makePiece(for: 0)
    }

    private func placementMetrics(
        for piece: YardPiece,
        centerOffset: CGFloat
    ) -> (
        quality: YardPlacementQuality,
        normalizedOffset: CGFloat,
        instability: CGFloat,
        lean: CGFloat,
        failed: Bool,
        reason: String,
        feedbackMessage: String
    ) {
        let previousCenter = blocks.last?.centerOffset ?? 0
        let previousWidth = blocks.last?.width ?? 164
        let offsetFromSupport = centerOffset - previousCenter
        let baseEarlyAssist = max(0, 1 - CGFloat(blocks.count) / 7)
        let activeFoundationAssist: CGFloat = foundationAssistDropsRemaining > 0 ? 0.22 : 0
        let dailyFoundationAssist = blocks.count < 4 ? (configuration.dailyModifier?.foundationAssist ?? 0) : 0
        let earlyAssist = min(1.25, baseEarlyAssist + activeFoundationAssist + dailyFoundationAssist)
        let supportSpan = max(42, min(previousWidth, piece.width) * (0.62 + earlyAssist * 0.12))
        let normalizedOffset = abs(offsetFromSupport) / supportSpan
        let perfectLimit = max(7, piece.width * (0.07 + earlyAssist * 0.02))
        let quality: YardPlacementQuality
        if abs(offsetFromSupport) <= perfectLimit {
            quality = .perfect
        } else if normalizedOffset <= 0.72 {
            quality = .good
        } else {
            quality = .risky
        }

        let block = YardPlacedPiece(
            width: piece.width,
            height: piece.height,
            weight: piece.weight,
            material: piece.material,
            kind: piece.kind,
            centerOffset: centerOffset,
            perfect: quality == .perfect,
            quality: quality
        )
        let projectedBlocks = blocks + [block]
        let totalWeight = projectedBlocks.reduce(CGFloat.zero) { $0 + $1.weight }
        let centerOfMass = projectedBlocks.reduce(CGFloat.zero) { partial, block in
            partial + block.centerOffset * block.weight
        } / max(0.1, totalWeight)

        let weightLoad = piece.weight / 1.72
        let heightLoad = 0.86 + CGFloat(projectedBlocks.count) * 0.055
        let windLoad = abs(wind) * (0.64 + CGFloat(projectedBlocks.count) * 0.055)
        let gripPenalty = (configuration.weather.gripPenalty + materialGripPenalty(for: piece.material)) * (1 - earlyAssist * 0.45)
        let placementStress = max(0, normalizedOffset - 0.24) * weightLoad * heightLoad
        let nextInstability = max(0, instability * 0.66 + placementStress + windLoad * 0.08 + gripPenalty)

        let baseWidth = max(96, blocks.first?.width ?? piece.width)
        let leanDirection: CGFloat
        if abs(offsetFromSupport) > 1 {
            leanDirection = offsetFromSupport > 0 ? 1 : -1
        } else {
            leanDirection = centerOfMass >= 0 ? 1 : -1
        }
        let nextLean = centerOfMass / (baseWidth * 0.72) + wind * 0.07 + nextInstability * 0.035 * leanDirection

        let failureGrace = 1 + earlyAssist * 0.22
        let noSupport = normalizedOffset > 1.42 + earlyAssist * 0.2
        let criticalLean = abs(nextLean) > 1.22 * failureGrace
        let criticalShake = nextInstability > 3.05 * failureGrace && abs(nextLean) > 0.82
        let failed = noSupport || criticalLean || criticalShake

        let reason: String
        if noSupport {
            reason = "The piece missed the block below."
        } else if criticalLean {
            reason = "The tower tipped because the stack leaned past the safe line."
        } else {
            reason = "The tower shook apart because stability ran out."
        }

        let feedbackMessage: String
        switch quality {
        case .perfect:
            feedbackMessage = "Centered on the stack"
        case .good:
            feedbackMessage = "Supported and stable"
        case .risky:
            feedbackMessage = noSupport ? "Barely any support" : "Watch the lean"
        }

        return (quality, normalizedOffset, nextInstability, nextLean, failed, reason, feedbackMessage)
    }

    private func scoreForPlacement(normalizedOffset: CGFloat, quality: YardPlacementQuality) -> Int {
        let placement = max(4, 24 - Int(normalizedOffset * 10))
        return placement + height * 2 + (quality == .perfect ? 18 : 0)
    }

    private func coinsForPlacement(normalizedOffset: CGFloat, quality: YardPlacementQuality) -> Int {
        if quality == .perfect {
            return 4 + (configuration.dailyModifier?.perfectPlacementCoinBonus ?? 0)
        }

        return quality == .good ? 2 : 1
    }

    private func windForHeight(_ height: Int) -> CGFloat {
        let heightFactor = min(1.08, 0.18 + CGFloat(height) * 0.052)
        let index = CGFloat(height + max(1, configuration.contractIndex))
        let waveA = sin(index * 0.72)
        let waveB = cos(CGFloat(height) * 0.37 + CGFloat(configuration.contractIndex) * 0.2) * 0.45
        let baseDirection: CGFloat = configuration.contractIndex % 2 == 0 ? -1 : 1
        let steadyPush = configuration.weather.windIntensity * 0.1 * baseDirection
        return (waveA + waveB) * heightFactor * configuration.weather.windIntensity + steadyPush
    }

    private func makePiece(for index: Int) -> YardPiece {
        let kind = kindForPiece(index: index)
        let material = materialForPiece(index: index, kind: kind)
        let widthOffsets: [CGFloat] = [0, -14, 10, -24, 18, -8, 6]
        let width = max(62, material.baseWidth + widthOffsets[(index + configuration.contractIndex) % widthOffsets.count])
        let height: CGFloat

        switch kind {
        case .beam:
            height = 22
        case .roof:
            height = 42
        case .window:
            height = 34
        case .decor:
            height = 28
        case .block:
            height = 36
        }

        return YardPiece(
            width: width,
            height: height,
            weight: material.weight,
            material: material,
            kind: kind
        )
    }

    private func materialForPiece(index: Int, kind: YardPieceKind) -> YardMaterial {
        switch kind {
        case .roof:
            return .roofTile
        case .decor:
            return .decor
        default:
            break
        }

        if configuration.material == .mixed {
            let materials: [YardMaterial] = [.timber, .brick, .steel, .glass, .composite]
            return materials[(index + configuration.contractIndex) % materials.count]
        }

        return configuration.material.primaryYardMaterial
    }

    private func kindForPiece(index: Int) -> YardPieceKind {
        if mode == .contracts, index == max(0, configuration.targetHeight - 1) {
            return .roof
        }

        let earlyBuildPattern: [YardPieceKind] = [.block, .block, .beam, .block, .window, .block]
        if index < earlyBuildPattern.count {
            return earlyBuildPattern[index]
        }

        switch (index + configuration.contractIndex) % 7 {
        case 0:
            return .beam
        case 2:
            return .window
        case 5:
            return .decor
        default:
            return .block
        }
    }

    private func materialGripPenalty(for material: YardMaterial) -> CGFloat {
        switch material {
        case .glass:
            0.05
        case .steel:
            configuration.weather == .rain || configuration.weather == .storm ? 0.04 : 0
        case .decor:
            -0.02
        default:
            0
        }
    }

    private func finish(_ finalPhase: YardRoundPhase, outcome: YardResultOutcome) {
        phase = finalPhase
        let result = makeResult(outcome: outcome)
        lastResult = result
        saveResult(result)
    }

    private func makeResult(outcome: YardResultOutcome) -> YardGameResult {
        let rating = YardBuildRating.evaluate(
            height: height,
            perfectBlocks: perfectBlocks,
            dangerLevel: tiltDangerLevel,
            helperToolUses: usedToolIDs.count,
            completed: outcome == .victory
        )

        return YardGameResult(
            id: UUID(),
            date: Date(),
            mode: mode,
            contractIndex: configuration.contractIndex,
            height: height,
            perfectBlocks: perfectBlocks,
            usedTools: usedTools,
            usedToolIDs: usedToolIDs,
            coins: coins,
            score: score,
            outcome: outcome,
            rating: rating
        )
    }

    private func registerToolUse(_ toolID: GameToolID, message: String) {
        usedToolIDs.append(toolID)
        activeToolMessage = message
    }

    private func levelLastBlock() {
        guard let lastIndex = blocks.indices.last else { return }

        let supportCenter = lastIndex > blocks.startIndex ? blocks[lastIndex - 1].centerOffset : 0
        let oldOffset = blocks[lastIndex].centerOffset
        blocks[lastIndex].centerOffset = supportCenter + (oldOffset - supportCenter) * 0.32
        if blocks[lastIndex].quality == .risky {
            blocks[lastIndex].quality = .good
            blocks[lastIndex].perfect = false
        }
        recalibrateTowerBalance()
    }

    private func recalibrateTowerBalance() {
        guard !blocks.isEmpty else {
            instability = 0
            lean = 0
            return
        }

        let totalWeight = blocks.reduce(CGFloat.zero) { $0 + $1.weight }
        let centerOfMass = blocks.reduce(CGFloat.zero) { partial, block in
            partial + block.centerOffset * block.weight
        } / max(0.1, totalWeight)
        let baseWidth = max(96, blocks.first?.width ?? 164)
        let correctedLean = centerOfMass / (baseWidth * 0.72) + wind * 0.045
        lean = min(1.2, max(-1.2, correctedLean))
        instability = min(3.05, max(0, instability * 0.54 + abs(lean) * 0.16))
    }

    private func consumeActiveToolCharges() {
        if foundationAssistDropsRemaining > 0 {
            foundationAssistDropsRemaining -= 1
        }

        if craneSlowdownDropsRemaining > 0 {
            craneSlowdownDropsRemaining -= 1
        }
    }

    private func unavailableToolMessage(for toolID: GameToolID) -> String {
        switch toolID {
        case .levelingHammer:
            return "Place a block before using the Leveling Hammer."
        case .safetyNet:
            return "A Safety Net is already armed."
        case .foundationBooster:
            return "Foundation Booster is only useful during the early build."
        case .craneSlowdown:
            return "Crane Slowdown is already active."
        }
    }

    private func recordZenSnapshotIfNeeded() {
        guard mode == .zen, !blocks.isEmpty, !phase.isTerminal else { return }
        let result = makeResult(outcome: .zenSnapshot)
        lastResult = result
        saveResult(result)
    }

    private func saveResult(_ result: YardGameResult) {
        var results = loadResults()
        results.insert(result, at: 0)
        results = Array(results.prefix(30))

        guard let data = try? JSONEncoder().encode(results) else { return }
        defaults.set(data, forKey: resultKey)
    }

    private func loadResults() -> [YardGameResult] {
        guard let data = defaults.data(forKey: resultKey),
              let results = try? JSONDecoder().decode([YardGameResult].self, from: data) else {
            return []
        }

        return results
    }
}

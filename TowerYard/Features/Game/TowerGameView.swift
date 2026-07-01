import SwiftUI
import UIKit

private enum GameSceneMetrics {
    static let foundationBottomPadding: CGFloat = 46
    static let foundationCapHeight: CGFloat = 26
    static let foundationFootHeight: CGFloat = 10
    static let towerBaseClearance = foundationBottomPadding + foundationCapHeight + foundationFootHeight
}

struct TowerGameView: View {
    @ObservedObject var game: YardGameStore
    var progressOutcome: RunOutcome?
    var canAdvanceContract: Bool
    var onResult: (YardGameResult) -> Void
    var onNextContract: () -> Void

    var body: some View {
        ZStack {
            GameBackdrop(wind: game.wind)

            VStack(spacing: 10) {
                topBar
                TowerPlayfield(game: game)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, AppShellMetrics.scrollContentBottomClearance)

            overlay
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: game.lastResult?.id) { _, _ in
            guard let result = game.lastResult else { return }
            onResult(result)
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            metric(title: "Height", value: "\(game.height)")
            metric(title: "Goal/Best", value: game.targetLabel)
            StabilityMeter(level: game.tiltDangerLevel)

            Spacer(minLength: 0)

            Button {
                game.togglePause()
            } label: {
                Image(systemName: game.phase == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(game.phase == .paused ? "Resume" : "Pause")

            Button {
                game.restartRound()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel("Restart")
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var overlay: some View {
        switch game.phase {
        case .paused:
            ResultOverlay(
                title: "Paused",
                message: "The crane is stopped.",
                game: game,
                progressOutcome: progressOutcome,
                primaryTitle: "Resume",
                primaryAction: { game.togglePause() },
                secondaryTitle: nil,
                secondaryAction: nil
            )
        case .won:
            ResultOverlay(
                title: "Contract Complete",
                message: "Height \(game.height) reached with \(game.perfectBlocks) perfect placements.",
                game: game,
                progressOutcome: progressOutcome,
                primaryTitle: canAdvanceContract ? "Next Contract" : "Restart",
                primaryAction: canAdvanceContract ? onNextContract : { game.restartRound() },
                secondaryTitle: "Restart",
                secondaryAction: { game.restartRound() }
            )
        case .lost(let reason):
            ResultOverlay(
                title: game.mode == .endless ? "Run Finished" : "Tower Failed",
                message: reason,
                game: game,
                progressOutcome: progressOutcome,
                primaryTitle: "Restart",
                primaryAction: { game.restartRound() },
                secondaryTitle: nil,
                secondaryAction: nil
            )
        case .playing:
            EmptyView()
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minWidth: 54, alignment: .leading)
    }
}

private struct StabilityMeter: View {
    var level: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Text("STABILITY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
                Text(status)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(riskColor(for: level))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.14))
                    Capsule()
                        .fill(riskColor(for: level))
                        .frame(width: proxy.size.width * max(0.08, 1 - min(1, level)))
                }
            }
            .frame(height: 7)
        }
        .frame(width: 104)
        .accessibilityLabel("Stability \(status)")
    }

    private var status: String {
        if level >= 0.72 {
            return "Danger"
        }
        if level >= 0.42 {
            return "Warning"
        }
        return "Stable"
    }
}

private struct TowerPlayfield: View {
    @ObservedObject var game: YardGameStore

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                let stageSize = proxy.size
                let craneOffset = game.craneOffset(stageWidth: stageSize.width, at: timeline.date)
                let towerScale = towerScale(for: stageSize.height)
                let safeLandingWidth = max(72, min(game.supportWidth, game.nextPiece.width) * 1.08)

                ZStack(alignment: .bottom) {
                    YardFloor(wind: game.wind)

                    TowerBuildZone(
                        supportCenterOffset: game.supportCenterOffset,
                        safeLandingWidth: safeLandingWidth,
                        towerScale: towerScale,
                        dangerLevel: game.tiltDangerLevel
                    )

                    DropLineGuide(
                        offset: craneOffset,
                        dangerLevel: game.tiltDangerLevel
                    )

                    CraneRig(
                        piece: game.nextPiece,
                        offset: craneOffset,
                        stageWidth: stageSize.width
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                    .opacity(game.phase == .playing ? 1 : 0.45)

                    FoundationView(dangerLevel: game.tiltDangerLevel)

                    TowerStackView(
                        blocks: game.blocks,
                        towerScale: towerScale,
                        rotation: game.towerRotation(at: timeline.date)
                    )

                    if let feedback = game.lastPlacementFeedback {
                        PlacementFeedbackToast(feedback: feedback)
                            .id(feedback.id)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding(.top, 76)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    game.placeCurrentBlockFromCrane(stageWidth: stageSize.width, at: timeline.date)
                }
                .animation(.spring(response: 0.24, dampingFraction: 0.82), value: game.lastPlacementFeedback?.id)
            }
        }
        .frame(minHeight: 420)
    }

    private func towerScale(for height: CGFloat) -> CGFloat {
        guard game.towerVisualHeight > 0 else { return 1 }

        let availableHeight = max(220, height - 150)
        return min(1, max(0.48, availableHeight / max(1, game.towerVisualHeight)))
    }
}

private struct TowerStackView: View {
    var blocks: [YardPlacedPiece]
    var towerScale: CGFloat
    var rotation: Double

    var body: some View {
        GeometryReader { proxy in
            let layers = towerLayers
            let towerHeight = max(1, layers.last?.top ?? 0)
            let stageWidth = proxy.size.width
            let stageHeight = proxy.size.height
            let buildHeight = max(1, stageHeight - GameSceneMetrics.towerBaseClearance)

            ZStack(alignment: .bottom) {
                ZStack(alignment: .topLeading) {
                    ForEach(layers) { layer in
                        let block = layer.block
                        PlacedPieceView(block: block)
                            .frame(width: block.width, height: block.height)
                            .position(
                                x: stageWidth / 2 + block.centerOffset,
                                y: towerHeight - layer.bottom - block.height / 2
                            )
                            .zIndex(Double(layer.order))
                    }
                }
                .frame(width: stageWidth, height: towerHeight, alignment: .bottom)
                .scaleEffect(towerScale, anchor: .bottom)
                .rotationEffect(.degrees(rotation), anchor: .bottom)
            }
            .frame(width: stageWidth, height: buildHeight, alignment: .bottom)
            .padding(.bottom, GameSceneMetrics.towerBaseClearance)
        }
        .allowsHitTesting(false)
    }

    private var towerLayers: [TowerLayer] {
        var bottom: CGFloat = 0
        return blocks.enumerated().map { index, block in
            let layer = TowerLayer(order: index, block: block, bottom: bottom)
            bottom += block.height
            return layer
        }
    }

    private struct TowerLayer: Identifiable {
        var order: Int
        var block: YardPlacedPiece
        var bottom: CGFloat

        var id: UUID { block.id }
        var top: CGFloat { bottom + block.height }
    }
}

private struct TowerBuildZone: View {
    var supportCenterOffset: CGFloat
    var safeLandingWidth: CGFloat
    var towerScale: CGFloat
    var dangerLevel: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let centerX = width / 2
            let foundationTop = height - GameSceneMetrics.towerBaseClearance
            let zoneTop = min(max(128, height * 0.24), foundationTop - 210)
            let zoneWidth = min(width - 52, 300)
            let supportX = centerX + supportCenterOffset * towerScale
            let supportWidth = min(zoneWidth * 0.92, safeLandingWidth * towerScale)

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: zoneTop + 8))
                    path.addLine(to: CGPoint(x: centerX, y: foundationTop - 8))
                }
                .stroke(
                    TowerYardTheme.constructionYellow.opacity(0.72),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 6])
                )

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(riskColor(for: dangerLevel).opacity(0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(riskColor(for: dangerLevel).opacity(0.66), lineWidth: 1)
                    }
                    .frame(width: max(60, supportWidth), height: 14)
                    .position(x: supportX, y: foundationTop - 18)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FoundationView: View {
    var dangerLevel: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.48, green: 0.49, blue: 0.45),
                            Color(red: 0.32, green: 0.34, blue: 0.32)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 184, height: 26)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(riskColor(for: dangerLevel).opacity(0.62), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.24), radius: 6, y: 4)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.21, green: 0.25, blue: 0.23))
                .frame(width: 228, height: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, GameSceneMetrics.foundationBottomPadding)
        .allowsHitTesting(false)
    }
}

private struct DropLineGuide: View {
    var offset: CGFloat
    var dangerLevel: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let x = proxy.size.width / 2 + offset
            let top: CGFloat = 104
            let bottom = proxy.size.height - GameSceneMetrics.towerBaseClearance - 2

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: x, y: top))
                    path.addLine(to: CGPoint(x: x, y: bottom))
                }
                .stroke(
                    Color.white.opacity(0.26),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 7])
                )

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(riskColor(for: dangerLevel).opacity(0.14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(riskColor(for: dangerLevel).opacity(0.46), lineWidth: 1)
                    }
                    .frame(width: 58, height: 10)
                    .position(x: x, y: bottom - 10)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CraneRig: View {
    var piece: YardPiece
    var offset: CGFloat
    var stageWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            CraneStructure(width: stageWidth)

            MovingCraneHead(piece: piece)
                .position(x: stageWidth / 2 + offset, y: 82)
        }
        .frame(width: stageWidth, height: 148, alignment: .topLeading)
    }
}

private struct MovingCraneHead: View {
    var piece: YardPiece

    var body: some View {
        let headWidth = max(160, piece.width + 30)
        let centerX = headWidth / 2
        let trolleyY: CGFloat = -51
        let pieceY: CGFloat = 30
        let hookY = pieceY - piece.height / 2 - 10
        let cableHeight = max(34, hookY - trolleyY - 12)

        ZStack {
            Rectangle()
                .fill(TowerYardTheme.deepSteel)
                .frame(width: 3, height: cableHeight)
                .position(x: centerX, y: trolleyY + 12 + cableHeight / 2)

            Path { path in
                path.move(to: CGPoint(x: centerX - 8, y: hookY))
                path.addLine(to: CGPoint(x: centerX, y: hookY + 10))
                path.addLine(to: CGPoint(x: centerX + 8, y: hookY))
            }
            .stroke(
                TowerYardTheme.deepSteel,
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(TowerYardTheme.constructionYellow)
                .frame(width: 42, height: 22)
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(.black.opacity(0.35), lineWidth: 1)
                }
                .overlay(alignment: .bottom) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(TowerYardTheme.deepSteel)
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(TowerYardTheme.deepSteel)
                            .frame(width: 6, height: 6)
                    }
                    .padding(.bottom, 3)
                }
                .position(x: centerX, y: trolleyY)

            PieceView(piece: piece)
                .frame(width: piece.width, height: piece.height)
                .shadow(color: .black.opacity(0.26), radius: 8, y: 5)
                .position(x: centerX, y: pieceY)
        }
        .frame(width: headWidth, height: 150)
        .drawingGroup()
    }
}

private struct CraneStructure: View {
    var width: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.88, green: 0.65, blue: 0.16))
                .frame(width: max(0, width - 36), height: 12)
                .position(x: width / 2, y: 26)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(TowerYardTheme.deepSteel.opacity(0.8))
                .frame(width: max(0, width - 48), height: 3)
                .position(x: width / 2, y: 34)
        }
        .frame(height: 54)
    }
}

private struct PlacedPieceView: View {
    var block: YardPlacedPiece

    var body: some View {
        PieceBody(
            material: block.material,
            kind: block.kind,
            quality: block.quality
        )
    }
}

private struct PieceView: View {
    var piece: YardPiece

    var body: some View {
        PieceBody(
            material: piece.material,
            kind: piece.kind,
            quality: nil
        )
    }
}

private struct PieceBody: View {
    var material: YardMaterial
    var kind: YardPieceKind
    var quality: YardPlacementQuality?

    var body: some View {
        ZStack {
            if let assetName {
                assetBackedBody(name: assetName)
            } else {
                fallbackBody
            }
        }
        .overlay {
            pieceOutline
        }
    }

    private var assetName: String? {
        nil
    }

    @ViewBuilder
    private func assetBackedBody(name: String) -> some View {
        if let image = UIImage(named: name) {
            assetTextureBody(image: image)
        } else {
            fallbackBody
        }
    }

    @ViewBuilder
    private func assetTextureBody(image: UIImage) -> some View {
        switch kind {
        case .roof:
            clippedAssetTexture(image: image, shape: RoofPieceShape())
        default:
            clippedAssetTexture(image: image, shape: RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
    }

    private func clippedAssetTexture<S: Shape>(image: UIImage, shape: S) -> some View {
        ZStack {
            shape
                .fill(material.tint.opacity(assetUnderlayOpacity))

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(shape)
    }

    private var assetUnderlayOpacity: Double {
        switch kind {
        case .window:
            0.16
        case .roof:
            0.24
        default:
            0.28
        }
    }

    @ViewBuilder
    private var fallbackBody: some View {
        switch kind {
        case .roof:
            roofBody
        case .beam:
            beamBody
        case .window:
            windowBody
        case .decor:
            decorBody
        case .block:
            blockBody
        }
    }

    private var blockBody: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(material.tint.gradient)
            .overlay {
                BrickLineShape()
                    .stroke(.black.opacity(0.22), lineWidth: 1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 6)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.black.opacity(0.22))
                    .frame(height: 5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var beamBody: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(material.tint.gradient)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.26))
                    .frame(height: 4)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.black.opacity(0.26))
                    .frame(height: 4)
            }
            .overlay {
                BeamBraceShape()
                    .stroke(.black.opacity(0.32), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .overlay {
                HStack {
                    Rectangle()
                        .fill(.black.opacity(0.16))
                        .frame(width: 4)
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(.black.opacity(0.16))
                        .frame(width: 4)
                }
                .padding(.vertical, 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }

    private var windowBody: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(material.tint.gradient)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(height: 5)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.black.opacity(0.28))
                    .frame(height: 5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(.black.opacity(0.22))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 7)
            }
            .overlay {
                HStack(spacing: 5) {
                    PaneView()
                    PaneView()
                    PaneView()
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var decorBody: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(material.tint.gradient)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.white.opacity(0.24))
                    .frame(height: 4)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.black.opacity(0.24))
                    .frame(height: 4)
            }
            .overlay {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(.black.opacity(0.2))
                            .frame(width: 7)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private var roofBody: some View {
        RoofPieceShape()
            .fill(material.tint.gradient)
            .overlay {
                RoofTileShape()
                    .stroke(.black.opacity(0.24), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .padding(.horizontal, 7)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 2)
                    Rectangle()
                        .fill(.black.opacity(0.22))
                        .frame(height: 8)
                }
            }
            .clipShape(RoofPieceShape())
    }

    @ViewBuilder
    private var pieceOutline: some View {
        let color = outlineColor
        let width: CGFloat = quality == nil ? 1.5 : 1

        switch kind {
        case .roof:
            RoofPieceShape()
                .stroke(color, lineWidth: width)
        default:
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(color, lineWidth: width)
        }
    }

    private var outlineColor: Color {
        switch quality {
        case .perfect:
            Color.white.opacity(0.28)
        case .good:
            Color.black.opacity(0.2)
        case .risky:
            TowerYardTheme.constructionYellow.opacity(0.46)
        case nil:
            Color.white.opacity(0.42)
        }
    }
}

private struct PaneView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.74, green: 0.9, blue: 0.96),
                        Color(red: 0.28, green: 0.52, blue: 0.68)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                Rectangle()
                    .fill(.white.opacity(0.34))
                    .frame(width: 3)
                    .padding(.vertical, 3)
                    .padding(.leading, 3)
            }
    }
}

private struct AssetImage<Fallback: View>: View {
    var name: String
    @ViewBuilder var fallback: () -> Fallback

    var body: some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.medium)
        } else {
            fallback()
        }
    }
}

private struct BrickLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = 3

        for index in 1..<rows {
            let y = rect.minY + rect.height * CGFloat(index) / CGFloat(rows)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height / 3))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height / 3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 2 / 3))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height / 3))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 2 / 3))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2 / 3))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct BeamBraceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let segment = max(28, rect.width / 4)
        var x = rect.minX

        while x < rect.maxX {
            let nextX = min(x + segment, rect.maxX)
            path.move(to: CGPoint(x: x, y: rect.maxY - 5))
            path.addLine(to: CGPoint(x: nextX, y: rect.minY + 5))
            path.move(to: CGPoint(x: x, y: rect.minY + 5))
            path.addLine(to: CGPoint(x: nextX, y: rect.maxY - 5))
            x += segment
        }

        return path
    }
}

private struct GlassShineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.46, y: rect.minY))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.54, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY))
        return path
    }
}

private struct RoofTileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corniceHeight = min(9, rect.height * 0.24)
        let roofBottom = rect.maxY - corniceHeight
        let roofHeight = max(1, roofBottom - rect.minY)
        let rows = 3

        for index in 1...rows {
            let progress = CGFloat(index) / CGFloat(rows + 1)
            let y = rect.minY + roofHeight * progress
            let inset = rect.width * max(0.06, 0.42 * (1 - progress))
            path.move(to: CGPoint(x: rect.minX + inset, y: y))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: y))
        }

        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 3))
        path.addLine(to: CGPoint(x: rect.midX, y: roofBottom - 1))
        return path
    }
}

private struct RoofPieceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corniceHeight = min(9, rect.height * 0.24)
        let roofBottom = rect.maxY - corniceHeight
        let ridgeHalfWidth = min(rect.width * 0.18, 26)
        let shoulderInset = min(rect.width * 0.08, 8)

        path.move(to: CGPoint(x: rect.midX - ridgeHalfWidth, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX + ridgeHalfWidth, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.maxX - shoulderInset, y: roofBottom))
        path.addLine(to: CGPoint(x: rect.maxX, y: roofBottom))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: roofBottom))
        path.addLine(to: CGPoint(x: rect.minX + shoulderInset, y: roofBottom))
        path.closeSubpath()
        return path
    }
}

private struct YardFloor: View {
    var wind: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.72, blue: 0.82),
                Color(red: 0.76, green: 0.82, blue: 0.8),
                Color(red: 0.48, green: 0.52, blue: 0.44)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .frame(width: 64 + CGFloat(index) * 28, height: 7)
                }
            }
            .offset(x: wind * 10, y: 72)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.36, green: 0.43, blue: 0.34),
                            Color(red: 0.25, green: 0.3, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 92)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.53, green: 0.62, blue: 0.42))
                        .frame(height: 7)
                }
        }
    }
}

private struct PlacementFeedbackToast: View {
    var feedback: YardPlacementFeedback

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.black))

            VStack(alignment: .leading, spacing: 1) {
                Text(feedback.quality.title)
                    .font(.caption.weight(.black))
                Text(feedback.message)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.54), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
    }

    private var iconName: String {
        switch feedback.quality {
        case .perfect:
            "checkmark.circle.fill"
        case .good:
            "checkmark.circle"
        case .risky:
            "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch feedback.quality {
        case .perfect:
            Color(red: 0.9, green: 1, blue: 0.62)
        case .good:
            .green
        case .risky:
            TowerYardTheme.constructionYellow
        }
    }
}

private func riskColor(for dangerLevel: CGFloat) -> Color {
    if dangerLevel >= 0.72 {
        return TowerYardTheme.brick
    }
    if dangerLevel >= 0.42 {
        return TowerYardTheme.constructionYellow
    }
    return .green
}

private struct ResultOverlay: View {
    var title: String
    var message: String
    @ObservedObject var game: YardGameStore
    var progressOutcome: RunOutcome?
    var primaryTitle: String
    var primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(progressOutcome?.message ?? message)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    resultStat("Height", "\(game.height)")
                    resultStat("Perfect", "\(game.perfectBlocks)")
                    resultStat("Coins", "\(game.coins)")
                }

                Text("Used: \(game.usedTools.joined(separator: ", "))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    Button(action: primaryAction) {
                        Label(primaryTitle, systemImage: primaryIcon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let secondaryTitle, let secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryTitle)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(20)
            .frame(maxWidth: 390)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(.horizontal, 24)
        }
    }

    private var primaryIcon: String {
        if primaryTitle == "Next Contract" {
            "arrow.right.circle.fill"
        } else if primaryTitle == "Resume" {
            "play.fill"
        } else {
            "arrow.clockwise"
        }
    }

    private func resultStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 21, weight: .black, design: .rounded))
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GameBackdrop: View {
    var wind: CGFloat

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.13, blue: 0.2),
                Color(red: 0.11, green: 0.25, blue: 0.34),
                Color(red: 0.23, green: 0.32, blue: 0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            GeometryReader { proxy in
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .frame(width: 64 + CGFloat(index % 3) * 24, height: 2)
                        .offset(
                            x: CGFloat(index * 47).truncatingRemainder(dividingBy: max(1, proxy.size.width)) + wind * 20,
                            y: 70 + CGFloat(index) * 58
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    TowerGameView(
        game: YardGameStore(configuration: .session(.contract(ContractCatalog.all[0]))),
        progressOutcome: nil,
        canAdvanceContract: true,
        onResult: { _ in },
        onNextContract: {}
    )
}

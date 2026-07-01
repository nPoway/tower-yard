import SwiftUI

struct MetricChip: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.indigo, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct DetailPill: View {
    let title: String
    let systemImage: String
    var color: Color = .teal

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct RewardPill: View {
    let reward: Int

    var body: some View {
        Label("\(reward)", systemImage: "banknote.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(.orange)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.orange.opacity(0.14), in: Capsule())
            .accessibilityLabel("\(reward) coins")
    }
}

struct BlueprintSilhouetteView: View {
    let widths: [Int]
    var highlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(widths.enumerated()).reversed(), id: \.offset) { _, width in
                RoundedRectangle(cornerRadius: 3)
                    .fill(highlighted ? Color.cyan.gradient : Color.blueGray.gradient)
                    .frame(width: CGFloat(width) * 18, height: 13)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension Color {
    static var blueGray: Color {
        Color(red: 0.33, green: 0.43, blue: 0.55)
    }
}

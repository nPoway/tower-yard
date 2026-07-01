//
//  ForemanChatView.swift
//  TowerYard
//
//  Created by Codex on 30.06.2026.
//

import SwiftUI

struct ForemanChatView: View {
    @State private var messages: [ForemanChatMessage] = [
        ForemanChatMessage(
            role: .foreman,
            text: "Builder Assistant ready. Ask about foundation, wind, beams, contracts, tools, or balance and I will help plan the next move.",
            topic: nil,
            status: "Build tip"
        )
    ]
    @State private var draftText = ""
    @State private var selectedTopic: ForemanAdviceTopic?
    @State private var nextAdviceOffsetByTopic: [ForemanAdviceTopic: Int] = [:]
    @State private var generalAdviceOffset = 0
    @State private var isTyping = false

    private let service = ForemanAdviceService()
    private let bottomAnchorID = "foreman-chat-bottom"

    var body: some View {
        ZStack {
            BlueprintGridBackground()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForemanChatHeader()
                            .padding(.bottom, 4)

                        ForEach(messages) { message in
                            ForemanChatMessageRow(message: message)
                                .id(message.id)
                        }

                        if isTyping {
                            ForemanTypingRow()
                                .id("foreman-typing")
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchorID)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
                .appShellScrollContentBottomClearance()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ForemanChatComposerBar(
                        text: $draftText,
                        selectedTopic: selectedTopic,
                        isDisabled: isTyping,
                        onPrompt: sendPrompt,
                        onSend: sendDraft
                    )
                    .padding(.bottom, AppShellMetrics.tabBarHeight)
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(with: proxy)
                }
                .onChange(of: isTyping) { _, _ in
                    scrollToBottom(with: proxy)
                }
            }
        }
        .background(TowerYardTheme.deepSteel)
        .navigationTitle("Builder Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendPrompt(_ prompt: ForemanQuickPrompt) {
        send(text: prompt.question, preferredTopic: prompt.topic)
    }

    private func sendDraft() {
        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isTyping else { return }

        draftText = ""
        send(text: trimmedText)
    }

    private func send(text: String, preferredTopic: ForemanAdviceTopic? = nil) {
        guard !isTyping else { return }

        let matchedTopic = preferredTopic ?? service.topic(for: text)
        let advice: ForemanAdvice

        if let matchedTopic {
            let offset = nextAdviceOffsetByTopic[matchedTopic, default: 0]
            advice = service.message(for: matchedTopic, offset: offset)
            nextAdviceOffsetByTopic[matchedTopic] = offset + 1
            selectedTopic = matchedTopic
        } else {
            advice = service.generalAdvice(offset: generalAdviceOffset)
            generalAdviceOffset += 1
            selectedTopic = advice.topic
        }

        withAnimation(.snappy(duration: 0.18)) {
            messages.append(
                ForemanChatMessage(
                    role: .player,
                    text: text,
                    topic: matchedTopic,
                    status: "Sent"
                )
            )
            isTyping = true
        }

        let responseDelay = 0.45 + min(Double(advice.message.count) * 0.005, 0.55)
        DispatchQueue.main.asyncAfter(deadline: .now() + responseDelay) {
            withAnimation(.snappy(duration: 0.22)) {
                isTyping = false
                messages.append(
                    ForemanChatMessage(
                        role: .foreman,
                        text: advice.message,
                        topic: advice.topic,
                        status: "Build tip"
                    )
                )
            }
        }
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        }
    }
}

private struct ForemanChatHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(TowerYardTheme.warningStripe)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TowerYardTheme.constructionYellow)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Yard Foreman")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(TowerYardTheme.textPrimary)

                    Text("Smart suggestions for foundations, wind, tools, contracts, and balance.")
                        .font(.subheadline)
                        .foregroundStyle(TowerYardTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForemanChatBadge(text: "Build strategy", systemImage: "lightbulb.fill")
                ForemanChatBadge(text: "Smart suggestions", systemImage: "sparkles")
            }
        }
        .yardPanel(stroke: TowerYardTheme.constructionYellow.opacity(0.45))
    }
}

private struct ForemanChatBadge: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(TowerYardTheme.constructionYellow)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(TowerYardTheme.deepSteel.opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
            )
    }
}

private struct ForemanChatComposerBar: View {
    @Binding var text: String

    let selectedTopic: ForemanAdviceTopic?
    let isDisabled: Bool
    let onPrompt: (ForemanQuickPrompt) -> Void
    let onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Quick questions")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TowerYardTheme.textSecondary)
                    .textCase(.uppercase)

                Spacer(minLength: 0)

                Label("Smart suggestions", systemImage: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(TowerYardTheme.constructionYellow)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ForemanQuickPrompt.all) { prompt in
                        Button {
                            onPrompt(prompt)
                        } label: {
                            Label(prompt.title, systemImage: prompt.topic.systemImage)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(
                            ForemanTopicChipStyle(
                                isSelected: selectedTopic == prompt.topic,
                                isDisabled: isDisabled
                            )
                        )
                        .disabled(isDisabled)
                    }
                }
                .padding(.horizontal, 16)
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask about wind, balance, tools...", text: $text, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .lineLimit(1...3)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(TowerYardTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(TowerYardTheme.steel.opacity(0.86))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(TowerYardTheme.panelStroke, lineWidth: 1)
                    )
                    .disabled(isDisabled)
                    .onSubmit(onSend)

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(canSend ? TowerYardTheme.constructionYellow : TowerYardTheme.textSecondary.opacity(0.55))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .background(TowerYardTheme.deepSteel.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TowerYardTheme.panelStroke)
                .frame(height: 1)
        }
    }
}

private struct ForemanTopicChipStyle: ButtonStyle {
    let isSelected: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? TowerYardTheme.warningStripe : TowerYardTheme.textPrimary)
            .background(
                Capsule()
                    .fill(isSelected ? TowerYardTheme.constructionYellow : TowerYardTheme.steel.opacity(0.88))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : TowerYardTheme.constructionYellow.opacity(0.22),
                        lineWidth: 1
                    )
            )
            .opacity(configuration.isPressed ? 0.72 : (isDisabled ? 0.62 : 1))
    }
}

private struct ForemanChatMessageRow: View {
    let message: ForemanChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .player {
                Spacer(minLength: 42)
            } else {
                ForemanAvatarView()
            }

            VStack(alignment: message.role == .player ? .trailing : .leading, spacing: 5) {
                Text(message.role == .player ? "You" : "Yard Foreman")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(message.role == .player ? TowerYardTheme.textSecondary : TowerYardTheme.constructionYellow)

                Text(message.text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(message.role == .player ? TowerYardTheme.warningStripe : TowerYardTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(bubbleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(bubbleStroke, lineWidth: 1)
                    )

                HStack(spacing: 6) {
                    if let topic = message.topic, message.role == .foreman {
                        Label(topic.rawValue, systemImage: topic.systemImage)
                    } else if let status = message.status {
                        Text(status)
                    }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(TowerYardTheme.textSecondary)
            }
            .frame(maxWidth: 310, alignment: message.role == .player ? .trailing : .leading)

            if message.role == .foreman {
                Spacer(minLength: 42)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .player ? .trailing : .leading)
    }

    private var bubbleFill: Color {
        switch message.role {
        case .foreman:
            TowerYardTheme.panel
        case .player:
            TowerYardTheme.constructionYellow
        }
    }

    private var bubbleStroke: Color {
        switch message.role {
        case .foreman:
            TowerYardTheme.beamBlue.opacity(0.35)
        case .player:
            TowerYardTheme.constructionYellow.opacity(0.65)
        }
    }
}

private struct ForemanAvatarView: View {
    var body: some View {
        Image(systemName: "hammer.fill")
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(TowerYardTheme.warningStripe)
            .frame(width: 32, height: 32)
            .background(Circle().fill(TowerYardTheme.constructionYellow))
            .overlay(Circle().stroke(TowerYardTheme.panelStroke, lineWidth: 1))
    }
}

private struct ForemanTypingRow: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForemanAvatarView()

            VStack(alignment: .leading, spacing: 7) {
                Text("Yard Foreman")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TowerYardTheme.constructionYellow)

                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(TowerYardTheme.constructionYellow.opacity(0.95 - Double(index) * 0.2))
                            .frame(width: 7, height: 7)
                    }

                    Text("thinking through the build")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TowerYardTheme.textSecondary)
                        .padding(.leading, 3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(TowerYardTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(TowerYardTheme.beamBlue.opacity(0.35), lineWidth: 1)
                )
            }

            Spacer(minLength: 42)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ForemanQuickPrompt: Identifiable, Hashable {
    let id: String
    let title: String
    let question: String
    let topic: ForemanAdviceTopic

    static let all: [ForemanQuickPrompt] = [
        ForemanQuickPrompt(id: "foundation", title: "Foundation", question: "How should I start the foundation?", topic: .foundation),
        ForemanQuickPrompt(id: "wind", title: "Wind plan", question: "What should I do when wind picks up?", topic: .wind),
        ForemanQuickPrompt(id: "roof", title: "Roof cap", question: "When should I cap the roof?", topic: .roofCap),
        ForemanQuickPrompt(id: "windows", title: "Windows", question: "When do windows go in?", topic: .windows),
        ForemanQuickPrompt(id: "beams", title: "Beams", question: "How should I place beams?", topic: .beams),
        ForemanQuickPrompt(id: "stability", title: "Wobble fix", question: "The tower is wobbling. What now?", topic: .stability),
        ForemanQuickPrompt(id: "contracts", title: "Contracts", question: "How do I finish a contract cleanly?", topic: .contracts),
        ForemanQuickPrompt(id: "endless", title: "Endless", question: "What is the Endless Tower opening?", topic: .endlessMode),
        ForemanQuickPrompt(id: "tools", title: "Tools", question: "When should I spend a tool?", topic: .tools),
        ForemanQuickPrompt(id: "balance", title: "Balance", question: "How do I keep the stack balanced?", topic: .balance)
    ]
}

private struct ForemanChatMessage: Identifiable, Hashable {
    let id = UUID()
    let role: ForemanChatRole
    let text: String
    let topic: ForemanAdviceTopic?
    let status: String?
}

private enum ForemanChatRole: Hashable {
    case foreman
    case player
}

#Preview {
    NavigationStack {
        ForemanChatView()
    }
}

import SwiftUI

struct AIReviewView: View {
    @ObservedObject var vm: ContractViewModel
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    let quickActions = [
        "📝 Summarize this contract",
        "🔍 Explain each clause",
        "⚠️ Flag any risks",
        "💡 Plain English version",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Quick action chips
            chipRow
            Divider()
            // Message list
            messageList
            Divider()
            // Input bar
            inputBar
        }
    }

    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(quickActions, id: \.self) { chip in
                    Button {
                        Task { await vm.sendAIMessage(chip) }
                    } label: {
                        Text(chip)
                            .font(.system(size: 11.5, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundColor(Color(.secondaryLabel))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(.separator), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSampling)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if vm.chatMessages.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.chatMessages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(12)
                }
            }
            .onChange(of: vm.chatMessages.count) { _ in
                if let last = vm.chatMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: vm.chatMessages.last?.text) { _ in
                if let last = vm.chatMessages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("✨")
                .font(.system(size: 42))
            Text("AI Contract Review")
                .font(.system(size: 14, weight: .semibold))
            Text("Ask anything about this \(vm.activeType.label.lowercased()) contract, or tap a quick action above.")
                .font(.system(size: 12.5))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask about this contract…", text: $inputText)
                .font(.system(size: 12.5))
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(inputFocused ? Color.accentColor : Color(.separator), lineWidth: 1.5))
                .focused($inputFocused)
                .disabled(vm.isSampling)
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                ZStack {
                    Circle()
                        .fill(vm.isSampling || inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color(.systemGray4) : Color.accentColor)
                        .frame(width: 34, height: 34)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(vm.isSampling || inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(.systemBackground))
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await vm.sendAIMessage(text) }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                if message.role == .assistant && message.text.isEmpty {
                    // Typing indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color(.tertiaryLabel))
                                .frame(width: 5, height: 5)
                                .modifier(TypingAnimation(delay: Double(i) * 0.2))
                        }
                    }
                    .padding(.horizontal, 13).padding(.vertical, 9)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(BubbleShape(isUser: false))
                    .overlay(BubbleShape(isUser: false).stroke(Color(.separator), lineWidth: 0.5))
                } else {
                    Text(markdownText)
                        .font(.system(size: 12.5))
                        .lineSpacing(3)
                        .foregroundColor(message.role == .user ? .white : Color(.label))
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(message.role == .user ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .clipShape(BubbleShape(isUser: message.role == .user))
                        .overlay(message.role == .assistant ? BubbleShape(isUser: false).stroke(Color(.separator), lineWidth: 0.5) : nil)
                }
            }
            if message.role == .assistant { Spacer(minLength: 48) }
        }
    }

    var markdownText: AttributedString {
        (try? AttributedString(markdown: message.text)) ?? AttributedString(message.text)
    }
}

struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        let tr: CGFloat = isUser ? 4 : r
        let tl: CGFloat = isUser ? r : 4
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct TypingAnimation: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0.2
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever().delay(delay)) {
                    opacity = 1
                }
            }
    }
}

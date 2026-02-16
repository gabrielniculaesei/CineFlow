import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [OllamaService.ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CineBot")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Your movie assistant")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(10)
                            .background(AppTheme.cardBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppTheme.cardBackground.opacity(0.5))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                welcomeView
                            }
                            
                            ForEach(messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                typingIndicator
                                    .id("typing")
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { _, _ in
                        withAnimation {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
                
                // Input bar
                inputBar
            }
        }
    }
    
    // MARK: - Welcome
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.accent.opacity(0.6))
            
            Text("Ask me anything about movies")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: 10) {
                suggestionButton("Suggest a thriller for tonight")
                suggestionButton("What's a good movie like Inception?")
                suggestionButton("Best movies of 2024")
                suggestionButton("Something light for a date night")
            }
        }
    }
    
    private func suggestionButton(_ text: String) -> some View {
        Button {
            sendMessage(text)
        } label: {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(14)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Message Bubble
    private func messageBubble(_ message: OllamaService.ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 50) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.accent)
                        Text("CineBot")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                    }
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .black : AppTheme.textPrimary)
                    .padding(14)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(AppTheme.goldGradient)
                            : AnyShapeStyle(AppTheme.cardBackground)
                    )
                    .cornerRadius(18)
                    .cornerRadius(18)
            }
            
            if message.role == .assistant { Spacer(minLength: 50) }
        }
    }
    
    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.textTertiary)
                        .frame(width: 7, height: 7)
                        .opacity(0.6)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isLoading
                        )
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(18)
            
            Spacer()
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about movies...", text: $inputText)
                .font(.body)
                .foregroundColor(AppTheme.textPrimary)
                .focused($isInputFocused)
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                        sendMessage(inputText)
                    }
                }
            
            Button {
                if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                    sendMessage(inputText)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AppTheme.textTertiary
                            : AppTheme.accent
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Send Message
    private func sendMessage(_ text: String) {
        let userText = text.trimmingCharacters(in: .whitespaces)
        guard !userText.isEmpty else { return }
        
        let userMessage = OllamaService.ChatMessage(role: .user, content: userText)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await OllamaService.shared.sendMessage(
                    userMessage: userText,
                    history: Array(messages.dropLast())
                )
                await MainActor.run {
                    let botMessage = OllamaService.ChatMessage(role: .assistant, content: response)
                    messages.append(botMessage)
                    isLoading = false
                }
            } catch let error as OllamaError {
                await MainActor.run {
                    let errorText: String
                    switch error {
                    case .serviceUnavailable:
                        errorText = "Can't reach Ollama - make sure it's running on your Mac (http://localhost:11434)."
                    case .modelNotFound:
                        errorText = "The model '\(APIConfig.ollamaModel)' wasn't found. Run 'ollama pull \(APIConfig.ollamaModel)' in Terminal first."
                    default:
                        errorText = "Something went wrong: \(error.localizedDescription). Please try again."
                    }
                    messages.append(OllamaService.ChatMessage(role: .assistant, content: errorText))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorText = "Connection error - make sure Ollama is running locally and try again."
                    messages.append(OllamaService.ChatMessage(role: .assistant, content: errorText))
                    isLoading = false
                }
            }
        }
    }
}

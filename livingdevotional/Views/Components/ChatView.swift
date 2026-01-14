// ChatView - Bible Conversation Interface

import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @ObservedObject var settingsStore: SettingsStore
    let onClose: () -> Void
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(settingsStore.appLanguage == .chineseTraditional ? "聖經助手" : "Bible Assistant")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding()
            .background(AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode))
            
            Divider()
            
            // Chat Content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Disclaimer / Welcome
                        if viewModel.session?.messages.isEmpty ?? true {
                            welcomeView
                        }
                        
                        // Messages
                        if let messages = viewModel.session?.messages {
                            ForEach(messages) { message in
                                ChatMessageView(message: message, settingsStore: settingsStore)
                                    .id(message.id)
                            }
                        }
                        
                        // Loading Indicator
                        if viewModel.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "正在思考..." : "Thinking...")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.leading)
                        }
                        
                        // Spacer for bottom
                        Color.clear.frame(height: 10)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.session?.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isGenerating) { isGen in
                    if isGen {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Suggested Questions (if empty or just started)
            if (viewModel.session?.messages.isEmpty ?? true) && !viewModel.suggestedQuestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                            Button {
                                Task {
                                    await viewModel.sendMessage(question)
                                }
                            } label: {
                                Text(question)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .stroke(AppTheme.accentColor, lineWidth: 1)
                                            .background(AppTheme.accentColor.opacity(0.05))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                Divider()
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField(settingsStore.appLanguage == .chineseTraditional ? "詢問關於這節經文的問題..." : "Ask a question about this verse...", text: $viewModel.inputMessage)
                    .font(.system(size: 16))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(settingsStore.isDarkMode ? Color.black.opacity(0.3) : Color.gray.opacity(0.1))
                    )
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !viewModel.inputMessage.isEmpty {
                            let msg = viewModel.inputMessage
                            Task {
                                await viewModel.sendMessage(msg)
                            }
                        }
                    }
                
                Button {
                    if !viewModel.inputMessage.isEmpty {
                        let msg = viewModel.inputMessage
                        Task {
                            await viewModel.sendMessage(msg)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.inputMessage.isEmpty ? AppTheme.secondaryText : AppTheme.accentColor)
                }
                .disabled(viewModel.inputMessage.isEmpty || viewModel.isGenerating)
            }
            .padding()
            .background(AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode))
        }
        .background(AppTheme.backgroundGradient(darkMode: settingsStore.isDarkMode))
        .onAppear {
            Task {
                await viewModel.loadSuggestions()
            }
        }
    }
    
    var welcomeView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
                .padding(.bottom, 8)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "有什麼我可以幫你的嗎？" : "How can I help you?")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "我可以解釋這節經文，或回答您的任何疑問。" : "I can explain this verse or answer any questions you have.")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    @ObservedObject var settingsStore: SettingsStore
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppTheme.accentColor.opacity(0.1)))
            } else {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(message.role == .user ? .white : AppTheme.primaryText)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ? AppTheme.accentColor : (settingsStore.isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)))
                    )
                
                if let date = message.createdAt {
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, 4)
                }
            }
            
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(width: 24, height: 24)
            } else {
                Spacer()
            }
        }
    }
}

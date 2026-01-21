// ChatView - Bible Conversation Interface

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var settingsStore: SettingsStore
    let onClose: () -> Void
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(settingsStore.appLanguage == .chineseTraditional ? "Q&A" : "Q&A")
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
            .background(AppTheme.backgroundGradient)
            
            Divider()
            
            // Pinned verse reference at top (always visible when verse context exists)
            if viewModel.hasVerseContext {
                verseReferenceView
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal)
            }
            
            // Chat Content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Welcome view only for new sessions
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
            
            // Suggested Questions (if empty or just started) - stacked vertically
            if (viewModel.session?.messages.isEmpty ?? true) && !viewModel.suggestedQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        Button {
                            Task {
                                await viewModel.sendMessage(question)
                            }
                        } label: {
                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentColor)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.accentColor.opacity(0.4), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppTheme.accentColor.opacity(0.05))
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                Divider()
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField(
                    viewModel.book != nil ? 
                        (settingsStore.appLanguage == .chineseTraditional ? "詢問關於這節經文的問題..." : "Ask a question about this verse...") :
                        (settingsStore.appLanguage == .chineseTraditional ? "詢問關於聖經或屬靈成長的問題..." : "Ask a question about the Bible or spiritual growth..."),
                    text: $viewModel.inputMessage
                )
                    .font(.system(size: 16))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.1))
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
            .background(AppTheme.backgroundGradient)
        }
        .background(AppTheme.backgroundGradient)
        .onAppear {
            Task {
                // Load verse text first if needed (for Ask questions with verse context)
                await viewModel.loadVerseTextIfNeeded(primaryLanguage: settingsStore.primaryLanguage)
                await viewModel.loadSuggestions()
                await viewModel.sendInitialQuestionIfNeeded()
            }
        }
    }
    
    var verseReferenceView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let book = viewModel.book, let chapter = viewModel.chapter, let verse = viewModel.verse {
                // Reference header with book icon
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor)
                    
                    let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                    Text("\(localizedBook) \(chapter):\(verse)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor)
                    
                    Spacer()
                }
                
                // Verse text
                if let verseText = viewModel.verseText, !verseText.isEmpty {
                    Text(verseText)
                        .font(.callout)
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(3)
                        .lineLimit(4) // Limit lines to keep it compact
                } else {
                    // Show loading indicator while verse text is being loaded
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "載入經文..." : "Loading verse...")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.accentColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    var welcomeView: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "questionmark.bubble")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.accentColor)
                .padding(.bottom, 8)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "開始問答" : "Start Q&A")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "詢問關於這節經文的問題，或繼續之前的對話。" : "Ask questions about this verse or continue a previous conversation.")
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
                            .fill(message.role == .user ? AppTheme.accentColor : Color.gray.opacity(0.1))
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

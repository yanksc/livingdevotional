// ChapterInfoView - Display chapter context or summary

import SwiftUI

struct ChapterInfoView: View {
    let book: String
    let chapter: Int
    let mode: ChapterInfoMode
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    var onDismiss: (() -> Void)?
    
    @StateObject private var cacheStore = AICacheStore.shared
    @State private var content: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showChatSheet: Bool = false
    @State private var showAskButton: Bool = false
    
    enum ChapterInfoMode {
        case context
        case summary
        
        var cacheKey: String {
            switch self {
            case .context:
                return "context"
            case .summary:
                return "summary"
            }
        }
    }
    
    var modeTitle: String {
        switch mode {
        case .context:
            return settingsStore.appLanguage == .chineseTraditional ? "章節背景" : "Chapter Context"
        case .summary:
            return settingsStore.appLanguage == .chineseTraditional ? "章節摘要" : "Chapter Summary"
        }
    }
    
    var modeIcon: String {
        switch mode {
        case .context:
            return "book.closed.fill"
        case .summary:
            return "doc.text.fill"
        }
    }
    
    var body: some View {
        ZStack {
            SereneGradientBackground()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: modeIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                        Text(modeTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Content area
                        if let error = errorMessage {
                            // Error state
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                Button(settingsStore.appLanguage == .chineseTraditional ? "重試" : "Retry") {
                                    errorMessage = nil
                                    loadContent()
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.accentColor)
                            }
                            .padding(.horizontal, 20)
                        } else if isLoading && content.isEmpty {
                            // Loading state
                            HStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(0.9)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "載入中..." : "Loading...")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        } else if !content.isEmpty {
                            // Content - selectable text
                            Text(content)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(6)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            // Ask button - appears with fade-in animation after content loads
                            if showAskButton {
                                Button {
                                    showChatSheet = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bubble.left.and.bubble.right.fill")
                                            .font(.system(size: 14, weight: .medium))
                                        Text(settingsStore.appLanguage == .chineseTraditional ? "詢問更多" : "Ask More")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.accentColor)
                                    )
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 16)
                                .padding(.bottom, 40)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            } else {
                                // Placeholder to reserve space while button fades in
                                Color.clear
                                    .frame(height: 80)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .sheet(isPresented: $showChatSheet) {
            if let aiService = services.aiService {
                let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                let modeDescription = mode == .context ? 
                    (settingsStore.appLanguage == .chineseTraditional ? "背景" : "context") :
                    (settingsStore.appLanguage == .chineseTraditional ? "摘要" : "summary")
                
                // Create initial context message that includes the summary/context content
                let contextMessage = settingsStore.appLanguage == .chineseTraditional ?
                    "我剛讀完 \(localizedBook) 第\(chapter)章的\(modeDescription)：\n\n「\(content)」\n\n我想更深入了解這段內容。" :
                    "I just read the \(modeDescription) of \(book) chapter \(chapter):\n\n\"\(content)\"\n\nI'd like to understand this more deeply."
                
                ChatView(
                    viewModel: ChatViewModel(
                        aiService: aiService,
                        appLanguage: settingsStore.appLanguage,
                        initialQuestion: contextMessage
                    ),
                    settingsStore: settingsStore,
                    onClose: {
                        showChatSheet = false
                    }
                )
                .environmentObject(router)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func loadContent() {
        // Reset button state
        showAskButton = false
        
        // Check cache first
        if let cachedContent = cacheStore.getCachedChapterContent(
            book: book,
            chapter: chapter,
            mode: mode.cacheKey,
            appLanguage: settingsStore.appLanguage
        ) {
            content = cachedContent
            isLoading = false
            // Show button with delay for cached content too
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showAskButton = true
                }
            }
            return
        }
        
        guard let aiService = services.aiService else {
            errorMessage = settingsStore.appLanguage == .chineseTraditional ? "服務不可用" : "Service not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        content = ""
        
        Task {
            do {
                let stream: AsyncThrowingStream<String, Error>
                
                switch mode {
                case .context:
                    stream = try await aiService.getChapterContext(book: book, chapter: chapter, appLanguage: settingsStore.appLanguage)
                case .summary:
                    stream = try await aiService.summarizeChapterStream(book: book, chapter: chapter, appLanguage: settingsStore.appLanguage)
                }
                
                var accumulatedContent = ""
                for try await chunk in stream {
                    accumulatedContent += chunk
                    await MainActor.run {
                        content = accumulatedContent
                    }
                }
                
                // Save to cache after successful load
                await MainActor.run {
                    isLoading = false
                    cacheStore.cacheChapterContent(
                        book: book,
                        chapter: chapter,
                        mode: mode.cacheKey,
                        appLanguage: settingsStore.appLanguage,
                        content: accumulatedContent
                    )
                    
                    // Show the Ask button with a slight delay and animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showAskButton = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

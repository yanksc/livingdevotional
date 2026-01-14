// VerseAIPanel - Verse explanation panel displayed underneath verse

import SwiftUI

struct VerseAIPanel: View {
    let verse: BibleVerse
    let mode: AIMode
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject private var aiCacheStore = AICacheStore.shared
    @Environment(\.services) var services
    @State private var explanation: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    let onClose: () -> Void
    
    var modeTitle: String {
        switch mode {
        case .insight:
            return settingsStore.appLanguage.localizedString("AIInsight")
        case .reflect:
            return settingsStore.appLanguage.localizedString("AIReflect")
        case .pray:
            return settingsStore.appLanguage.localizedString("AIPray")
        }
    }
    
    var modeIcon: String {
        switch mode {
        case .insight:
            return "lightbulb.fill"
        case .reflect:
            return "heart.fill"
        case .pray:
            return "hands.clap.fill"
        }
    }
    
    var verseText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with close button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: modeIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                    Text(modeTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Content area
            if let error = errorMessage {
                // Error state
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Button(settingsStore.appLanguage.localizedString("Retry")) {
                        errorMessage = nil
                        loadExplanation()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else if isLoading && explanation.isEmpty {
                // Loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(settingsStore.appLanguage.localizedString("GeneratingExplanation"))
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            } else if !explanation.isEmpty {
                // Explanation content
                ScrollView {
                    Text(explanation)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let cachedContent = aiCacheStore.getCachedResponse(verseId: verse.id, mode: mode, appLanguage: settingsStore.appLanguage)
            let logEntry: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "VerseAIPanel.onAppear",
                "message": "Panel appeared",
                "data": [
                    "mode": mode.rawValue,
                    "verseId": verse.id,
                    "appLanguage": settingsStore.appLanguage.rawValue,
                    "explanationEmpty": explanation.isEmpty,
                    "isLoading": isLoading,
                    "hasCachedContent": cachedContent != nil,
                    "cachedContentLength": cachedContent?.count ?? 0,
                    "hypothesisId": "E"
                ],
                "sessionId": "debug-session",
                "runId": "cache-debug"
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                }
            }
            // #endregion agent log
            
            // Check cache first
            if let cachedContent = aiCacheStore.getCachedResponse(verseId: verse.id, mode: mode, appLanguage: settingsStore.appLanguage) {
                explanation = cachedContent
                isLoading = false
                errorMessage = nil
            } else if explanation.isEmpty && !isLoading {
                loadExplanation()
            }
        }
        .onChange(of: mode) { oldMode, newMode in
            // #region agent log
            let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
            let cachedContent = aiCacheStore.getCachedResponse(verseId: verse.id, mode: newMode, appLanguage: settingsStore.appLanguage)
            let logEntry: [String: Any] = [
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "location": "VerseAIPanel.onChange",
                "message": "Mode changed",
                "data": [
                    "oldMode": oldMode.rawValue,
                    "newMode": newMode.rawValue,
                    "verseId": verse.id,
                    "appLanguage": settingsStore.appLanguage.rawValue,
                    "explanationLength": explanation.count,
                    "isLoading": isLoading,
                    "hasCachedContent": cachedContent != nil,
                    "cachedContentLength": cachedContent?.count ?? 0,
                    "hypothesisId": "E"
                ],
                "sessionId": "debug-session",
                "runId": "cache-debug"
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                    fileHandle.closeFile()
                } else {
                    try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                }
            }
            // #endregion agent log
            
            // Check cache for new mode first
            if let cachedContent = aiCacheStore.getCachedResponse(verseId: verse.id, mode: newMode, appLanguage: settingsStore.appLanguage) {
                explanation = cachedContent
                isLoading = false
                errorMessage = nil
            } else {
                // Reset state when mode changes and no cache available
                explanation = ""
                isLoading = false
                errorMessage = nil
                // Load new explanation for the new mode
                loadExplanation()
            }
        }
        .onChange(of: settingsStore.appLanguage) { oldLang, newLang in
            // When app language changes, clear current explanation and reload
            explanation = ""
            isLoading = false
            errorMessage = nil
            // Check cache for new language
            if let cachedContent = aiCacheStore.getCachedResponse(verseId: verse.id, mode: mode, appLanguage: newLang) {
                explanation = cachedContent
            } else {
                loadExplanation()
            }
        }
    }
    
    private func loadExplanation() {
        guard let aiService = services.aiService else {
            errorMessage = "服務未初始化"
            return
        }
        
        isLoading = true
        errorMessage = nil
        explanation = ""
        
        Task {
            do {
                let stream = try await aiService.explainVerse(
                    book: verse.book,
                    chapter: verse.chapter,
                    verse: verse.verseNumber,
                    verseText: verseText,
                    language: settingsStore.primaryLanguage,
                    mode: mode,
                    appLanguage: settingsStore.appLanguage,
                    conversationHistory: nil,
                    userPrompt: nil
                )
                
                var accumulatedText = ""
                var isFirstChunk = true
                
                for try await chunk in stream {
                    if isFirstChunk {
                        await MainActor.run {
                            isLoading = false
                        }
                        isFirstChunk = false
                    }
                    
                    accumulatedText += chunk
                    
                    await MainActor.run {
                        explanation = accumulatedText
                    }
                }
                
                // Cache the final response
                await MainActor.run {
                    if !accumulatedText.isEmpty {
                        aiCacheStore.cacheResponse(verseId: verse.id, mode: mode, appLanguage: settingsStore.appLanguage, content: accumulatedText)
                        
                        // #region agent log
                        let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
                        let logEntry: [String: Any] = [
                            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                            "location": "VerseAIPanel.loadExplanation",
                            "message": "Cached response",
                            "data": [
                                "verseId": verse.id,
                                "mode": mode.rawValue,
                                "appLanguage": settingsStore.appLanguage.rawValue,
                                "contentLength": accumulatedText.count,
                                "hypothesisId": "E"
                            ],
                            "sessionId": "debug-session",
                            "runId": "cache-debug"
                        ]
                        if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                                fileHandle.seekToEndOfFile()
                                fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                                fileHandle.closeFile()
                            } else {
                                try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                            }
                        }
                        // #endregion agent log
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let nsError = error as NSError? {
                        let errorDesc = nsError.localizedDescription
                        print("AIService Error Details: \(errorDesc), Code: \(nsError.code)")
                        
                        if nsError.code == 429 || errorDesc.contains("rate_limit") {
                            errorMessage = "服務暫時達到使用上限，請稍後再試。"
                        } else if nsError.code == 401 || errorDesc.contains("unauthorized") || errorDesc.contains("authentication") {
                            errorMessage = "API 認證失敗，請檢查 API 金鑰設定。"
                        } else if nsError.code == 400 {
                            errorMessage = "請求格式錯誤：\(errorDesc)"
                        } else {
                            errorMessage = "無法載入解釋：\(errorDesc)"
                        }
                    } else {
                        let errorString = String(describing: error)
                        print("AIService Error: \(errorString)")
                        errorMessage = "無法載入解釋：\(errorString)"
                    }
                }
            }
        }
    }
}

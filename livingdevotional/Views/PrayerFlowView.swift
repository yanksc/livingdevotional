// PrayerFlowView.swift
// Anytime Prayer Feature - Allows users to generate personalized prayers

import SwiftUI

// MARK: - Verse Option Model

struct VerseOption: Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let verseText: String
    let source: VerseSource
    let sourceDescription: String
    let timestamp: Date
    
    enum VerseSource {
        case dailyVerse
        case recentReading
        case savedNote
        case qaHistory
        case newSearch
    }
}

// MARK: - Prayer Flow View

struct PrayerFlowView: View {
    let initialVerse: BibleVerse?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.services) var services
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @ObservedObject private var checkInStore = CheckInStore.shared
    
    @State private var currentQuestionIndex = 0
    @State private var selectedFocus: PrayerFocus?
    @State private var customTopicText: String = ""
    @State private var selectedVerseOption: VerseOption?
    @State private var emotionalNeed: EmotionalNeed?
    
    @State private var verseOptions: [VerseOption] = []
    @State private var isLoadingOptions = false
    @State private var selectedVerse: DailyVerse?
    @State private var generatedPrayer: String = ""
    @State private var isLoadingVerse = false
    @State private var isLoadingPrayer = false
    @State private var errorMessage: String?
    
    init(initialVerse: BibleVerse? = nil) {
        self.initialVerse = initialVerse
    }
    
    enum PrayerFocus: String, CaseIterable {
        case recentFocus = "recent_focus"
        case worry = "worry"
        case gratitude = "gratitude"
        case guidance = "guidance"
        case strength = "strength"
        case custom = "custom"
        
        var displayName: String {
            let isChinese = SettingsStore.shared.appLanguage == .chineseTraditional
            switch self {
            case .recentFocus: return isChinese ? "最近的關注" : "Recent focus"
            case .worry: return isChinese ? "擔憂焦慮" : "Worry/anxiety"
            case .gratitude: return isChinese ? "感恩感謝" : "Gratitude/thanksgiving"
            case .guidance: return isChinese ? "指引決定" : "Guidance/decision"
            case .strength: return isChinese ? "力量鼓勵" : "Strength/encouragement"
            case .custom: return isChinese ? "自訂主題" : "Custom topic"
            }
        }
    }
    
    enum EmotionalNeed: String, CaseIterable {
        case peace = "peace"
        case wisdom = "wisdom"
        case strength = "strength"
        case hope = "hope"
        case forgiveness = "forgiveness"
        case other = "other"
        
        var displayName: String {
            let isChinese = SettingsStore.shared.appLanguage == .chineseTraditional
            switch self {
            case .peace: return isChinese ? "平安安慰" : "Peace/comfort"
            case .wisdom: return isChinese ? "智慧指引" : "Wisdom/guidance"
            case .strength: return isChinese ? "力量勇氣" : "Strength/courage"
            case .hope: return isChinese ? "希望鼓勵" : "Hope/encouragement"
            case .forgiveness: return isChinese ? "寬恕醫治" : "Forgiveness/healing"
            case .other: return isChinese ? "其他" : "Other"
            }
        }
    }
    
    private var questions: [QuestionType] {
        // Skip verse selection if initial verse is provided
        if initialVerse != nil {
            return [.heartFocus, .emotionalNeed]
        } else {
            return [.heartFocus, .chooseVerse, .emotionalNeed]
        }
    }
    
    enum QuestionType {
        case heartFocus
        case chooseVerse
        case emotionalNeed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SereneGradientBackground()
                
                if isLoadingVerse || isLoadingPrayer {
                    PrayerGenerationWaitingView(
                        verse: selectedVerse,
                        focus: selectedFocus,
                        emotionalNeed: emotionalNeed
                    )
                } else if let verse = selectedVerse, !generatedPrayer.isEmpty {
                    // Show verse and prayer result
                    PrayerResultView(
                        verse: verse,
                        prayer: generatedPrayer,
                        onDismiss: { dismiss() }
                    )
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.accentColor)
                        Text(error)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button(settingsStore.appLanguage == .chineseTraditional ? "重試" : "Retry") {
                            errorMessage = nil
                            if selectedVerse == nil {
                                generatePersonalizedVerse()
                            } else {
                                Task {
                                    await generatePrayer(for: selectedVerse!)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    // Show questions with page-flip transition
                    ZStack {
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            if index == currentQuestionIndex {
                                ScrollView {
                                    VStack(spacing: 24) {
                                        // Progress indicator
                                        ProgressIndicator(
                                            current: currentQuestionIndex + 1,
                                            total: questions.count
                                        )
                                        .padding(.top)
                                        
                                        // Question content
                                        Group {
                                            switch question {
                                            case .heartFocus:
                                                HeartFocusQuestionView(
                                                    selectedFocus: $selectedFocus,
                                                    customTopicText: $customTopicText,
                                                    onNext: handleAnswer,
                                                    onSkip: handleSkip
                                                )
                                            case .chooseVerse:
                                                ChooseVerseQuestionView(
                                                    verseOptions: verseOptions,
                                                    isLoading: isLoadingOptions,
                                                    selectedOption: $selectedVerseOption,
                                                    onNext: handleAnswer,
                                                    onSkip: handleSkip,
                                                    onLoadOptions: loadVerseOptions
                                                )
                                            case .emotionalNeed:
                                                EmotionalNeedQuestionView(
                                                    selectedNeed: $emotionalNeed,
                                                    onNext: handleAnswer,
                                                    onSkip: handleSkip
                                                )
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                }
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "禱告" : "Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(settingsStore.appLanguage == .chineseTraditional ? "取消" : "Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // If initial verse is provided, convert it to a VerseOption and set it
                if let verse = initialVerse {
                    let verseText = verse.text(for: settingsStore.primaryLanguage)
                    let bookName = BibleData.localizedBookName(verse.book, language: settingsStore.primaryLanguage)
                    let isChinese = settingsStore.appLanguage == .chineseTraditional
                    
                    selectedVerseOption = VerseOption(
                        id: "initial_\(verse.book)_\(verse.chapter)_\(verse.verseNumber)",
                        book: verse.book,
                        chapter: verse.chapter,
                        verseNumber: verse.verseNumber,
                        verseText: verseText,
                        source: .recentReading,
                        sourceDescription: isChinese ? "選中的經文：\(bookName) \(verse.chapter):\(verse.verseNumber)" : "Selected Verse: \(bookName) \(verse.chapter):\(verse.verseNumber)",
                        timestamp: Date()
                    )
                } else if verseOptions.isEmpty {
                    loadVerseOptions()
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadVerseOptions() {
        isLoadingOptions = true
        Task {
            var options: [VerseOption] = []
            let isChinese = settingsStore.appLanguage == .chineseTraditional
            
            // 1. Daily Verse
            if let dailyVerseService = services.dailyVerseService {
                do {
                    let dailyVerse = try await dailyVerseService.getVerseOfTheDay(date: nil)
                    let verseText = dailyVerse.text(for: settingsStore.primaryLanguage)
                    options.append(VerseOption(
                        id: "daily_\(dailyVerse.book)_\(dailyVerse.chapter)_\(dailyVerse.verseNumber)",
                        book: dailyVerse.book,
                        chapter: dailyVerse.chapter,
                        verseNumber: dailyVerse.verseNumber,
                        verseText: verseText,
                        source: .dailyVerse,
                        sourceDescription: isChinese ? "今日經文" : "Today's Verse",
                        timestamp: Date()
                    ))
                } catch {
                    // Silently fail - daily verse is optional
                }
            }
            
            // 2. Recent Reading
            if let book = progressStore.currentBook,
               let chapter = progressStore.currentChapter {
                // Try to load a verse from the current chapter
                do {
                    let verses = try await services.bibleService.loadVerses(
                        book: book,
                        chapter: chapter,
                        translation: settingsStore.primaryLanguage
                    )
                    if let firstVerse = verses.first {
                        let verseText = firstVerse.text(for: settingsStore.primaryLanguage)
                        let bookName = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                        options.append(VerseOption(
                            id: "reading_\(book)_\(chapter)_\(firstVerse.verseNumber)",
                            book: book,
                            chapter: chapter,
                            verseNumber: firstVerse.verseNumber,
                            verseText: verseText,
                            source: .recentReading,
                            sourceDescription: isChinese ? "最近閱讀：\(bookName) \(chapter)章" : "Recent Reading: \(bookName) \(chapter)",
                            timestamp: Date()
                        ))
                    }
                } catch {
                    // If loading fails, still add option with placeholder text
                    let bookName = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                    options.append(VerseOption(
                        id: "reading_\(book)_\(chapter)_1",
                        book: book,
                        chapter: chapter,
                        verseNumber: 1,
                        verseText: isChinese ? "從您正在閱讀的章節" : "From your current reading",
                        source: .recentReading,
                        sourceDescription: isChinese ? "最近閱讀：\(bookName) \(chapter)章" : "Recent Reading: \(bookName) \(chapter)",
                        timestamp: Date()
                    ))
                }
            }
            
            // 3. Recently Saved Verses (last 5)
            let recentSaved = Array(noteStore.savedVerses.prefix(5))
            for savedVerse in recentSaved {
                do {
                    let verses = try await services.bibleService.loadVerses(
                        book: savedVerse.book,
                        chapter: savedVerse.chapter,
                        translation: settingsStore.primaryLanguage
                    )
                    if let verse = verses.first(where: { $0.verseNumber == savedVerse.verse }) {
                        let verseText = verse.text(for: settingsStore.primaryLanguage)
                        options.append(VerseOption(
                            id: "saved_\(savedVerse.id)",
                            book: savedVerse.book,
                            chapter: savedVerse.chapter,
                            verseNumber: savedVerse.verse,
                            verseText: verseText,
                            source: .savedNote,
                            sourceDescription: isChinese ? "已保存" : "Saved",
                            timestamp: savedVerse.timestamp
                        ))
                    }
                } catch {
                    // Skip if can't load verse text
                    continue
                }
            }
            
            // 4. Recent Q&A Verses (last 5)
            let recentQAs = Array(chatStore.sessions.prefix(5))
            for session in recentQAs {
                // Only include sessions with complete verse context
                guard let book = session.book,
                      let chapter = session.chapter,
                      let verseNumber = session.verseNumber,
                      let verseText = session.verseText else {
                    continue
                }
                options.append(VerseOption(
                    id: "qa_\(session.id)",
                    book: book,
                    chapter: chapter,
                    verseNumber: verseNumber,
                    verseText: verseText,
                    source: .qaHistory,
                    sourceDescription: isChinese ? "問答記錄" : "From Q&A",
                    timestamp: session.updatedAt
                ))
            }
            
            // 5. "Find something new" option
            options.append(VerseOption(
                id: "new_search",
                book: "",
                chapter: 0,
                verseNumber: 0,
                verseText: isChinese ? "為我找一節新的經文" : "Find me a new verse",
                source: .newSearch,
                sourceDescription: isChinese ? "新經文" : "New Verse",
                timestamp: Date.distantPast
            ))
            
            // Sort by timestamp (most recent first), but keep "new_search" at the end
            await MainActor.run {
                verseOptions = options.sorted { option1, option2 in
                    if option1.source == .newSearch { return false }
                    if option2.source == .newSearch { return true }
                    return option1.timestamp > option2.timestamp
                }
                isLoadingOptions = false
            }
        }
    }
    
    // MARK: - Flow Control
    
    private func handleAnswer() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuestionIndex += 1
            }
        } else {
            generatePersonalizedVerse()
        }
    }
    
    private func handleSkip() {
        // Skip current question with default values
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuestionIndex += 1
            }
        } else {
            generatePersonalizedVerse()
        }
    }
    
    private func generatePersonalizedVerse() {
        isLoadingVerse = true
        errorMessage = nil
        
        Task {
            do {
                let verse: DailyVerse
                
                // Determine which verse to use
                if let selectedOption = selectedVerseOption {
                    if selectedOption.source == .newSearch {
                        // Use AI to find a new verse based on user's answers
                        verse = try await findVerseWithAI()
                    } else {
                        // Use the selected verse
                        verse = try await loadVerseFromOption(selectedOption)
                    }
                } else {
                    // Fallback: use daily verse or find new
                    if let dailyVerseService = services.dailyVerseService,
                       let dailyVerse = try? await dailyVerseService.getVerseOfTheDay(date: nil) {
                        verse = dailyVerse
                    } else {
                        verse = try await findVerseWithAI()
                    }
                }
                
                // Set verse early so waiting view can display it
                await MainActor.run {
                    selectedVerse = verse
                }
                
                // Generate prayer using existing AI service
                await generatePrayer(for: verse)
                
                await MainActor.run {
                    isLoadingVerse = false
                }
            } catch {
                await MainActor.run {
                    isLoadingVerse = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func findVerseWithAI() async throws -> DailyVerse {
        guard let aiService = services.aiService else {
            throw NSError(domain: "PrayerFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service not available"])
        }
        
        // Use custom topic text if user selected custom and entered text
        let focusText: String
        if selectedFocus == .custom && !customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            focusText = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            focusText = selectedFocus?.displayName ?? ""
        }
        let needText = emotionalNeed?.displayName ?? ""
        
        return try await aiService.findVerseForPrayer(
            focus: focusText,
            need: needText,
            language: settingsStore.primaryLanguage,
            appLanguage: settingsStore.appLanguage
        )
    }
    
    private func loadVerseFromOption(_ option: VerseOption) async throws -> DailyVerse {
        // Load verse text from BibleService for all translations
        let verses = try await services.bibleService.loadVerses(
            book: option.book,
            chapter: option.chapter,
            translation: settingsStore.primaryLanguage
        )
        
        guard let verse = verses.first(where: { $0.verseNumber == option.verseNumber }) else {
            throw NSError(domain: "PrayerFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verse not found"])
        }
        
        // Convert BibleVerse to DailyVerse
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        return DailyVerse(
            book: option.book,
            chapter: option.chapter,
            verseNumber: option.verseNumber,
            textBsb: verse.textBsb,
            textCuv: verse.textCuv,
            textCu1: verse.textCu1,
            textKjv: verse.textKjv,
            textWeb: verse.textWeb,
            textSpa: verse.textSpa,
            textPor: verse.textPor,
            reference: "\(option.book) \(option.chapter):\(option.verseNumber)",
            selectedDate: dateString
        )
    }
    
    private func generatePrayer(for verse: DailyVerse) async {
        isLoadingPrayer = true
        errorMessage = nil
        
        guard let aiService = services.aiService else {
            await MainActor.run {
                isLoadingPrayer = false
                errorMessage = "AI service not available"
            }
            return
        }
        
        let verseText = verse.text(for: settingsStore.primaryLanguage)
        
        // Build custom prayer prompt if user entered a custom topic
        let customPrayerPrompt: String?
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        let isSimplified = languageCode == "zh-Hans"
        let isChinese = languageCode == "zh-Hans" || languageCode == "zh-Hant"
        
        if selectedFocus == .custom && !customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let topic = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
            let needText = emotionalNeed?.displayName ?? ""
            
            if isSimplified {
                customPrayerPrompt = """
                请根据这节经文撰写一篇简短而深刻的祷告文，特别针对以下主题：「\(topic)」
                \(needText.isEmpty ? "" : "读者现在需要：\(needText)")
                
                请简洁地包含：
                1. 感谢神在这节经文中显明的真理
                2. 为「\(topic)」这个主题向神祷告
                3. 祈求神帮助我们活出这节经文的教导
                
                请用简体中文书写，以"亲爱的天父"或"主啊"开头。请控制在 80-120 字以内，精简而深刻。
                """
            } else if isChinese {
                customPrayerPrompt = """
                請根據這節經文撰寫一篇簡短而深刻的禱告文，特別針對以下主題：「\(topic)」
                \(needText.isEmpty ? "" : "讀者現在需要：\(needText)")
                
                請簡潔地包含：
                1. 感謝神在這節經文中顯明的真理
                2. 為「\(topic)」這個主題向神禱告
                3. 祈求神幫助我們活出這節經文的教導
                
                請用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭。請控制在 80-120 字以內，精簡而深刻。
                """
            } else {
                customPrayerPrompt = """
                Please compose a concise and meaningful prayer based on this verse, specifically addressing this topic: "\(topic)"
                \(needText.isEmpty ? "" : "The reader currently needs: \(needText)")
                
                Briefly include:
                1. Thanksgiving for the truth revealed in this verse
                2. Prayer to God specifically about "\(topic)"
                3. Request for God's help to live out this verse's teaching
                
                Please write in English, starting with "Dear Heavenly Father" or "Lord". Please keep it concise and meaningful, around 60-100 words.
                """
            }
        } else {
            customPrayerPrompt = nil
        }
        
        do {
            var accumulatedPrayer = ""
            let stream = try await aiService.explainVerse(
                book: verse.book,
                chapter: verse.chapter,
                verse: verse.verseNumber,
                verseText: verseText,
                language: settingsStore.primaryLanguage,
                mode: .pray,
                appLanguage: settingsStore.appLanguage,
                conversationHistory: nil,
                userPrompt: customPrayerPrompt
            )
            
            for try await chunk in stream {
                accumulatedPrayer += chunk
            }
            
            await MainActor.run {
                generatedPrayer = accumulatedPrayer
                isLoadingPrayer = false
                
                // Save prayer log
                savePrayerLog(verse: verse, prayer: accumulatedPrayer)
            }
        } catch {
            await MainActor.run {
                isLoadingPrayer = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func resetFlow() {
        currentQuestionIndex = 0
        selectedFocus = nil
        customTopicText = ""
        selectedVerseOption = nil
        emotionalNeed = nil
        selectedVerse = nil
        generatedPrayer = ""
        verseOptions = []
        errorMessage = nil
        loadVerseOptions()
    }
    
    // MARK: - Prayer Logging
    
    private func savePrayerLog(verse: DailyVerse, prayer: String) {
        // Determine topic string
        let topicString: String
        if selectedFocus == .custom {
            topicString = "custom"
        } else {
            topicString = selectedFocus?.rawValue ?? "other"
        }
        
        // Get verse text
        let verseText = verse.text(for: settingsStore.primaryLanguage)
        
        // Create prayer log
        let log = PrayerLog(
            topic: topicString,
            customTopicText: selectedFocus == .custom && !customTopicText.isEmpty ? customTopicText : nil,
            verseReference: "\(verse.book) \(verse.chapter):\(verse.verseNumber)",
            verseBook: verse.book,
            verseChapter: verse.chapter,
            verseNumber: verse.verseNumber,
            verseText: verseText,
            prayerText: prayer,
            emotionalNeed: emotionalNeed?.rawValue
        )
        
        // Save to store
        services.prayerLogStore.addLog(log)
        
        // Also record prayer check-in for streak
        checkInStore.recordPrayer()
    }
}

// MARK: - Question Views

struct HeartFocusQuestionView: View {
    @Binding var selectedFocus: PrayerFlowView.PrayerFocus?
    @Binding var customTopicText: String
    var onNext: () -> Void
    var onSkip: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<PrayerFlowView.PrayerFocus> = []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "今天您心中有什麼？" : "What's on your heart today?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(PrayerFlowView.PrayerFocus.allCases.enumerated()), id: \.element) { index, focus in
                    Button {
                        selectedFocus = focus
                        if focus != .custom {
                            onNext()
                        } else {
                            // Focus text field when custom is selected
                            isTextFieldFocused = true
                        }
                    } label: {
                        HStack {
                            Text(focus.displayName)
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selectedFocus == focus {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            selectedFocus == focus 
                                ? AppTheme.accentColor.opacity(0.1)
                                : Color.white.opacity(0.9)
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .opacity(appearedOptions.contains(focus) ? 1.0 : 0.0)
                    .offset(x: appearedOptions.contains(focus) ? 0 : 30)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                let _ = appearedOptions.insert(focus)
                            }
                        }
                    }
                }
                
                // Custom topic text field (shown when custom is selected)
                if selectedFocus == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "請輸入您的禱告主題" : "Enter your prayer topic")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        
                        TextField(
                            settingsStore.appLanguage == .chineseTraditional ? "例如：工作、家庭、健康..." : "e.g., work, family, health...",
                            text: $customTopicText,
                            axis: .vertical
                        )
                        .focused($isTextFieldFocused)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTextFieldFocused ? AppTheme.accentColor : Color.clear, lineWidth: 2)
                        )
                        .lineLimit(3...5)
                        
                        Button {
                            if !customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onNext()
                            }
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "繼續" : "Continue")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? AppTheme.secondaryText.opacity(0.3)
                                        : AppTheme.accentColor
                                )
                                .cornerRadius(12)
                        }
                        .disabled(customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 4)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Skip button
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

struct ChooseVerseQuestionView: View {
    let verseOptions: [VerseOption]
    let isLoading: Bool
    @Binding var selectedOption: VerseOption?
    var onNext: () -> Void
    var onSkip: () -> Void
    var onLoadOptions: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "選擇一節經文來禱告" : "Choose a verse to pray with")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if verseOptions.isEmpty {
                Button(settingsStore.appLanguage == .chineseTraditional ? "載入經文選項" : "Load Verse Options") {
                    onLoadOptions()
                }
                .buttonStyle(.borderedProminent)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(verseOptions.enumerated()), id: \.element.id) { index, option in
                            VerseOptionCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id,
                                onSelect: {
                                    selectedOption = option
                                    onNext()
                                }
                            )
                            .opacity(appearedOptions.contains(option.id) ? 1.0 : 0.0)
                            .offset(x: appearedOptions.contains(option.id) ? 0 : 30)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        let _ = appearedOptions.insert(option.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Skip button
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

struct VerseOptionCard: View {
    let option: VerseOption
    let isSelected: Bool
    var onSelect: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Source label
                Text(option.sourceDescription)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accentColor)
                
                // Verse text preview
                Text(option.verseText)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Reference
                if option.source != .newSearch {
                    Text("\(BibleData.localizedBookName(option.book, language: settingsStore.primaryLanguage)) \(option.chapter):\(option.verseNumber)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                if isSelected {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected 
                    ? AppTheme.accentColor.opacity(0.1)
                    : Color.white
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmotionalNeedQuestionView: View {
    @Binding var selectedNeed: PrayerFlowView.EmotionalNeed?
    var onNext: () -> Void
    var onSkip: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<PrayerFlowView.EmotionalNeed> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "您現在最需要什麼？" : "What would help you most right now?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(PrayerFlowView.EmotionalNeed.allCases.enumerated()), id: \.element) { index, need in
                    Button {
                        selectedNeed = need
                        onNext()
                    } label: {
                        HStack {
                            Text(need.displayName)
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if selectedNeed == need {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            selectedNeed == need 
                                ? AppTheme.accentColor.opacity(0.1)
                                : Color.white.opacity(0.9)
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .opacity(appearedOptions.contains(need) ? 1.0 : 0.0)
                    .offset(x: appearedOptions.contains(need) ? 0 : 30)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                let _ = appearedOptions.insert(need)
                            }
                        }
                    }
                }
            }
            
            // Skip button
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct PrayerResultView: View {
    let verse: DailyVerse
    let prayer: String
    var onDismiss: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        ZStack {
            SereneGradientBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Prayer text - starts from top, animated
                    TypewriterText(
                        text: prayer,
                        speed: 0.05,
                        font: .system(size: 18, weight: .regular, design: .serif)
                    )
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // Verse display - below prayer text
                    VStack(spacing: 12) {
                        Text(verse.text(for: settingsStore.primaryLanguage))
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                        
                        if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                            Text(verse.text(for: settingsStore.secondaryLanguage))
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        Text("\(BibleData.localizedBookName(verse.book, language: settingsStore.primaryLanguage)) \(verse.chapter):\(verse.verseNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    
                    // Amen Button
                    AmenButton(onComplete: onDismiss)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Typewriter Text Animation

struct TypewriterText: View {
    let text: String
    let speed: Double
    let font: Font
    
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        guard currentIndex < text.count else { return }
        
        // Check if text contains Chinese characters
        let isChinese = text.range(of: "\\p{Han}", options: .regularExpression) != nil
        
        if isChinese {
            // Character by character for Chinese (including punctuation)
            let nextIndex = min(currentIndex + 1, text.count)
            let index = text.index(text.startIndex, offsetBy: nextIndex)
            displayedText = String(text[..<index])
            currentIndex = nextIndex
            
            if currentIndex < text.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
                    startTyping()
                }
            }
        } else {
            // Word by word for English
            let words = text.split(separator: " ", omittingEmptySubsequences: false)
            let currentWordCount = displayedText.isEmpty ? 0 : displayedText.split(separator: " ", omittingEmptySubsequences: false).count
            
            if currentWordCount < words.count {
                let nextWords = Array(words[0..<min(currentWordCount + 1, words.count)])
                displayedText = nextWords.joined(separator: " ")
                
                if currentWordCount + 1 < words.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + speed * 2) {
                        startTyping()
                    }
                }
            }
        }
    }
}

// MARK: - Amen Button

struct AmenButton: View {
    var onComplete: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    @State private var isHolding = false
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private let holdDuration: Double = 3.0 // 3 seconds
    private let buttonSize: CGFloat = 80
    private let progressRingWidth: CGFloat = 6
    
    var body: some View {
        ZStack {
            // Outer progress ring - full circle around button
            if isHolding {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.accentColor.opacity(0.9),
                                AppTheme.accentColor,
                                AppTheme.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: progressRingWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
                    .animation(.linear(duration: 0.05), value: progress)
            }
            
            // Button background
            Circle()
                .fill(
                    LinearGradient(
                        colors: isHolding ? [
                            AppTheme.accentColor.opacity(0.9),
                            AppTheme.accentColor
                        ] : [
                            AppTheme.accentColor.opacity(0.8),
                            AppTheme.accentColor.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: AppTheme.accentColor.opacity(isHolding ? 0.5 : 0.3), radius: isHolding ? 15 : 8)
                .scaleEffect(isHolding ? 1.05 : 1.0)
            
            // Button text
            Text(settingsStore.appLanguage == .chineseTraditional ? "阿們" : "Amen")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(isHolding ? 1.1 : 1.0)
        }
        .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        startHolding()
                    }
                }
                .onEnded { _ in
                    stopHolding()
                }
        )
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startHolding() {
        isHolding = true
        progress = 0.0
        
        // Initial haptic feedback
        hapticLight.prepare()
        hapticLight.impactOccurred()
        
        // Start timer
        let startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            progress = min(elapsed / holdDuration, 1.0)
            
            // Haptic feedback at 50%
            if progress >= 0.5 && progress < 0.52 {
                hapticMedium.prepare()
                hapticMedium.impactOccurred()
            }
            
            // Completion
            if progress >= 1.0 {
                timer.invalidate()
                completeAmen()
            }
        }
    }
    
    private func stopHolding() {
        isHolding = false
        timer?.invalidate()
        timer = nil
        
        // Reset animation
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0.0
        }
    }
    
    private func completeAmen() {
        // Success haptic
        notificationGenerator.notificationOccurred(.success)
        
        // Visual flourish
        withAnimation(.easeOut(duration: 0.5)) {
            progress = 1.0
        }
        
        // Small delay for visual feedback, then complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}


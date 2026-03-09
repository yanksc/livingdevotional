// PrayerFlowViewModel.swift
// ViewModel for the Prayer Flow feature - manages verse loading, AI calls, and flow state

import Foundation
import SwiftUI

@MainActor
class PrayerFlowViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var currentQuestionIndex = 0
    @Published var selectedIntent: PrayerIntent?
    @Published var selectedTopics: Set<PrayerTopic> = []
    @Published var customTopicText: String = ""
    @Published var selectedVerseOption: VerseOption?
    
    @Published var verseOptions: [VerseOption] = []
    @Published var isLoadingOptions = false
    @Published var selectedVerse: DailyVerse?
    @Published var generatedPrayer: String = ""
    @Published var isLoadingVerse = false
    @Published var isLoadingPrayer = false
    @Published var errorMessage: String?
    @Published var backgroundTransitionProgress: Double = 0.0
    @Published var introBackgroundProgress: Double = 0.0
    @Published var introLine1Visible: Bool = false
    @Published var introLine2Visible: Bool = false
    @Published var limitReached: Bool = false
    
    /// Verses already shown in this prayer session; used to exclude from re-search.
    private var excludedVerseReferences: [String] = []
    
    // MARK: - Dependencies
    
    private let settingsStore = SettingsStore.shared
    private let progressStore = ProgressStore.shared
    private let noteStore = NoteStore.shared
    private let chatStore = ChatStore.shared
    private let checkInStore = CheckInStore.shared
    
    let initialVerse: BibleVerse?
    var services: ServiceContainer?
    
    // MARK: - Computed Properties
    
    var questions: [PrayerQuestionType] {
        let intro: [PrayerQuestionType] = [.prayerIntro]
        let topicScreen: [PrayerQuestionType] = [.firstScreen]
        let verseQuestion: [PrayerQuestionType] = initialVerse != nil ? [] : [.chooseVerse]
        return intro + topicScreen + verseQuestion
    }
    
    // MARK: - Init
    
    init(initialVerse: BibleVerse? = nil) {
        self.initialVerse = initialVerse
    }
    
    // MARK: - Setup
    
    func setup(services: ServiceContainer) {
        self.services = services
        
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
    
    // MARK: - Data Loading
    
    func loadVerseOptions() {
        guard let services = services else { return }
        isLoadingOptions = true
        Task {
            var options: [VerseOption] = []
            let isChinese = settingsStore.appLanguage == .chineseTraditional
            
            // 1. Recent Reading
            if let book = progressStore.currentBook,
               let chapter = progressStore.currentChapter {
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
            
            // 2. Recently Saved Verses (last 5)
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
                    continue
                }
            }
            
            // 3. Recent Q&A Verses (last 5)
            let recentQAs = Array(chatStore.sessions.prefix(5))
            for session in recentQAs {
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
            
            // Sort by timestamp (most recent first)
            verseOptions = options.sorted { $0.timestamp > $1.timestamp }
            isLoadingOptions = false
        }
    }
    
    // MARK: - Flow Control
    
    func advanceFromIntro() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuestionIndex += 1
            }
        }
    }
    
    private var hasStartedIntroSequence = false
    
    func startIntroSequence() {
        guard !hasStartedIntroSequence else { return }
        hasStartedIntroSequence = true
        
        introBackgroundProgress = 0
        introLine1Visible = false
        introLine2Visible = false
        
        Task { @MainActor in
            // Phase 1-2: Background emerges over 2s
            withAnimation(.easeInOut(duration: 2.0)) {
                introBackgroundProgress = 1.0
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Phase 3: Line 1 appears ("Every prayer brings you closer to Him")
            withAnimation(.easeInOut(duration: 2.0)) {
                introLine1Visible = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Phase 4: Line 2 appears (Psalm 145:18 quote in rounded rect)
            withAnimation(.easeInOut(duration: 2.0)) {
                introLine2Visible = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Phase 5: Pause before advancing
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            advanceFromIntro()
        }
    }
    
    func handleIntentSelected(_ intent: PrayerIntent) {
        selectedIntent = intent
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuestionIndex += 1
            }
            // Generate verse immediately when advancing to verse selection (page 3)
            if questions[currentQuestionIndex] == .chooseVerse {
                generateVerseOnly()
            }
        } else {
            // No verse selection step (e.g. initialVerse provided)—generate verse and prayer directly
            generateVerseAndPrayer()
        }
    }
    
    func handleFindVerse() {
        if let verse = selectedVerse {
            let ref = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
            excludedVerseReferences.append(ref)
        }
        selectedVerseOption = nil
        generateVerseOnly()
    }
    
    func handleSelectVerseOption(_ option: VerseOption) {
        selectedVerseOption = option
        generateVerseOnly()
    }
    
    /// Finds a verse (AI or from option) and shows it on verse selection screen. Does NOT generate prayer.
    func generateVerseOnly() {
        guard let services = services else { return }
        isLoadingVerse = true
        errorMessage = nil
        selectedVerse = nil
        
        Task {
            do {
                let verse: DailyVerse
                
                if let selectedOption = selectedVerseOption {
                    verse = try await loadVerseFromOption(selectedOption)
                } else {
                    verse = try await findVerseWithAI(excludeReferences: excludedVerseReferences)
                }
                
                selectedVerse = verse
                isLoadingVerse = false
            } catch {
                isLoadingVerse = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// User confirmed the verse on verse selection screen—generate prayer and show result.
    func handleConfirmVerseAndGeneratePrayer() {
        guard let verse = selectedVerse else { return }
        Task {
            await generatePrayer(for: verse)
        }
    }
    
    /// Generate verse and prayer in one go (used when no verse selection step, e.g. initialVerse provided).
    private func generateVerseAndPrayer() {
        guard let services = services else { return }
        isLoadingVerse = true
        errorMessage = nil
        
        Task {
            do {
                let verse: DailyVerse
                
                if let selectedOption = selectedVerseOption {
                    verse = try await loadVerseFromOption(selectedOption)
                } else {
                    verse = try await findVerseWithAI(excludeReferences: excludedVerseReferences)
                }
                
                selectedVerse = verse
                await generatePrayer(for: verse)
                isLoadingVerse = false
            } catch {
                isLoadingVerse = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func findVerseWithAI(excludeReferences: [String]) async throws -> DailyVerse {
        guard let aiService = services?.aiService else {
            throw NSError(domain: "PrayerFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service not available"])
        }
        
        let customTrimmed = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        let topicsText = selectedTopics.map(\.displayName).joined(separator: ", ")
        let focusText: String
        if !customTrimmed.isEmpty && !topicsText.isEmpty {
            focusText = "\(customTrimmed), \(topicsText)"
        } else if !customTrimmed.isEmpty {
            focusText = customTrimmed
        } else {
            focusText = topicsText
        }
        let needText = focusText.isEmpty ? "" : focusText
        
        return try await aiService.findVerseForPrayer(
            focus: focusText,
            need: needText,
            language: settingsStore.primaryLanguage,
            appLanguage: settingsStore.appLanguage,
            excludeReferences: excludeReferences
        )
    }
    
    private func loadVerseFromOption(_ option: VerseOption) async throws -> DailyVerse {
        guard let services = services else {
            throw NSError(domain: "PrayerFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Services not available"])
        }
        
        let verses = try await services.bibleService.loadVerses(
            book: option.book,
            chapter: option.chapter,
            translation: settingsStore.primaryLanguage
        )
        
        guard let verse = verses.first(where: { $0.verseNumber == option.verseNumber }) else {
            throw NSError(domain: "PrayerFlow", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verse not found"])
        }
        
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
    
    func generatePrayer(for verse: DailyVerse) async {
        guard let aiService = services?.aiService else {
            isLoadingPrayer = false
            errorMessage = "AI service not available"
            return
        }
        
        guard UsageLimitStore.shared.canGeneratePrayer() else {
            limitReached = true
            return
        }
        
        isLoadingPrayer = true
        errorMessage = nil
        
        let verseText = verse.text(for: settingsStore.primaryLanguage)
        let prayerPrompt = buildPrayerPrompt(verseText: verseText)
        
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
                userPrompt: prayerPrompt
            )
            
            for try await chunk in stream {
                accumulatedPrayer += chunk
            }
            
            generatedPrayer = accumulatedPrayer
            isLoadingPrayer = false
            UsageLimitStore.shared.recordPrayerGenerated()
            
            withAnimation(.easeInOut(duration: 2.0)) {
                backgroundTransitionProgress = 1.0
            }
            
            savePrayerLog(verse: verse, prayer: accumulatedPrayer)
        } catch {
            isLoadingPrayer = false
            errorMessage = error.localizedDescription
        }
    }
    
    private func buildPrayerPrompt(verseText: String) -> String {
        let intent = selectedIntent ?? .helpMePray
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        let isSimplified = languageCode == "zh-Hans"
        let isChinese = languageCode == "zh-Hans" || languageCode == "zh-Hant"
        let customTrimmed = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        let topicsText = selectedTopics.map(\.displayName).joined(separator: ", ")
        let focusText: String
        if !customTrimmed.isEmpty && !topicsText.isEmpty {
            focusText = "\(customTrimmed), \(topicsText)"
        } else if !customTrimmed.isEmpty {
            focusText = customTrimmed
        } else {
            focusText = topicsText
        }
        let needText = focusText
        
        switch intent {
        case .prayForMe:
            let name = UserProfileStore.shared.profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameForPrayer: String
            if isSimplified {
                nameForPrayer = name.isEmpty ? "这个孩子" : name
            } else if isChinese {
                nameForPrayer = name.isEmpty ? "這位孩子" : name
            } else {
                nameForPrayer = name.isEmpty ? "this child" : name
            }
            if isSimplified {
                return """
                请根据这节经文撰写一篇简短的代祷文，为 \(nameForPrayer) 向神祷告。你是在代替别人向神祈求，不是让 \(nameForPrayer) 自己祷告。
                \(focusText.isEmpty ? "" : "祷告主题：\(focusText)")\(needText.isEmpty ? "" : "\n他们目前需要：\(needText)")
                
                请用"我们为 \(nameForPrayer) 祷告"或类似的代祷语开头。用简体中文书写，以"亲爱的天父"或"主啊"开头。请控制在 105-155 字以内。
                """
            } else if isChinese {
                return """
                請根據這節經文撰寫一篇簡短的代禱文，為 \(nameForPrayer) 向神禱告。你是在代替別人向神祈求，不是讓 \(nameForPrayer) 自己禱告。
                \(focusText.isEmpty ? "" : "禱告主題：\(focusText)")\(needText.isEmpty ? "" : "\n他們目前需要：\(needText)")
                
                請用「我們為 \(nameForPrayer) 禱告」或類似的代禱語開頭。用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭。請控制在 105-155 字以內。
                """
            } else {
                return """
                Compose an intercessory prayer praying FOR \(nameForPrayer) based on this verse. You are praying on their behalf to God, not as if they are praying themselves.
                \(focusText.isEmpty ? "" : "Prayer focus: \(focusText)")\(needText.isEmpty ? "" : "\nThey currently need: \(needText)")
                
                Use phrases like "We lift up \(nameForPrayer) to You" or "We pray for \(nameForPrayer)". Write in English, starting with "Dear Heavenly Father" or "Lord". Keep it concise and meaningful, around 60-100 words.
                """
            }
        case .helpMePray:
            guard !focusText.isEmpty else {
                if isSimplified {
                    return """
                    请根据这节经文撰写一篇简短而深刻的祷告文，供读者自己向神祷告。
                    \(focusText.isEmpty ? "" : "读者心中的主题：\(focusText)")\(needText.isEmpty ? "" : "\n读者现在需要：\(needText)")
                    
                    请简洁地包含：感谢神显明的真理、认罪悔改（如经文章相关）、祈求神帮助活出教导。请用简体中文书写，以"亲爱的天父"或"主啊"开头，用第一人称（我/我们）。请控制在 105-155 字以内。
                    """
                } else if isChinese {
                    return """
                    請根據這節經文撰寫一篇簡短而深刻的禱告文，供讀者自己向神禱告。
                    \(focusText.isEmpty ? "" : "讀者心中的主題：\(focusText)")\(needText.isEmpty ? "" : "\n讀者現在需要：\(needText)")
                    
                    請簡潔地包含：感謝神顯明的真理、認罪悔改（如經文相關）、祈求神幫助活出教導。請用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭，用第一人稱（我/我們）。請控制在 105-155 字以內。
                    """
                } else {
                    return """
                    Please compose a concise and meaningful prayer based on this verse for the reader to pray themselves.
                    \(focusText.isEmpty ? "" : "Their heart's focus: \(focusText)")\(needText.isEmpty ? "" : "\nThey currently need: \(needText)")
                    
                    Briefly include: thanksgiving for the truth in this verse, confession/repentance (if relevant), request for God's help to live out the teaching. Please write in English, starting with "Dear Heavenly Father" or "Lord", using first person (I/we). Keep it around 60-100 words.
                    """
                }
            }
            if isSimplified {
                return """
                请根据这节经文撰写一篇简短而深刻的祷告文，特别针对以下主题：「\(focusText)」
                \(needText.isEmpty ? "" : "读者现在需要：\(needText)")
                
                请简洁地包含：感谢神显明的真理、为「\(focusText)」向神祷告、祈求神帮助活出教导。请用简体中文书写，以"亲爱的天父"或"主啊"开头，用第一人称。请控制在 105-155 字以内。
                """
            } else if isChinese {
                return """
                請根據這節經文撰寫一篇簡短而深刻的禱告文，特別針對以下主題：「\(focusText)」
                \(needText.isEmpty ? "" : "讀者現在需要：\(needText)")
                
                請簡潔地包含：感謝神顯明的真理、為「\(focusText)」向神禱告、祈求神幫助活出教導。請用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭，用第一人稱。請控制在 105-155 字以內。
                """
            } else {
                return """
                Please compose a concise and meaningful prayer based on this verse, specifically addressing: "\(focusText)"
                \(needText.isEmpty ? "" : "The reader currently needs: \(needText)")
                
                Briefly include: thanksgiving, prayer about "\(focusText)", request for God's help. Please write in English, starting with "Dear Heavenly Father" or "Lord", using first person. Keep it around 60-100 words.
                """
            }
        }
    }
    
    func resetFlow() {
        currentQuestionIndex = 0
        hasStartedIntroSequence = false
        introBackgroundProgress = 0.0
        introLine1Visible = false
        introLine2Visible = false
        selectedIntent = nil
        selectedTopics = []
        customTopicText = ""
        selectedVerseOption = nil
        selectedVerse = nil
        generatedPrayer = ""
        verseOptions = []
        excludedVerseReferences = []
        errorMessage = nil
        loadVerseOptions()
    }
    
    // MARK: - Prayer Logging
    
    private func savePrayerLog(verse: DailyVerse, prayer: String) {
        guard let services = services else { return }
        
        let customTrimmed = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        let topicString: String
        let customTopicTextForLog: String?
        if !customTrimmed.isEmpty {
            topicString = "custom"
            customTopicTextForLog = customTrimmed
        } else if !selectedTopics.isEmpty {
            topicString = selectedTopics.map(\.rawValue).joined(separator: ",")
            customTopicTextForLog = nil
        } else {
            topicString = "other"
            customTopicTextForLog = nil
        }
        
        let verseText = verse.text(for: settingsStore.primaryLanguage)
        
        let log = PrayerLog(
            topic: topicString,
            customTopicText: customTopicTextForLog,
            verseReference: "\(verse.book) \(verse.chapter):\(verse.verseNumber)",
            verseBook: verse.book,
            verseChapter: verse.chapter,
            verseNumber: verse.verseNumber,
            verseText: verseText,
            prayerText: prayer,
            emotionalNeed: nil
        )
        
        services.prayerLogStore.addLog(log)
        checkInStore.recordPrayer()
    }
}

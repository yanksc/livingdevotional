// DailyVerseService - Manages Verse of the Day functionality

import Foundation
import Combine
import WidgetKit

class DailyVerseService: DailyVerseServiceProtocol {
    static let shared = DailyVerseService()
    
    private let bibleService: BibleService
    private let injectedAIService: AIServiceProtocol?
    private let userDefaults = UserDefaults.standard
    private let dailyVerseKey = "dailyVerse"
    private let dailyVerseDateKey = "dailyVerseDate"
    
    // Curated list of popular verses for Verse of the Day
    private let popularVerses: [(book: String, chapter: Int, verse: Int)] = [
        ("John", 3, 16),
        ("Philippians", 4, 13),
        ("Jeremiah", 29, 11),
        ("Romans", 8, 28),
        ("Psalms", 23, 1),
        ("Proverbs", 3, 5),
        ("Matthew", 6, 33),
        ("Isaiah", 40, 31),
        ("Joshua", 1, 9),
        ("Romans", 12, 2)
    ]
    
    // Lazy access to avoid circular dependency with ServiceContainer
    // Access ServiceContainer on main thread to ensure thread safety
    private var aiService: AIServiceProtocol? {
        if let injected = injectedAIService {
            return injected
        }
        // Access ServiceContainer safely - it's initialized on main thread
        return ServiceContainer.shared.aiService
    }
    
    init(bibleService: BibleService = .shared, aiService: AIServiceProtocol? = nil) {
        self.bibleService = bibleService
        self.injectedAIService = aiService
    }
    
    func getVerseOfTheDay(date: Date?) async throws -> DailyVerse {
        let targetDate = date ?? Date()
        
        // Check if we already have a verse for today stored locally
        // Use normalized date comparison to avoid timezone issues
        if let storedDate = userDefaults.object(forKey: dailyVerseDateKey) as? Date {
            let calendar = Calendar.current
            let storedDay = calendar.startOfDay(for: storedDate)
            let targetDay = calendar.startOfDay(for: targetDate)
            
            if storedDay == targetDay,
               let storedData = userDefaults.data(forKey: dailyVerseKey),
               let storedVerse = try? JSONDecoder().decode(DailyVerse.self, from: storedData) {
                // Validate cached verse has actual content for at least one translation
                if !storedVerse.textBsb.isEmpty || !storedVerse.textCuv.isEmpty || 
                   !storedVerse.textCu1.isEmpty || !storedVerse.textKjv.isEmpty ||
                   !storedVerse.textWeb.isEmpty || !storedVerse.textSpa.isEmpty ||
                   !storedVerse.textPor.isEmpty {
                    return storedVerse
                }
                // Cached verse has no content - clear cache and regenerate
                userDefaults.removeObject(forKey: dailyVerseKey)
                userDefaults.removeObject(forKey: dailyVerseDateKey)
            }
        }
        
        // Generate a new verse of the day
        return try await generateAndSaveDailyVerse(for: targetDate)
    }
    
    /// Seed a verse from onboarding as today's Verse of the Day.
    /// This ensures the user's first home screen shows the verse chosen for them during onboarding.
    /// Only seeds if no verse is already cached for today.
    func seedVerseFromOnboarding(verse: OnboardingRecommendedVerse) {
        // Don't overwrite an existing verse for today
        if let storedDate = userDefaults.object(forKey: dailyVerseDateKey) as? Date {
            let calendar = Calendar.current
            if calendar.isDateInToday(storedDate),
               userDefaults.data(forKey: dailyVerseKey) != nil {
                return
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        // Parse reference into book/chapter/verse (e.g. "Psalm 46:10" or "詩篇 46:10")
        let parts = verse.reference.components(separatedBy: CharacterSet(charactersIn: " :"))
        let book = parts.first ?? verse.reference
        let chapter = parts.count > 1 ? Int(parts[parts.count - 2]) ?? 1 : 1
        let verseNum = parts.count > 2 ? Int(parts.last ?? "1") ?? 1 : 1
        
        let backgroundImage = SereneBackgroundManager.shared.randomBackground()
        
        // Create a DailyVerse with the onboarding text in BSB (English) slot
        // The AI-generated text from onboarding may not match a specific translation,
        // so we put it in whichever translation slots make sense
        let dailyVerse = DailyVerse(
            book: book,
            chapter: chapter,
            verseNumber: verseNum,
            textBsb: verse.text,
            textCuv: verse.text,
            textCu1: verse.text,
            textKjv: verse.text,
            textWeb: verse.text,
            textSpa: verse.text,
            textPor: verse.text,
            reference: verse.reference,
            selectedDate: dateString,
            reason: verse.reason,
            source: "Chosen for you during onboarding",
            rationale: verse.reason,
            backgroundImage: backgroundImage
        )
        
        // Save to UserDefaults cache (same keys DailyVerseService reads)
        if let encoded = try? JSONEncoder().encode(dailyVerse) {
            userDefaults.set(encoded, forKey: dailyVerseKey)
            userDefaults.set(Date(), forKey: dailyVerseDateKey)
        }
    }
    
    /// Force refresh the verse of the day by clearing cache and regenerating
    func forceRefreshVerseOfTheDay() async throws -> DailyVerse {
        // Clear the cached verse
        userDefaults.removeObject(forKey: dailyVerseKey)
        userDefaults.removeObject(forKey: dailyVerseDateKey)
        
        // Generate a new verse
        return try await generateAndSaveDailyVerse(for: Date())
    }
    
    func getCuratedVerses(category: String?) async throws -> [CuratedVerse] {
        // Placeholder for future implementation
        return []
    }
    
    private func generateAndSaveDailyVerse(for date: Date) async throws -> DailyVerse {
        var selection: (book: String, chapter: Int, verse: Int)
        var reason: String?
        var source: String?
        
        // Check recent activity (last 48 hours)
        let twoDaysAgo = Date().addingTimeInterval(-48 * 3600)
        
        // Priority order: Prayer > Ask (Chat) > Note > Reading Plan > Reading History > Popular Verses
        
        // 1. Check recent Prayer (highest priority - most intimate activity)
        let recentPrayer = await MainActor.run {
            PrayerLogStore.shared.logs.first(where: { $0.date > twoDaysAgo })
        }
        
        // Get app language for localization
        let appLanguage = await MainActor.run {
            SettingsStore.shared.appLanguage
        }
        
        if let prayer = recentPrayer {
            // Use the verse from the prayer
            selection = (prayer.verseBook, prayer.verseChapter, prayer.verseNumber)
            let topicDisplay = prayer.customTopicText ?? prayer.topic
            reason = appLanguage.localizedString("FromYourPrayer").replacingOccurrences(of: "%@", with: topicDisplay)
            source = "Based on your prayer about \(topicDisplay)"
        } else {
            // 2. Check recent Chat/Ask (exploring questions)
            let recentChat = await MainActor.run {
                ChatStore.shared.sessions.first(where: { $0.updatedAt > twoDaysAgo && $0.book != nil && $0.chapter != nil && $0.verseNumber != nil })
            }
            
            if let chat = recentChat, let book = chat.book, let chapter = chat.chapter, let verse = chat.verseNumber {
                selection = (book, chapter, verse)
                // Extract topic from chat if available, otherwise use verse reference
                let chatTopic = chat.messages.first?.content ?? "\(book) \(chapter):\(verse)"
                reason = appLanguage.localizedString("BecauseYouAsked").replacingOccurrences(of: "%@", with: chatTopic)
                source = "Based on your conversation about \(book) \(chapter):\(verse)"
            } else {
                // 3. Check recent Saved Note
                let recentNote = await MainActor.run {
                    NoteStore.shared.savedVerses.first(where: { $0.timestamp > twoDaysAgo })
                }
                
                if let note = recentNote {
                    selection = (note.book, note.chapter, note.verse)
                    let noteRef = "\(note.book) \(note.chapter):\(note.verse)"
                    reason = appLanguage.localizedString("YouSavedNotes").replacingOccurrences(of: "%@", with: noteRef)
                    source = "From your notes on \(note.book) \(note.chapter):\(note.verse)"
                } else {
                    // 4. Check Active Reading Plan
                    let activePlan = await MainActor.run {
                        ReadingPlanStore.shared.getActivePlans().first
                    }
                    
                    if let (plan, _) = activePlan,
                       let currentDay = ReadingPlanStore.shared.getCurrentDay(for: plan.id) {
                        // Get first verse of the current reading day
                        let verseNum = currentDay.verseStart ?? 1
                        selection = (currentDay.book, currentDay.chapter, verseNum)
                        reason = appLanguage.localizedString("SinceYouRead").replacingOccurrences(of: "%@", with: plan.title)
                        source = "Today's reading: \(plan.title)"
                    } else {
                        // 5. Check Reading History
                        let recentHistory = await MainActor.run {
                            ProgressStore.shared.getRecentHistory(limit: 1).first
                        }
                        
                        if let history = recentHistory, history.timestamp > twoDaysAgo {
                            selection = (history.book, history.chapter, 1)
                            reason = appLanguage.localizedString("SinceYouRead").replacingOccurrences(of: "%@", with: history.book)
                            source = "Based on your reading in \(history.book)"
                        } else {
                            // 6. Fallback to Popular Verses
                            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
                            let index = dayOfYear % popularVerses.count
                            selection = popularVerses[index]
                            reason = "Daily inspiration"
                            source = nil
                        }
                    }
                }
            }
        }
        
        
        // Fetch verse range text from all translations (up to 4 consecutive verses)
        var textBsb = ""
        var textCuv = ""
        var textCu1 = ""
        var textKjv = ""
        var textWeb = ""
        var textSpa = ""
        var textPor = ""
        var endVerse = selection.verse
        
        // Load BSB (also determines the canonical verse range end)
        if let bsbVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .bsb) {
            let result = collectVerseRange(from: bsbVerses, startVerse: selection.verse) { $0.textBsb }
            textBsb = result.text
            if !result.text.isEmpty { endVerse = result.endVerse }
        }
        
        // Load CUV
        if let cuvVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .cuv) {
            textCuv = collectVerseRange(from: cuvVerses, startVerse: selection.verse) { $0.textCuv }.text
        }
        
        // Load CU1
        if let cu1Verses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .cu1) {
            textCu1 = collectVerseRange(from: cu1Verses, startVerse: selection.verse) { $0.textCu1 }.text
        }
        
        // Load KJV
        if let kjvVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .kjv) {
            textKjv = collectVerseRange(from: kjvVerses, startVerse: selection.verse) { $0.textKjv }.text
        }
        
        // Load WEB
        if let webVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .web) {
            textWeb = collectVerseRange(from: webVerses, startVerse: selection.verse) { $0.textWeb }.text
        }
        
        // Load Spanish
        if let spaVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .spa_r09) {
            textSpa = collectVerseRange(from: spaVerses, startVerse: selection.verse) { $0.textSpa }.text
        }
        
        // Load Portuguese
        if let porVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .por_blj) {
            textPor = collectVerseRange(from: porVerses, startVerse: selection.verse) { $0.textPor }.text
        }
        
        // If no verse found in any translation, try fallback to popular verses
        if textBsb.isEmpty && textCuv.isEmpty && textCu1.isEmpty && textKjv.isEmpty && textWeb.isEmpty && textSpa.isEmpty && textPor.isEmpty {
            // The selected verse failed to load - try fallback to popular verses
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
            
            // Try each popular verse until we find one that loads successfully
            for offset in 0..<popularVerses.count {
                let index = (dayOfYear + offset) % popularVerses.count
                let fallbackSelection = popularVerses[index]
                
                // Try to load this fallback verse range
                var fallbackLoaded = false
                var fallbackEndVerse = fallbackSelection.verse
                
                // Load BSB for fallback (also determines the canonical verse range end)
                if let bsbVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .bsb) {
                    let result = collectVerseRange(from: bsbVerses, startVerse: fallbackSelection.verse) { $0.textBsb }
                    if !result.text.isEmpty {
                        textBsb = result.text
                        fallbackEndVerse = result.endVerse
                        fallbackLoaded = true
                    }
                }
                
                // Load CUV for fallback
                if let cuvVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .cuv) {
                    let result = collectVerseRange(from: cuvVerses, startVerse: fallbackSelection.verse) { $0.textCuv }
                    if !result.text.isEmpty { textCuv = result.text; fallbackLoaded = true }
                }
                
                // Load CU1 for fallback
                if let cu1Verses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .cu1) {
                    let result = collectVerseRange(from: cu1Verses, startVerse: fallbackSelection.verse) { $0.textCu1 }
                    if !result.text.isEmpty { textCu1 = result.text; fallbackLoaded = true }
                }
                
                // Load KJV for fallback
                if let kjvVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .kjv) {
                    let result = collectVerseRange(from: kjvVerses, startVerse: fallbackSelection.verse) { $0.textKjv }
                    if !result.text.isEmpty { textKjv = result.text; fallbackLoaded = true }
                }
                
                // Load WEB for fallback
                if let webVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .web) {
                    let result = collectVerseRange(from: webVerses, startVerse: fallbackSelection.verse) { $0.textWeb }
                    if !result.text.isEmpty { textWeb = result.text; fallbackLoaded = true }
                }
                
                // Load Spanish for fallback
                if let spaVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .spa_r09) {
                    let result = collectVerseRange(from: spaVerses, startVerse: fallbackSelection.verse) { $0.textSpa }
                    if !result.text.isEmpty { textSpa = result.text; fallbackLoaded = true }
                }
                
                // Load Portuguese for fallback
                if let porVerses = try? await bibleService.loadVerses(book: fallbackSelection.book, chapter: fallbackSelection.chapter, translation: .por_blj) {
                    let result = collectVerseRange(from: porVerses, startVerse: fallbackSelection.verse) { $0.textPor }
                    if !result.text.isEmpty { textPor = result.text; fallbackLoaded = true }
                }
                
                if fallbackLoaded {
                    // Successfully loaded fallback verse range - update selection and end verse
                    selection = fallbackSelection
                    endVerse = fallbackEndVerse
                    reason = "Daily inspiration"
                    source = nil
                    break
                }
            }
            
            // If still no verse after trying all fallbacks, throw error
            if textBsb.isEmpty && textCuv.isEmpty && textCu1.isEmpty && textKjv.isEmpty && textWeb.isEmpty && textSpa.isEmpty && textPor.isEmpty {
                throw NSError(domain: "DailyVerseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Unable to load verse. Please check your Bible data."])
            }
        }
        
        // Get primary language text for rationale generation
        let primaryLanguage = await MainActor.run {
            SettingsStore.shared.primaryLanguage
        }
        let verseText: String
        switch primaryLanguage {
        case .bsb: verseText = textBsb
        case .cuv: verseText = textCuv
        case .cu1: verseText = textCu1
        case .kjv: verseText = textKjv
        case .web: verseText = textWeb
        case .spa_r09: verseText = textSpa
        case .por_blj: verseText = textPor
        case .none: verseText = textBsb.isEmpty ? textCuv : textBsb
        }
        
        // Generate rationale using AI if available and source exists
        var rationale: String? = nil
        if let aiService = aiService, let source = source, !verseText.isEmpty {
            let verseReference = endVerse > selection.verse
                ? "\(selection.book) \(selection.chapter):\(selection.verse)-\(endVerse)"
                : "\(selection.book) \(selection.chapter):\(selection.verse)"
            rationale = try? await aiService.generateVerseRationale(
                verseReference: verseReference,
                verseText: verseText,
                userAction: source,
                appLanguage: appLanguage
            )
        }
        
        // Select random background from SereneBackgroundManager
        let backgroundImage = SereneBackgroundManager.shared.randomBackground()
        
        // Create DailyVerse object
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let referenceString: String
        if endVerse > selection.verse {
            referenceString = "\(selection.book) \(selection.chapter):\(selection.verse)-\(endVerse)"
        } else {
            referenceString = "\(selection.book) \(selection.chapter):\(selection.verse)"
        }
        
        let dailyVerse = DailyVerse(
            book: selection.book,
            chapter: selection.chapter,
            verseNumber: selection.verse,
            verseNumberEnd: endVerse > selection.verse ? endVerse : nil,
            textBsb: textBsb,
            textCuv: textCuv,
            textCu1: textCu1,
            textKjv: textKjv,
            textWeb: textWeb,
            textSpa: textSpa,
            textPor: textPor,
            reference: referenceString,
            selectedDate: dateString,
            reason: reason,
            source: source,
            rationale: rationale,
            backgroundImage: backgroundImage
        )
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(dailyVerse) {
            userDefaults.set(encoded, forKey: dailyVerseKey)
            userDefaults.set(date, forKey: dailyVerseDateKey)
        }
        
        // Sync to widget
        await MainActor.run {
            WidgetDataSync.shared.syncVerseToWidget(verse: dailyVerse, language: primaryLanguage)
        }
        
        return dailyVerse
    }
    
    /// Collect up to `maxVerses` consecutive verses starting at `startVerse` from a pre-loaded array.
    /// Returns the joined text and the actual last verse number that was found.
    private func collectVerseRange(
        from verses: [BibleVerse],
        startVerse: Int,
        maxVerses: Int = 4,
        getText: (BibleVerse) -> String
    ) -> (text: String, endVerse: Int) {
        let endLimit = startVerse + maxVerses - 1
        let rangeVerses = verses
            .filter { $0.verseNumber >= startVerse && $0.verseNumber <= endLimit }
            .sorted { $0.verseNumber < $1.verseNumber }
        
        guard !rangeVerses.isEmpty else {
            return ("", startVerse)
        }
        
        let text = rangeVerses.map { getText($0) }.filter { !$0.isEmpty }.joined(separator: " ")
        let endVerse = rangeVerses.last?.verseNumber ?? startVerse
        return (text, endVerse)
    }
}

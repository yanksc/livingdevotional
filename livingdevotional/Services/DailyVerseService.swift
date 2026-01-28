// DailyVerseService - Manages Verse of the Day functionality

import Foundation
import Combine

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
        if let storedDate = userDefaults.object(forKey: dailyVerseDateKey) as? Date,
           Calendar.current.isDate(storedDate, inSameDayAs: targetDate),
           let storedData = userDefaults.data(forKey: dailyVerseKey),
           let storedVerse = try? JSONDecoder().decode(DailyVerse.self, from: storedData) {
            return storedVerse
        }
        
        // Generate a new verse of the day
        return try await generateAndSaveDailyVerse(for: targetDate)
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
        
        
        // Fetch verse text from all translations
        var textBsb = ""
        var textCuv = ""
        var textCu1 = ""
        var textKjv = ""
        var textWeb = ""
        var textSpa = ""
        var textPor = ""
        
        // Load BSB
        if let bsbVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .bsb),
           let verse = bsbVerses.first(where: { $0.verseNumber == selection.verse }) {
            textBsb = verse.textBsb
        }
        
        // Load CUV
        if let cuvVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .cuv),
           let verse = cuvVerses.first(where: { $0.verseNumber == selection.verse }) {
            textCuv = verse.textCuv
        }
        
        // Load CU1
        if let cu1Verses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .cu1),
           let verse = cu1Verses.first(where: { $0.verseNumber == selection.verse }) {
            textCu1 = verse.textCu1
        }
        
        // Load KJV
        if let kjvVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .kjv),
           let verse = kjvVerses.first(where: { $0.verseNumber == selection.verse }) {
            textKjv = verse.textKjv
        }
        
        // Load WEB
        if let webVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .web),
           let verse = webVerses.first(where: { $0.verseNumber == selection.verse }) {
            textWeb = verse.textWeb
        }
        
        // Load Spanish
        if let spaVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .spa_r09),
           let verse = spaVerses.first(where: { $0.verseNumber == selection.verse }) {
            textSpa = verse.textSpa
        }
        
        // Load Portuguese
        if let porVerses = try? await bibleService.loadVerses(book: selection.book, chapter: selection.chapter, translation: .por_blj),
           let verse = porVerses.first(where: { $0.verseNumber == selection.verse }) {
            textPor = verse.textPor
        }
        
        // If no verse found in any translation, try to fallback to default logic if it was a dynamic selection
        // But if even popular verses fail, throw error.
        if textBsb.isEmpty && textCuv.isEmpty && textCu1.isEmpty && textKjv.isEmpty && textWeb.isEmpty && textSpa.isEmpty && textPor.isEmpty {
             // If we tried a dynamic selection and it failed (maybe verse doesn't exist?), fallback to popular list
             let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
             let index = dayOfYear % popularVerses.count
             let fallbackSelection = popularVerses[index]
             
             // Recursively try one more time with fallback? Or just fail?
             // Let's just throw for now to avoid complexity in this snippet
            throw NSError(domain: "DailyVerseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Verse not found"])
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
            let verseReference = "\(selection.book) \(selection.chapter):\(selection.verse)"
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
        
        let dailyVerse = DailyVerse(
            book: selection.book,
            chapter: selection.chapter,
            verseNumber: selection.verse,
            textBsb: textBsb,
            textCuv: textCuv,
            textCu1: textCu1,
            textKjv: textKjv,
            textWeb: textWeb,
            textSpa: textSpa,
            textPor: textPor,
            reference: "\(selection.book) \(selection.chapter):\(selection.verse)",
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
        
        return dailyVerse
    }
}

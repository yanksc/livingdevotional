// JourneyService - Manages user journey analytics and milestones
//
// Aggregates data from multiple stores to provide a holistic view of user progress.

import Foundation
import Combine

class JourneyService: JourneyServiceProtocol {
    static let shared = JourneyService()
    
    private let progressStore: ProgressStore
    private let noteStore: NoteStore
    private let checkInStore: CheckInStore
    private let chatStore: ChatStore
    private let userProfileStore: UserProfileStore
    private let prayerLogStore: PrayerLogStore
    
    // Cache for AI analysis to avoid repeated API calls
    private var cachedAnalysis: AIJourneyAnalysis?
    private var cachedSnapshot: ActivitySnapshot?
    private let activityThreshold: Int = 3 // Regenerate after 3+ new activities
    private let userDefaults = UserDefaults.standard
    
    private struct PersistedJourneyCache: Codable {
        let analysis: AIJourneyAnalysis
        let snapshot: ActivitySnapshot
    }
    
    private func persistedCacheKey(appLanguage: AppLanguage) -> String {
        "journeyAnalysis_\(appLanguage.rawValue)"
    }
    
    var hasValidCache: Bool {
        guard let cached = cachedAnalysis,
              let snapshot = cachedSnapshot else {
            return false
        }
        
        // Build current snapshot
        let currentChapters = progressStore.readingHistory.count
        let currentVerses = noteStore.savedVerses.count
        let currentQuestions = chatStore.sessions.reduce(0) { count, session in
            count + session.messages.filter { $0.role == .user }.count
        }
        let currentPrayers = prayerLogStore.getAllLogs().count
        
        // Calculate total activity delta
        let delta = abs(currentChapters - snapshot.chaptersRead) +
                   abs(currentVerses - snapshot.versesSaved) +
                   abs(currentQuestions - snapshot.questionsAsked) +
                   abs(currentPrayers - snapshot.prayerCount)
        
        return delta < activityThreshold
    }
    
    init(
        progressStore: ProgressStore = .shared,
        noteStore: NoteStore = .shared,
        checkInStore: CheckInStore = .shared,
        chatStore: ChatStore = .shared,
        userProfileStore: UserProfileStore = .shared,
        prayerLogStore: PrayerLogStore = .shared
    ) {
        self.progressStore = progressStore
        self.noteStore = noteStore
        self.checkInStore = checkInStore
        self.chatStore = chatStore
        self.userProfileStore = userProfileStore
        self.prayerLogStore = prayerLogStore
    }
    
    func getJourneyStats() async throws -> JourneyStats {
        // Calculate questions count safely
        let questionsCount = chatStore.sessions.reduce(0) { count, session in
            count + session.messages.filter { $0.role == .user }.count
        }
        
        return JourneyStats(
            totalChaptersRead: progressStore.readingHistory.count,
            totalVersesSaved: noteStore.savedVerses.count,
            currentStreak: checkInStore.currentStreak,
            questionsAsked: questionsCount
        )
    }
    
    func getMilestones(limit: Int) async throws -> [JourneyMilestone] {
        var milestones: [JourneyMilestone] = []
        
        // 1. Reading History Milestones
        let readingMilestones = progressStore.readingHistory.map { item in
            JourneyMilestone(
                type: .reading,
                title: "Read \(item.book) \(item.chapter)",
                description: "Completed reading chapter",
                date: item.timestamp,
                iconName: "book.fill"
            )
        }
        milestones.append(contentsOf: readingMilestones)
        
        // 2. Saved Notes
        let noteMilestones = noteStore.savedVerses.map { note in
            JourneyMilestone(
                type: .note,
                title: "Saved \(note.book) \(note.chapter):\(note.verse)",
                description: note.content.isEmpty ? "Saved a verse" : "Added a note: \(note.content)",
                date: note.timestamp,
                iconName: "bookmark.fill"
            )
        }
        milestones.append(contentsOf: noteMilestones)
        
        // 3. Chat sessions (Questions)
        let chatMilestones = chatStore.sessions.map { session in
            let book = session.book ?? "Bible"
            let chapter = session.chapter ?? 1
            let verseNumber = session.verseNumber ?? 1
            return JourneyMilestone(
                type: .question,
                title: "Asked about \(book) \(chapter):\(verseNumber)",
                description: session.title,
                date: session.updatedAt,
                iconName: "bubble.left.and.bubble.right.fill"
            )
        }
        milestones.append(contentsOf: chatMilestones)
        
        // 4. Prayer logs
        let prayerMilestones = prayerLogStore.getAllLogs().map { log in
            let topicDisplay: String
            if log.topic == "custom", let customText = log.customTopicText {
                topicDisplay = customText
            } else {
                topicDisplay = log.topic.capitalized
            }
            
            return JourneyMilestone(
                type: .prayer,
                title: "Prayed for \(topicDisplay)",
                description: "Used \(log.verseReference)",
                date: log.date,
                iconName: "hands.sparkles.fill"
            )
        }
        milestones.append(contentsOf: prayerMilestones)
        
        // Sort by date descending and take top N
        return Array(milestones.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    func getDailyInsight() async throws -> JourneyInsight {
        // Simple logic for MVP: Rotate based on data
        let stats = try await getJourneyStats()
        
        // Prioritize encouraging streak if active
        if stats.currentStreak >= 3 {
             return JourneyInsight(
                title: "Momentum Building!",
                content: "You've been consistent for \(stats.currentStreak) days. Keep it up!",
                type: .encouragement,
                date: Date()
            )
        } 
        // Then highlight engagement
        else if stats.totalVersesSaved > 5 {
             return JourneyInsight(
                title: "Verse Collector",
                content: "You've saved \(stats.totalVersesSaved) verses. Review them to refresh your memory.",
                type: .stat,
                date: Date()
            )
        } 
        else if stats.totalChaptersRead > 10 {
            return JourneyInsight(
                title: "Faithful Reader",
                content: "You've read \(stats.totalChaptersRead) chapters. What's been your favorite?",
                type: .pattern,
                date: Date()
            )
        }
        // Default welcome
        else {
             return JourneyInsight(
                title: "Start Your Journey",
                content: "Your journey begins with a single step. Try reading a chapter today.",
                type: .encouragement,
                date: Date()
            )
        }
    }
    
    // MARK: - AI Journey Analysis
    
    func getPersistedAnalysisIfValid(appLanguage: AppLanguage) -> AIJourneyAnalysis? {
        guard let cache = loadPersistedCache(appLanguage: appLanguage),
              isPersistedCacheValid(cache.snapshot) else {
            return nil
        }
        cachedAnalysis = cache.analysis
        cachedSnapshot = cache.snapshot
        return cache.analysis
    }
    
    func getAIJourneyAnalysis(appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        // Check in-memory cache first
        if let cached = cachedAnalysis, hasValidCache {
            return cached
        }
        
        // Check persisted cache (survives app restart)
        if let persisted = loadPersistedCache(appLanguage: appLanguage),
           isPersistedCacheValid(persisted.snapshot) {
            cachedAnalysis = persisted.analysis
            cachedSnapshot = persisted.snapshot
            return persisted.analysis
        }
        
        // Get AI service
        guard let aiService = ServiceContainer.shared.aiService else {
            throw NSError(domain: "JourneyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service not available"])
        }
        
        // Collect all data for AI analysis
        let dataForAI = try await collectDataForAI()
        
        // Call AI service
        let analysis = try await aiService.analyzeJourney(data: dataForAI, appLanguage: appLanguage)
        
        // Cache the result and snapshot (in-memory)
        cachedAnalysis = analysis
        
        // Save current activity counts as snapshot
        let currentChapters = progressStore.readingHistory.count
        let currentVerses = noteStore.savedVerses.count
        let currentQuestions = chatStore.sessions.reduce(0) { count, session in
            count + session.messages.filter { $0.role == .user }.count
        }
        let currentPrayers = prayerLogStore.getAllLogs().count
        
        cachedSnapshot = ActivitySnapshot(
            chaptersRead: currentChapters,
            versesSaved: currentVerses,
            questionsAsked: currentQuestions,
            prayerCount: currentPrayers
        )
        
        // Persist to UserDefaults for instant load on app reopen
        savePersistedCache(
            analysis: analysis,
            snapshot: cachedSnapshot!,
            appLanguage: appLanguage
        )
        
        return analysis
    }
    
    // Force refresh the AI analysis (ignore cache)
    func refreshAIAnalysis(appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        cachedAnalysis = nil
        cachedSnapshot = nil
        clearPersistedCache(appLanguage: appLanguage)
        return try await getAIJourneyAnalysis(appLanguage: appLanguage)
    }
    
    // MARK: - Private Helpers
    
    private func isPersistedCacheValid(_ snapshot: ActivitySnapshot) -> Bool {
        let currentChapters = progressStore.readingHistory.count
        let currentVerses = noteStore.savedVerses.count
        let currentQuestions = chatStore.sessions.reduce(0) { count, session in
            count + session.messages.filter { $0.role == .user }.count
        }
        let currentPrayers = prayerLogStore.getAllLogs().count
        let delta = abs(currentChapters - snapshot.chaptersRead) +
            abs(currentVerses - snapshot.versesSaved) +
            abs(currentQuestions - snapshot.questionsAsked) +
            abs(currentPrayers - snapshot.prayerCount)
        return delta < activityThreshold
    }
    
    private func savePersistedCache(analysis: AIJourneyAnalysis, snapshot: ActivitySnapshot, appLanguage: AppLanguage) {
        let cache = PersistedJourneyCache(analysis: analysis, snapshot: snapshot)
        guard let encoded = try? JSONEncoder().encode(cache) else { return }
        userDefaults.set(encoded, forKey: persistedCacheKey(appLanguage: appLanguage))
    }
    
    private func loadPersistedCache(appLanguage: AppLanguage) -> PersistedJourneyCache? {
        guard let data = userDefaults.data(forKey: persistedCacheKey(appLanguage: appLanguage)),
              let decoded = try? JSONDecoder().decode(PersistedJourneyCache.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    private func clearPersistedCache(appLanguage: AppLanguage) {
        userDefaults.removeObject(forKey: persistedCacheKey(appLanguage: appLanguage))
    }
    
    private func collectDataForAI() async throws -> JourneyDataForAI {
        let stats = try await getJourneyStats()
        let profile = userProfileStore.profile
        let settingsStore = SettingsStore.shared
        let bibleService = BibleService.shared
        let primaryLanguage = settingsStore.primaryLanguage
        
        // Build detailed reading history with recent 10 entries (book + chapter + date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        let detailedReadingHistory = progressStore.readingHistory.prefix(10).map { item -> String in
            let daysAgo = Calendar.current.dateComponents([.day], from: item.timestamp, to: Date()).day ?? 0
            let dateStr: String
            if daysAgo == 0 {
                dateStr = settingsStore.appLanguage == .chineseTraditional ? "今天" : "today"
            } else if daysAgo == 1 {
                dateStr = settingsStore.appLanguage == .chineseTraditional ? "昨天" : "yesterday"
            } else if daysAgo < 7 {
                dateStr = settingsStore.appLanguage == .chineseTraditional ? "\(daysAgo)天前" : "\(daysAgo) days ago"
            } else {
                dateStr = dateFormatter.string(from: item.timestamp)
            }
            return "\(item.book) \(item.chapter) (\(dateStr))"
        }
        
        // Extract books where verses were saved
        let savedBooks = Array(Set(noteStore.savedVerses.map { $0.book }))
        
        // Extract all labels used
        let allLabels = Array(Set(noteStore.savedVerses.flatMap { $0.labels }))
        
        // Helper function to get verse text
        func getVerseText(book: String, chapter: Int, verse: Int) async -> String {
            do {
                let verses = try await bibleService.loadVerses(book: book, chapter: chapter, translation: primaryLanguage)
                if let verse = verses.first(where: { $0.verseNumber == verse }) {
                    return verse.text(for: primaryLanguage)
                }
            } catch {
                // If verse loading fails, return empty string
            }
            return ""
        }
        
        // Priority 1: Custom prayers with verse context
        var customPrayers: [IntentionalAction] = []
        let customPrayerLogs = prayerLogStore.getAllLogs().filter { $0.topic == "custom" && $0.customTopicText != nil }
        for log in customPrayerLogs.prefix(10) {
            let verseText = await getVerseText(book: log.verseBook, chapter: log.verseChapter, verse: log.verseNumber)
            let metadata = log.emotionalNeed != nil ? "Emotional need: \(log.emotionalNeed!)" : nil
            customPrayers.append(IntentionalAction(
                type: "customPrayer",
                verseReference: log.verseReference,
                verseText: verseText,
                content: log.customTopicText,
                metadata: metadata,
                date: log.date
            ))
        }
        
        // Priority 2: Prayer topics with verse context
        var prayerTopics: [IntentionalAction] = []
        let topicPrayerLogs = prayerLogStore.getAllLogs().filter { $0.topic != "custom" }
        for log in topicPrayerLogs.prefix(10) {
            let verseText = await getVerseText(book: log.verseBook, chapter: log.verseChapter, verse: log.verseNumber)
            prayerTopics.append(IntentionalAction(
                type: "prayerTopic",
                verseReference: log.verseReference,
                verseText: verseText,
                content: log.topic.capitalized,
                metadata: log.emotionalNeed != nil ? "Emotional need: \(log.emotionalNeed!)" : nil,
                date: log.date
            ))
        }
        
        // Priority 3: Questions with verse context
        var questions: [IntentionalAction] = []
        for session in chatStore.sessions.prefix(10) {
            let book = session.book ?? "Bible"
            let chapter = session.chapter ?? 1
            let verseNumber = session.verseNumber ?? 1
            let verseText = await getVerseText(book: book, chapter: chapter, verse: verseNumber)
            let questionText = session.messages.first(where: { $0.role == .user })?.content ?? session.title
            questions.append(IntentionalAction(
                type: "question",
                verseReference: "\(book) \(chapter):\(verseNumber)",
                verseText: verseText,
                content: questionText,
                metadata: nil,
                date: session.updatedAt
            ))
        }
        
        // Priority 4: Saved notes with note content
        var savedNotesWithContent: [IntentionalAction] = []
        // Priority 5: Saved notes without content
        var savedNotesWithoutContent: [IntentionalAction] = []
        
        for savedVerse in noteStore.savedVerses.prefix(20) {
            let verseText = await getVerseText(book: savedVerse.book, chapter: savedVerse.chapter, verse: savedVerse.verse)
            let labelsStr = savedVerse.labels.isEmpty ? nil : "Labels: \(savedVerse.labels.joined(separator: ", "))"
            
            if !savedVerse.content.isEmpty {
                savedNotesWithContent.append(IntentionalAction(
                    type: "savedNote",
                    verseReference: savedVerse.verseReference,
                    verseText: verseText,
                    content: savedVerse.content,
                    metadata: labelsStr,
                    date: savedVerse.timestamp
                ))
            } else {
                savedNotesWithoutContent.append(IntentionalAction(
                    type: "savedNote",
                    verseReference: savedVerse.verseReference,
                    verseText: verseText,
                    content: nil,
                    metadata: labelsStr,
                    date: savedVerse.timestamp
                ))
            }
        }
        
        // Collect all actions and sort by date to get the most recent 5
        var allActions: [IntentionalAction] = []
        allActions.append(contentsOf: customPrayers)
        allActions.append(contentsOf: prayerTopics)
        allActions.append(contentsOf: questions)
        allActions.append(contentsOf: savedNotesWithContent)
        allActions.append(contentsOf: savedNotesWithoutContent)
        
        // Sort by date descending and take the 5 most recent
        let recentActions = Array(allActions.sorted { $0.date > $1.date }.prefix(5))
        
        // Calculate total active days
        let totalDaysActive = checkInStore.dailyRecords.count
        
        return JourneyDataForAI(
            stats: stats,
            readingHistory: detailedReadingHistory,
            customPrayers: customPrayers,
            prayerTopics: prayerTopics,
            questions: questions,
            savedNotesWithContent: savedNotesWithContent,
            savedNotesWithoutContent: savedNotesWithoutContent,
            recentActions: recentActions,
            savedVerseBooks: savedBooks,
            savedVerseLabels: allLabels,
            currentStreak: stats.currentStreak,
            totalDaysActive: totalDaysActive,
            userName: profile.name,
            spiritualMaturity: profile.spiritualMaturity.displayName,
            spiritualGoals: profile.spiritualGoals.map { $0.displayName }
        )
    }
}

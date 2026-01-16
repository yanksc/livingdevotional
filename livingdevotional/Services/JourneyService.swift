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
    private var lastAnalysisDate: Date?
    private let cacheExpirationHours: Int = 6 // Refresh every 6 hours
    
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
            JourneyMilestone(
                type: .question,
                title: "Asked about \(session.book) \(session.chapter):\(session.verseNumber)",
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
    
    func getAIJourneyAnalysis(appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        // Check cache first
        if let cached = cachedAnalysis,
           let lastDate = lastAnalysisDate,
           Date().timeIntervalSince(lastDate) < Double(cacheExpirationHours * 3600) {
            return cached
        }
        
        // Get AI service
        guard let aiService = ServiceContainer.shared.aiService else {
            throw NSError(domain: "JourneyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service not available"])
        }
        
        // Collect all data for AI analysis
        let dataForAI = try await collectDataForAI()
        
        // Call AI service
        let analysis = try await aiService.analyzeJourney(data: dataForAI, appLanguage: appLanguage)
        
        // Cache the result
        cachedAnalysis = analysis
        lastAnalysisDate = Date()
        
        return analysis
    }
    
    // Force refresh the AI analysis (ignore cache)
    func refreshAIAnalysis(appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        cachedAnalysis = nil
        lastAnalysisDate = nil
        return try await getAIJourneyAnalysis(appLanguage: appLanguage)
    }
    
    // MARK: - Private Helpers
    
    private func collectDataForAI() async throws -> JourneyDataForAI {
        let stats = try await getJourneyStats()
        let profile = userProfileStore.profile
        
        // Extract unique books from reading history
        let readingBooks = Array(Set(progressStore.readingHistory.map { $0.book }))
        
        // Extract books where verses were saved
        let savedBooks = Array(Set(noteStore.savedVerses.map { $0.book }))
        
        // Extract all labels used
        let allLabels = Array(Set(noteStore.savedVerses.flatMap { $0.labels }))
        
        // Extract question topics (from chat session titles/content)
        let questionTopics = chatStore.sessions.prefix(10).compactMap { session -> String? in
            // Get the first user message as the topic
            if let firstQuestion = session.messages.first(where: { $0.role == .user })?.content {
                // Truncate to first 50 chars
                return String(firstQuestion.prefix(50))
            }
            return "\(session.book) \(session.chapter):\(session.verseNumber)"
        }
        
        // Extract prayer topics
        let prayerTopics = prayerLogStore.getAllLogs().prefix(20).map { log -> String in
            if log.topic == "custom", let customText = log.customTopicText {
                return customText
            } else {
                return log.topic
            }
        }
        
        // Calculate total active days
        let totalDaysActive = checkInStore.dailyRecords.count
        
        return JourneyDataForAI(
            stats: stats,
            readingHistory: readingBooks,
            savedVerseBooks: savedBooks,
            savedVerseLabels: allLabels,
            questionTopics: Array(questionTopics),
            prayerTopics: Array(prayerTopics),
            currentStreak: stats.currentStreak,
            totalDaysActive: totalDaysActive,
            userName: profile.name,
            spiritualMaturity: profile.spiritualMaturity.displayName,
            spiritualGoals: profile.spiritualGoals.map { $0.displayName }
        )
    }
}

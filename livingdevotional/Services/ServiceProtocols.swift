// ServiceProtocols - Protocol definitions for service layer

import Foundation

// MARK: - Authentication Service Protocol

protocol AuthenticationServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    
    func login(email: String, password: String) async throws -> User
    func signup(email: String, password: String, name: String) async throws -> User
    func logout() async throws
    func refreshToken() async throws
}

// MARK: - AI Service Protocol

protocol AIServiceProtocol {
    func explainVerse(book: String, chapter: Int, verse: Int, verseText: String, language: Language, mode: AIMode, appLanguage: AppLanguage, conversationHistory: [ChatMessage]?, userPrompt: String?) async throws -> AsyncThrowingStream<String, Error>
    func findRelatedVerses(book: String, chapter: Int, verse: Int, text: String, appLanguage: AppLanguage) async throws -> [RelatedVerse]
    func searchVerses(query: String, appLanguage: AppLanguage) async throws -> VerseSearchResponse
    func searchMoreVerses(query: String, excludeReferences: [String], appLanguage: AppLanguage) async throws -> VerseSearchResponse
    func askQuestion(question: String, context: String?) async throws -> String
    func summarizeChapter(book: String, chapter: Int, language: Language) async throws -> String
    func summarizeChapterStream(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error>
    func getChapterContext(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error>
    func searchBible(query: String, language: Language) async throws -> [SearchResult]
    func findVerseForPrayer(focus: String, need: String, language: Language, appLanguage: AppLanguage) async throws -> DailyVerse
    func generateVerseRationale(verseReference: String, verseText: String, userAction: String, appLanguage: AppLanguage) async throws -> String
    func analyzeJourney(data: JourneyDataForAI, appLanguage: AppLanguage) async throws -> AIJourneyAnalysis
    func chatGeneral(appLanguage: AppLanguage, conversationHistory: [ChatMessage], userQuestion: String) async throws -> AsyncThrowingStream<String, Error>
    func generatePersonalizedPlanQuestions(profile: UserProfile, history: AIService.UserHistoryContext?, appLanguage: AppLanguage) async throws -> [AIService.PlanQuestion]
    func generateReadingPlan(answers: [String: String], profile: UserProfile, appLanguage: AppLanguage) async throws -> ReadingPlan
}

// MARK: - User Service Protocol

protocol UserServiceProtocol {
    func getUserProfile() async throws -> APIUserProfile
    func updateUserProfile(_ profile: APIUserProfile) async throws
    func getUserBookmarks() async throws -> [VerseBookmark]
    func getUserProgress() async throws -> ReadingProgress
}

// MARK: - Daily Verse Service Protocol

protocol DailyVerseServiceProtocol {
    func getVerseOfTheDay(date: Date?) async throws -> DailyVerse
    func getCuratedVerses(category: String?) async throws -> [CuratedVerse]
    func forceRefreshVerseOfTheDay() async throws -> DailyVerse
}

// MARK: - Conversation Service Protocol

protocol ConversationServiceProtocol {
    func saveConversation(_ conversation: VerseConversation) async throws
    func getConversations(book: String, chapter: Int, verse: Int) async throws -> [VerseConversation]
    func deleteConversation(id: String) async throws
}

// MARK: - Check-in Service Protocol

protocol CheckInServiceProtocol {
    func saveCheckIn(_ checkIn: DailyCheckIn) async throws
    func getCheckIns(startDate: Date, endDate: Date) async throws -> [DailyCheckIn]
    func getCheckInStats() async throws -> CheckInStats
}

// MARK: - Journey Service Protocol

protocol JourneyServiceProtocol {
    var hasValidCache: Bool { get }
    func getJourneyStats() async throws -> JourneyStats
    func getMilestones(limit: Int) async throws -> [JourneyMilestone]
    func getDailyInsight() async throws -> JourneyInsight
    func getAIJourneyAnalysis(appLanguage: AppLanguage) async throws -> AIJourneyAnalysis
}

// MARK: - Supporting Types

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date
}

struct APIUserProfile: Codable {
    let userId: String
    var name: String?
    var avatarUrl: String?
    var preferences: UserPreferences
}

struct CheckInStats: Codable {
    let totalDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let lastCheckInDate: Date?
}

// MARK: - Journey Models

enum JourneyMilestoneType: String, Codable {
    case streak
    case reading
    case note
    case prayer
    case question
    case other
}

struct JourneyMilestone: Codable, Identifiable {
    let id: String
    let type: JourneyMilestoneType
    let title: String
    let description: String
    let date: Date
    let iconName: String
    
    // Helper for initialization
    init(id: String = UUID().uuidString, type: JourneyMilestoneType, title: String, description: String, date: Date, iconName: String) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.date = date
        self.iconName = iconName
    }
}

struct JourneyStats: Codable {
    let totalChaptersRead: Int
    let totalVersesSaved: Int
    let currentStreak: Int
    let questionsAsked: Int
}

struct JourneyInsight: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let type: InsightType
    let date: Date
    
    enum InsightType: String, Codable {
        case stat
        case encouragement
        case pattern
    }
    
    init(id: String = UUID().uuidString, title: String, content: String, type: InsightType, date: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.date = date
    }
}

// MARK: - AI Journey Analysis Models

struct AIJourneyAnalysis: Codable, Identifiable {
    let id: String
    let encouragement: String
    let journeySummary: String
    let pathStatus: PathStatus
    let recommendedVerse: RecommendedVerse?
    let pathHighlights: [PathHighlight]
    let nextStep: String
    let generatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        encouragement: String,
        journeySummary: String,
        pathStatus: PathStatus,
        recommendedVerse: RecommendedVerse?,
        pathHighlights: [PathHighlight],
        nextStep: String,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.encouragement = encouragement
        self.journeySummary = journeySummary
        self.pathStatus = pathStatus
        self.recommendedVerse = recommendedVerse
        self.pathHighlights = pathHighlights
        self.nextStep = nextStep
        self.generatedAt = generatedAt
    }
}

struct PathStatus: Codable {
    let title: String
    let description: String
    let iconName: String
    
    init(title: String, description: String, iconName: String) {
        self.title = title
        self.description = description
        self.iconName = iconName
    }
}

struct RecommendedVerse: Codable {
    let reference: String
    let text: String
    let reason: String
    
    init(reference: String, text: String, reason: String) {
        self.reference = reference
        self.text = text
        self.reason = reason
    }
}

struct PathHighlight: Codable, Identifiable {
    let id: String
    let emoji: String
    let fact: String
    
    init(id: String = UUID().uuidString, emoji: String, fact: String) {
        self.id = id
        self.emoji = emoji
        self.fact = fact
    }
}

// Input data structure for AI analysis
struct JourneyDataForAI {
    let stats: JourneyStats
    let readingHistory: [String] // Book names read (low priority)
    
    // Priority 1: Custom prayers with verse context
    let customPrayers: [IntentionalAction]
    
    // Priority 2: Prayer topics with verse context
    let prayerTopics: [IntentionalAction]
    
    // Priority 3: Questions with verse context
    let questions: [IntentionalAction]
    
    // Priority 4: Saved notes with note content
    let savedNotesWithContent: [IntentionalAction]
    
    // Priority 5: Saved notes without content (just verse reference)
    let savedNotesWithoutContent: [IntentionalAction]
    
    // Recent 5 actions (most important for status generation)
    let recentActions: [IntentionalAction]
    
    // Additional metadata
    let savedVerseBooks: [String] // Books where verses were saved
    let savedVerseLabels: [String] // Labels used
    let currentStreak: Int
    let totalDaysActive: Int
    let userName: String
    let spiritualMaturity: String
    let spiritualGoals: [String]
}

// Represents an intentional user action with verse context
struct IntentionalAction: Codable {
    let type: String // "customPrayer", "prayerTopic", "question", "savedNote"
    let verseReference: String // e.g., "John 3:16"
    let verseText: String // Actual verse text
    let content: String? // Custom topic, question text, or note content
    let metadata: String? // Additional context like emotional need, labels, etc.
    let date: Date
}






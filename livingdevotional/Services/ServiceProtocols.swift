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
    func askQuestion(question: String, context: String?) async throws -> String
    func summarizeChapter(book: String, chapter: Int, language: Language) async throws -> String
    func summarizeChapterStream(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error>
    func getChapterContext(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error>
    func searchBible(query: String, language: Language) async throws -> [SearchResult]
    func findVerseForPrayer(focus: String, need: String, language: Language, appLanguage: AppLanguage) async throws -> DailyVerse
    func analyzeJourney(data: JourneyDataForAI, appLanguage: AppLanguage) async throws -> AIJourneyAnalysis
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
    let readingPersonality: ReadingPersonality
    let recommendedVerse: RecommendedVerse?
    let funFacts: [FunFact]
    let nextStep: String
    let generatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        encouragement: String,
        journeySummary: String,
        readingPersonality: ReadingPersonality,
        recommendedVerse: RecommendedVerse?,
        funFacts: [FunFact],
        nextStep: String,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.encouragement = encouragement
        self.journeySummary = journeySummary
        self.readingPersonality = readingPersonality
        self.recommendedVerse = recommendedVerse
        self.funFacts = funFacts
        self.nextStep = nextStep
        self.generatedAt = generatedAt
    }
}

struct ReadingPersonality: Codable {
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

struct FunFact: Codable, Identifiable {
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
    let readingHistory: [String] // Book names read
    let savedVerseBooks: [String] // Books where verses were saved
    let savedVerseLabels: [String] // Labels used
    let questionTopics: [String] // Topics from Q&A
    let prayerTopics: [String] // Topics from prayer logs
    let currentStreak: Int
    let totalDaysActive: Int
    let userName: String
    let spiritualMaturity: String
    let spiritualGoals: [String]
}






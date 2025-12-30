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
    func explainVerse(book: String, chapter: Int, verse: Int, language: Language) async throws -> String
    func findRelatedVerses(book: String, chapter: Int, verse: Int) async throws -> [RelatedVerse]
    func askQuestion(question: String, context: String?) async throws -> String
    func summarizeChapter(book: String, chapter: Int, language: Language) async throws -> String
    func searchBible(query: String, language: Language) async throws -> [SearchResult]
}

// MARK: - User Service Protocol

protocol UserServiceProtocol {
    func getUserProfile() async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws
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

// MARK: - Supporting Types

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date
}

struct UserProfile: Codable {
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


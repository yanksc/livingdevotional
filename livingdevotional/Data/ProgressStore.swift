// ProgressStore - Manages reading progress using UserDefaults

import Foundation
import Combine

struct ReadingProgressData: Codable {
    let book: String
    let chapter: Int
    let lastReadAt: Date
}

struct ReadingHistoryItem: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let timestamp: Date
    
    init(book: String, chapter: Int, timestamp: Date = Date()) {
        self.id = UUID().uuidString
        self.book = book
        self.chapter = chapter
        self.timestamp = timestamp
    }
}

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "readingProgress"
    private let historyKey = "readingHistory"
    private let readChaptersKey = "readChapters"
    private let maxHistoryItems = 50
    
    @Published var currentBook: String?
    @Published var currentChapter: Int?
    @Published var readingHistory: [ReadingHistoryItem] = []
    @Published var readChapters: Set<String> = []
    
    private init() {
        loadProgress()
        loadHistory()
        loadReadChapters()
    }
    
    // MARK: - Read Chapters Management
    
    private func chapterKey(book: String, chapter: Int) -> String {
        return "\(book):\(chapter)"
    }
    
    func markChapterAsRead(book: String, chapter: Int) {
        let key = chapterKey(book: book, chapter: chapter)
        readChapters.insert(key)
        saveReadChapters()
    }
    
    func isChapterRead(book: String, chapter: Int) -> Bool {
        let key = chapterKey(book: book, chapter: chapter)
        return readChapters.contains(key)
    }
    
    private func loadReadChapters() {
        if let data = userDefaults.data(forKey: readChaptersKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            readChapters = Set(decoded)
        } else {
            // If no saved set exists, build it from reading history
            readChapters = Set(readingHistory.map { chapterKey(book: $0.book, chapter: $0.chapter) })
        }
    }
    
    private func saveReadChapters() {
        let array = Array(readChapters)
        if let encoded = try? JSONEncoder().encode(array) {
            userDefaults.set(encoded, forKey: readChaptersKey)
        }
    }
    
    func saveProgress(book: String, chapter: Int) {
        let progress = ReadingProgressData(
            book: book,
            chapter: chapter,
            lastReadAt: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(progress) {
            userDefaults.set(encoded, forKey: progressKey)
            currentBook = book
            currentChapter = chapter
        }
        
        // Add to reading history
        addToHistory(book: book, chapter: chapter)
    }
    
    func loadProgress() {
        guard let data = userDefaults.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode(ReadingProgressData.self, from: data) else {
            currentBook = nil
            currentChapter = nil
            return
        }
        
        currentBook = progress.book
        currentChapter = progress.chapter
    }
    
    func clearProgress() {
        userDefaults.removeObject(forKey: progressKey)
        currentBook = nil
        currentChapter = nil
    }
    
    // MARK: - Reading History Management
    
    private func addToHistory(book: String, chapter: Int) {
        // Remove any existing entry for the same book/chapter to avoid duplicates
        readingHistory.removeAll { $0.book == book && $0.chapter == chapter }
        
        // Add new entry at the beginning
        let newItem = ReadingHistoryItem(book: book, chapter: chapter)
        readingHistory.insert(newItem, at: 0)
        
        // Limit to maxHistoryItems
        if readingHistory.count > maxHistoryItems {
            readingHistory = Array(readingHistory.prefix(maxHistoryItems))
        }
        
        // Mark chapter as read
        markChapterAsRead(book: book, chapter: chapter)
        
        // Save to UserDefaults
        saveHistory()
    }
    
    func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([ReadingHistoryItem].self, from: data) else {
            readingHistory = []
            return
        }
        
        readingHistory = decoded
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(readingHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    func clearHistory() {
        readingHistory = []
        userDefaults.removeObject(forKey: historyKey)
        readChapters = []
        userDefaults.removeObject(forKey: readChaptersKey)
    }
    
    func getRecentHistory(limit: Int = 3) -> [ReadingHistoryItem] {
        return Array(readingHistory.prefix(limit))
    }
    
    // MARK: - Today's Reading Stats
    
    /// Get count of unique chapters read today
    func getTodayReadingCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return readingHistory.filter { item in
            calendar.isDate(item.timestamp, inSameDayAs: today)
        }.count
    }
    
    /// Get all readings from today
    func getTodayReadings() -> [ReadingHistoryItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return readingHistory.filter { item in
            calendar.isDate(item.timestamp, inSameDayAs: today)
        }
    }
}






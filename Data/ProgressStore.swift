// ProgressStore - Manages reading progress using UserDefaults

import Foundation
import Combine

struct ReadingProgressData: Codable {
    let book: String
    let chapter: Int
    let lastReadAt: Date
}

class ProgressStore: ObservableObject {
    static let shared = ProgressStore()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "readingProgress"
    
    @Published var currentBook: String?
    @Published var currentChapter: Int?
    
    private init() {
        loadProgress()
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
}


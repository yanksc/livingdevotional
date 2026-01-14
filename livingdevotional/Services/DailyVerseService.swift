// DailyVerseService - Manages Verse of the Day functionality

import Foundation
import Combine

class DailyVerseService: DailyVerseServiceProtocol {
    static let shared = DailyVerseService()
    
    private let bibleService: BibleService
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
    
    init(bibleService: BibleService = .shared) {
        self.bibleService = bibleService
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
    
    func getCuratedVerses(category: String?) async throws -> [CuratedVerse] {
        // Placeholder for future implementation
        return []
    }
    
    private func generateAndSaveDailyVerse(for date: Date) async throws -> DailyVerse {
        // Pick a random verse from popular list
        // Use the date to seed the selection so it's consistent across app launches if storage fails
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = dayOfYear % popularVerses.count
        let selection = popularVerses[index]
        
        // Fetch verse text from all translations
        // Load verses from each translation and combine them
        var textBsb = ""
        var textCuv = ""
        var textCu1 = ""
        var textKjv = ""
        
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
        
        // If no verse found in any translation, throw error
        if textBsb.isEmpty && textCuv.isEmpty && textCu1.isEmpty && textKjv.isEmpty {
            throw NSError(domain: "DailyVerseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Verse not found"])
        }
        
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
            reference: "\(selection.book) \(selection.chapter):\(selection.verse)",
            selectedDate: dateString
        )
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(dailyVerse) {
            userDefaults.set(encoded, forKey: dailyVerseKey)
            userDefaults.set(date, forKey: dailyVerseDateKey)
        }
        
        return dailyVerse
    }
}



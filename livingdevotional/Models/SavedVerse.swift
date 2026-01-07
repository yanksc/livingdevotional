// SavedVerse - SwiftData model for saved verses with notes and labels

import Foundation
import SwiftData

@Model
final class SavedVerse {
    @Attribute(.unique) var id: String
    var verseReference: String // e.g., "John 3:16"
    var book: String
    var chapter: Int
    var verse: Int
    var content: String // The note text (optional)
    var labels: [String] // Tags like "Peace", "Faith"
    var timestamp: Date
    var color: String? // Optional highlight color
    
    init(
        id: String = UUID().uuidString,
        verseReference: String,
        book: String,
        chapter: Int,
        verse: Int,
        content: String = "",
        labels: [String] = [],
        timestamp: Date = Date(),
        color: String? = nil
    ) {
        self.id = id
        self.verseReference = verseReference
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.content = content
        self.labels = labels
        self.timestamp = timestamp
        self.color = color
    }
    
    // Helper to generate verse reference
    static func generateReference(book: String, chapter: Int, verse: Int) -> String {
        return "\(book) \(chapter):\(verse)"
    }
}


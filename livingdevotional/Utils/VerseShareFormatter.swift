// VerseShareFormatter.swift
// Shared utility for formatting verse text for sharing across the app

import Foundation

enum VerseShareFormatter {
    
    /// Format a BibleVerse for sharing
    static func format(_ verse: BibleVerse, language: Language) -> String {
        let text = verse.text(for: language)
        let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
        return formatShareText(text: text, reference: reference)
    }
    
    /// Format a DailyVerse for sharing
    static func format(_ verse: DailyVerse, language: Language) -> String {
        let text = verse.text(for: language)
        let reference = verseRangeReference(book: verse.book, chapter: verse.chapter,
                                            verseStart: verse.verseNumber, verseEnd: verse.verseNumberEnd)
        return formatShareText(text: text, reference: reference)
    }
    
    /// Format a DailyVerse for sharing with localized book name
    static func format(_ verse: DailyVerse, language: Language, bookNameLanguage: Language) -> String {
        let text = verse.text(for: language)
        let localizedBook = BibleData.localizedBookName(verse.book, language: bookNameLanguage)
        let reference = verseRangeReference(book: localizedBook, chapter: verse.chapter,
                                            verseStart: verse.verseNumber, verseEnd: verse.verseNumberEnd)
        return formatShareText(text: text, reference: reference)
    }
    
    private static func verseRangeReference(book: String, chapter: Int, verseStart: Int, verseEnd: Int?) -> String {
        if let end = verseEnd, end != verseStart {
            return "\(book) \(chapter):\(verseStart)-\(end)"
        }
        return "\(book) \(chapter):\(verseStart)"
    }
    
    /// Common share text formatting
    private static func formatShareText(text: String, reference: String) -> String {
        "\"\(text)\"\n- \(reference)\n\nShared from Living Path"
    }
}

// BibleService - Loads Bible verses from local JSON files

import Foundation

enum BibleServiceError: LocalizedError {
    case fileNotFound(book: String, chapter: Int, translation: String)
    case invalidData(book: String, chapter: Int, translation: String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let book, let chapter, let translation):
            return "Bible file not found: \(translation)/\(book)/\(chapter).json\n\nPlease ensure the BibleData folder is added to your Xcode project and included in the app bundle."
        case .invalidData(let book, let chapter, let translation):
            return "Invalid data in file: \(translation)/\(book)/\(chapter).json"
        case .decodingError(let error):
            return "Failed to decode Bible data: \(error.localizedDescription)"
        }
    }
}

class BibleService {
    static let shared = BibleService()
    
    private init() {
        // Debug: Verify bundle structure on first access
        #if DEBUG
        BundleHelper.debugBundleStructure()
        #endif
    }
    
    /// Load verses for a specific book, chapter, and translation
    /// Expected file structure: BibleData.bundle/{translation}/{bookId}/{chapter}.json
    func loadVerses(book: String, chapter: Int, translation: Language) async throws -> [BibleVerse] {
        guard let bookId = BibleData.bookId(for: book) else {
            throw BibleServiceError.fileNotFound(book: book, chapter: chapter, translation: translation.rawValue)
        }
        
        let translationFolder: String
        switch translation {
        case .bsb:
            translationFolder = "bsb"
        case .cuv:
            translationFolder = "cuv"
        case .cu1:
            translationFolder = "cu1"
        case .none:
            throw BibleServiceError.fileNotFound(book: book, chapter: chapter, translation: translation.rawValue)
        }
        
        // Load from the BibleData.bundle
        // Xcode treats .bundle folders as single units, preserving subfolder structure.
        guard let bundleUrl = Bundle.main.url(forResource: "BibleData", withExtension: "bundle"),
              let bibleBundle = Bundle(url: bundleUrl) else {
            throw BibleServiceError.fileNotFound(book: book, chapter: chapter, translation: translation.rawValue)
        }
        
        let fileUrl = bibleBundle.url(
            forResource: "\(chapter)",
            withExtension: "json",
            subdirectory: "\(translationFolder)/\(bookId)"
        )
        
        guard let url = fileUrl else {
            throw BibleServiceError.fileNotFound(
                book: book,
                chapter: chapter,
                translation: translation.rawValue
            )
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // The JSON structure may vary - we'll try to decode as an array of verses
            // Common formats: [{"verse": 1, "text": "..."}, ...] or {"verses": [...]}
            let verses = try decoder.decode([BibleVerseJSON].self, from: data)
            
            return verses.map { verseJson in
                BibleVerse(
                    id: "\(bookId)-\(chapter)-\(verseJson.verse)",
                    book: book,
                    chapter: chapter,
                    verseNumber: verseJson.verse,
                    textBsb: translation == .bsb ? verseJson.text : "",
                    textCuv: translation == .cuv ? verseJson.text : "",
                    textCu1: translation == .cu1 ? verseJson.text : "",
                    testament: BibleData.book(named: book)?.testament.rawValue ?? ""
                )
            }
        } catch {
            // Try alternative format: {"verses": [...]}
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let container = try decoder.decode(BibleChapterJSON.self, from: data)
                
                return container.verses.map { verseJson in
                    BibleVerse(
                        id: "\(bookId)-\(chapter)-\(verseJson.verse)",
                        book: book,
                        chapter: chapter,
                        verseNumber: verseJson.verse,
                        textBsb: translation == .bsb ? verseJson.text : "",
                        textCuv: translation == .cuv ? verseJson.text : "",
                        textCu1: translation == .cu1 ? verseJson.text : "",
                        testament: BibleData.book(named: book)?.testament.rawValue ?? ""
                    )
                }
            } catch {
                throw BibleServiceError.decodingError(error)
            }
        }
    }
    
    /// Load verses for both primary and secondary languages
    func loadVersesDualLanguage(book: String, chapter: Int, primary: Language, secondary: Language) async throws -> [BibleVerse] {
        // Load primary language verses
        let primaryVerses = try await loadVerses(book: book, chapter: chapter, translation: primary)
        
        // If secondary language is "none" or same as primary, return primary verses
        guard secondary != .none && secondary != primary else {
            return primaryVerses
        }
        
        // Load secondary language verses
        let secondaryVerses = try await loadVerses(book: book, chapter: chapter, translation: secondary)
        
        // Create a map of verse numbers to secondary verses
        let secondaryMap = Dictionary(uniqueKeysWithValues: secondaryVerses.map { ($0.verseNumber, $0) })
        
        // Merge verses by verse number
        return primaryVerses.map { primaryVerse in
            guard let secondaryVerse = secondaryMap[primaryVerse.verseNumber] else {
                return primaryVerse
            }
            
            // Create merged verse with both languages
            return BibleVerse(
                id: primaryVerse.id,
                book: primaryVerse.book,
                chapter: primaryVerse.chapter,
                verseNumber: primaryVerse.verseNumber,
                textBsb: primaryVerse.textBsb.isEmpty ? secondaryVerse.textBsb : primaryVerse.textBsb,
                textCuv: primaryVerse.textCuv.isEmpty ? secondaryVerse.textCuv : primaryVerse.textCuv,
                textCu1: primaryVerse.textCu1.isEmpty ? secondaryVerse.textCu1 : primaryVerse.textCu1,
                testament: primaryVerse.testament
            )
        }
    }
}

// MARK: - JSON Decoding Structures

private struct BibleVerseJSON: Codable {
    let verse: Int
    let text: String
}

private struct BibleChapterJSON: Codable {
    let verses: [BibleVerseJSON]
}


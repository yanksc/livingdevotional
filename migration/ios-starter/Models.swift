// BibleMind iOS - Swift Models
// Converted from TypeScript types.ts

import Foundation

// MARK: - Language Enum

enum Language: String, Codable, CaseIterable, Identifiable {
    case niv = "niv"
    case cuv = "cuv"
    case cu1 = "cu1"
    case none = "none"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .niv: return "English (NIV)"
        case .cuv: return "中文和合本 (CUV)"
        case .cu1: return "新标点和合本"
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        case .niv: return "New International Version"
        case .cuv: return "Chinese Union Version"
        case .cu1: return "Chinese Union Version with New Punctuation"
        case .none: return "僅顯示主要語言"
        }
    }
}

// MARK: - Bible Verse

struct BibleVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textNiv: String
    let textCuv: String
    let textCu1: String
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textNiv = "text_niv"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
    }
    
    /// Get text for specified language
    func text(for language: Language) -> String {
        switch language {
        case .niv: return textNiv
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .none: return ""
        }
    }
}

// MARK: - Bible Book

struct BibleBook: Codable, Identifiable, Hashable {
    let name: String
    let testament: Testament
    let chapters: Int
    let hasData: Bool
    
    var id: String { name }
    
    enum Testament: String, Codable {
        case old = "Old"
        case new = "New"
        
        var displayName: String {
            switch self {
            case .old: return "舊約"
            case .new: return "新約"
            }
        }
        
        var englishName: String {
            switch self {
            case .old: return "Old Testament"
            case .new: return "New Testament"
            }
        }
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Identifiable {
    let id: String?
    let userId: String
    var primaryLanguage: Language
    var secondaryLanguage: Language
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case primaryLanguage = "primary_language"
        case secondaryLanguage = "secondary_language"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Verse Bookmark

struct VerseBookmark: Codable, Identifiable {
    let id: String
    let userId: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let verseText: String
    var note: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case book, chapter
        case verseNumber = "verse_number"
        case verseText = "verse_text"
        case note
        case createdAt = "created_at"
    }
}

// MARK: - Reading Progress

struct ReadingProgress: Codable, Identifiable {
    let id: String?
    let userId: String
    let book: String
    let chapter: Int
    let lastVerse: Int
    let lastReadAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case book, chapter
        case lastVerse = "last_verse"
        case lastReadAt = "last_read_at"
    }
}

// MARK: - Daily Verse (Verse of the Day)

struct DailyVerse: Codable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textNiv: String
    let textCuv: String
    let textCu1: String
    let reference: String
    let selectedDate: String
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference
        case verseNumber = "verse_number"
        case textNiv = "text_niv"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case selectedDate = "selected_date"
    }
    
    func text(for language: Language) -> String {
        switch language {
        case .niv: return textNiv
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .none: return ""
        }
    }
}

// MARK: - Related Verse (AI Response)

struct RelatedVerse: Codable, Identifiable {
    let reference: String
    let summary: String
    let relevance: String
    
    var id: String { reference }
}

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable {
    let id: String?
    let role: MessageRole
    let content: String
    let createdAt: Date?
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
    
    enum CodingKeys: String, CodingKey {
        case id, role, content
        case createdAt = "created_at"
    }
    
    init(id: String? = nil, role: MessageRole, content: String, createdAt: Date? = nil) {
        self.id = id ?? UUID().uuidString
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Verse Conversation

struct VerseConversation: Codable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    var messages: [ChatMessage]
    
    enum CodingKeys: String, CodingKey {
        case book, chapter
        case verseNumber = "verse_number"
        case messages
    }
}

// MARK: - Daily Check-in

struct DailyCheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let checkInDate: String
    let readCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case checkInDate = "check_in_date"
        case readCount = "read_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Search Result

struct SearchResult: Codable, Identifiable {
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textCuv: String
    let textNiv: String
    let reference: String
    let relevance: String
    
    var id: String { reference }
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference, relevance
        case verseNumber = "verse_number"
        case textCuv = "text_cuv"
        case textNiv = "text_niv"
    }
}

// MARK: - Search Response

struct SearchResponse: Codable {
    let results: [SearchResult]
    let message: String
}

// MARK: - Curated Verse (for VOTD pool)

struct CuratedVerse: Codable, Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let category: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, category
        case verseNumber = "verse_number"
        case createdAt = "created_at"
    }
}



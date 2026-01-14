// BibleMind iOS - Swift Models
// Converted from TypeScript types.ts

import Foundation

// MARK: - Verse Mode Enum

enum AIMode: String, CaseIterable {
    case insight
    case reflect
    case pray
    
    var displayName: String {
        switch self {
        case .insight: return "Insight"
        case .reflect: return "Reflect"
        case .pray: return "Pray"
        }
    }
}

// MARK: - App Font Enum

enum AppFont: String, Codable, CaseIterable, Identifiable {
    case system = "system"
    case serif = "serif"
    case rounded = "rounded"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        }
    }
    
    func localizedDisplayName(appLanguage: AppLanguage) -> String {
        switch self {
        case .system: return appLanguage.localizedString("FontSystem")
        case .serif: return appLanguage.localizedString("FontSerif")
        case .rounded: return appLanguage.localizedString("FontRounded")
        }
    }
}

// MARK: - Language Enum (Bible Translation)

enum Language: String, Codable, CaseIterable, Identifiable {
    case bsb = "bsb"
    case cuv = "cuv"
    case cu1 = "cu1"
    case kjv = "kjv"
    case none = "none"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bsb: return "English (BSB)"
        case .cuv: return "中文和合本 (CUV)"
        case .cu1: return "新标点和合本"
        case .kjv: return "King James Version"
        case .none: return "無"
        }
    }
    
    var description: String {
        switch self {
        case .bsb: return "Berean Standard Bible"
        case .cuv: return "Chinese Union Version"
        case .cu1: return "Chinese Union Version with New Punctuation"
        case .kjv: return "King James Version"
        case .none: return "僅顯示主要語言"
        }
    }
}

// MARK: - AppLanguage Enum (UI Language)

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english = "en"
    case chineseTraditional = "zh-Hant"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .chineseTraditional: return "繁體中文"
        }
    }
    
    /// Resolve to a specific locale identifier, using system locale if .system
    func resolvedLocale() -> Locale {
        switch self {
        case .system:
            return Locale.current
        case .english:
            return Locale(identifier: "en")
        case .chineseTraditional:
            return Locale(identifier: "zh-Hant")
        }
    }
    
    /// Get the resolved language code for book name localization
    func resolvedLanguageCode() -> String {
        switch self {
        case .system:
            // Use system's preferred language
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                return "zh-Hant"
            }
            return "en"
        case .english:
            return "en"
        case .chineseTraditional:
            return "zh-Hant"
        }
    }
    
    /// Localize interface strings based on app language
    func localizedString(_ key: String) -> String {
        let languageCode = resolvedLanguageCode()
        
        // #region agent log
        let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
        let logEntry: [String: Any] = [
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "location": "AppLanguage.localizedString",
            "message": "Localizing string",
            "data": [
                "key": key,
                "appLanguage": self.rawValue,
                "resolvedLanguageCode": languageCode,
                "hypothesisId": "C"
            ],
            "sessionId": "debug-session",
            "runId": "localization-debug"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
            }
        }
        // #endregion agent log
        
        // Interface string mappings
        let strings: [String: [String: String]] = [
            "Home": ["en": "Home", "zh-Hant": "首頁"],
            "Welcome": ["en": "Welcome", "zh-Hant": "歡迎"],
            "WelcomeSubtitle": ["en": "Start your daily devotional journey", "zh-Hant": "開始您的每日靈修之旅"],
            "VerseOfTheDay": ["en": "Verse of the Day", "zh-Hant": "今日金句"],
            "QuickActions": ["en": "Quick Actions", "zh-Hant": "快速操作"],
            "ContinueReading": ["en": "Continue Reading", "zh-Hant": "繼續閱讀"],
            "ReadBible": ["en": "Read Bible", "zh-Hant": "讀經"],
            "MyNotes": ["en": "My Notes", "zh-Hant": "我的筆記"],
            "ReadChapter": ["en": "Read Chapter", "zh-Hant": "閱讀章節"],
            "SavedNotes": ["en": "Saved Notes", "zh-Hant": "已保存的筆記"],
            "ViewAll": ["en": "View All", "zh-Hant": "查看全部"],
            "NoRecentReading": ["en": "No recent reading", "zh-Hant": "沒有最近的閱讀記錄"],
            "NoSavedVerses": ["en": "No saved verses yet", "zh-Hant": "尚未保存任何經文"],
            "UnableToLoadVerse": ["en": "Unable to load verse", "zh-Hant": "無法載入經文"],
            "Loading": ["en": "Loading...", "zh-Hant": "載入中..."],
            "ErrorLoadingVerses": ["en": "Error loading verses", "zh-Hant": "載入經文時發生錯誤"],
            "NoVersesFound": ["en": "No verses found", "zh-Hant": "找不到經文"],
            "Retry": ["en": "Retry", "zh-Hant": "重試"],
            "Bible": ["en": "Bible", "zh-Hant": "聖經"],
            "Books": ["en": "Books", "zh-Hant": "書卷"],
            "Chapter": ["en": "chapter", "zh-Hant": "章"],
            "Chapters": ["en": "chapters", "zh-Hant": "章"],
            "SelectBook": ["en": "Select Book", "zh-Hant": "選擇書卷"],
            "Done": ["en": "Done", "zh-Hant": "完成"],
            "ViewSettings": ["en": "View Settings", "zh-Hant": "檢視設定"],
            "FontSize": ["en": "Font Size", "zh-Hant": "字體大小"],
            "LineSpacing": ["en": "Line Spacing", "zh-Hant": "行距"],
            "Language": ["en": "Language", "zh-Hant": "語言"],
            "ShowSecondLanguage": ["en": "Show Second Language", "zh-Hant": "顯示第二語言"],
            "Appearance": ["en": "Appearance", "zh-Hant": "外觀"],
            "DarkMode": ["en": "Dark Mode", "zh-Hant": "深色模式"],
            "AIExplanation": ["en": "Explanation", "zh-Hant": "解釋"],
            "GeneratingExplanation": ["en": "Loading explanation...", "zh-Hant": "載入解釋中..."],
            "AIInsight": ["en": "Insight", "zh-Hant": "理解"],
            "AIReflect": ["en": "Reflect", "zh-Hant": "反思"],
            "AIPray": ["en": "Pray", "zh-Hant": "禱告"],
            "Font": ["en": "Font", "zh-Hant": "字體"],
            "FontSystem": ["en": "System", "zh-Hant": "系統"],
            "FontSerif": ["en": "Serif", "zh-Hant": "襯線"],
            "FontRounded": ["en": "Rounded", "zh-Hant": "圓體"],
            "BibleTranslation": ["en": "Bible Translation", "zh-Hant": "聖經譯本"],
            "PrimaryTranslation": ["en": "Primary Translation", "zh-Hant": "主要譯本"],
            "SecondaryTranslation": ["en": "Secondary Translation", "zh-Hant": "次要譯本"],
            "ReadingSettings": ["en": "Reading Settings", "zh-Hant": "閱讀設定"]
        ]
        
        return strings[key]?[languageCode] ?? strings[key]?["en"] ?? key
    }
}

// MARK: - Bible Verse

struct BibleVerse: Codable, Identifiable, Hashable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textKjv: String
    let testament: String
    
    enum CodingKeys: String, CodingKey {
        case id, book, chapter, testament
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textKjv = "text_kjv"
    }
    
    /// Get text for specified language
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .kjv: return textKjv
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
    let textBsb: String
    let textCuv: String
    let textCu1: String
    let textKjv: String
    let reference: String
    let selectedDate: String
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference
        case verseNumber = "verse_number"
        case textBsb = "text_bsb"
        case textCuv = "text_cuv"
        case textCu1 = "text_cu1"
        case textKjv = "text_kjv"
        case selectedDate = "selected_date"
    }
    
    func text(for language: Language) -> String {
        switch language {
        case .bsb: return textBsb
        case .cuv: return textCuv
        case .cu1: return textCu1
        case .kjv: return textKjv
        case .none: return ""
        }
    }
}

// MARK: - Related Verse

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
    let textBsb: String
    let reference: String
    let relevance: String
    
    var id: String { reference }
    
    enum CodingKeys: String, CodingKey {
        case book, chapter, reference, relevance
        case verseNumber = "verse_number"
        case textCuv = "text_cuv"
        case textBsb = "text_bsb"
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


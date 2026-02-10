// WidgetLocalization - Localized strings for widgets
//
// Supports: English, Traditional Chinese, Simplified Chinese, Spanish, Portuguese

import Foundation

/// Localized strings for widget content
enum WidgetStrings {
    
    // MARK: - Widget Titles
    
    static func verseOfTheDay(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "今日金句"
        case "spa_r09": return "Versículo del Día"
        case "por_blj": return "Versículo do Dia"
        default: return "Verse of the Day"
        }
    }
    
    static func appName(languageCode: String) -> String {
        // App name stays as "Living Path" in all languages
        return "Living Path"
    }
    
    static func streak(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "連續"
        case "spa_r09": return "Racha"
        case "por_blj": return "Sequência"
        default: return "Streak"
        }
    }
    
    static func dayStreak(_ count: Int, languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "\(count) 天連續"
        case "spa_r09": return "racha de \(count) días"
        case "por_blj": return "sequência de \(count) dias"
        default: return "\(count) day streak"
        }
    }
    
    static func tapToRead(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "點擊閱讀"
        case "spa_r09": return "Toca para leer"
        case "por_blj": return "Toque para ler"
        default: return "Tap to read"
        }
    }
    
    static func tapToOpen(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "點擊打開"
        case "spa_r09": return "Toca para abrir"
        case "por_blj": return "Toque para abrir"
        default: return "Tap to open"
        }
    }
    
    // MARK: - Reading Plan Strings
    
    static func day(_ current: Int, of total: Int, languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "第 \(current)/\(total) 天"
        case "spa_r09": return "Día \(current)/\(total)"
        case "por_blj": return "Dia \(current)/\(total)"
        default: return "Day \(current)/\(total)"
        }
    }
    
    static func readingPlan(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "閱讀計劃"
        case "spa_r09": return "Plan de Lectura"
        case "por_blj": return "Plano de Leitura"
        default: return "Reading Plan"
        }
    }
    
    // MARK: - Daily Tasks
    
    static func read(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "閱讀"
        case "spa_r09": return "Leer"
        case "por_blj": return "Ler"
        default: return "Read"
        }
    }
    
    static func pray(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "禱告"
        case "spa_r09": return "Orar"
        case "por_blj": return "Orar"
        default: return "Pray"
        }
    }
    
    // MARK: - Widget Configuration Display Names
    
    static func verseWidgetDisplayName(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "今日金句"
        case "spa_r09": return "Versículo del Día"
        case "por_blj": return "Versículo do Dia"
        default: return "Verse of the Day"
        }
    }
    
    static func verseWidgetDescription(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "每日聖經經文啟發"
        case "spa_r09": return "Inspiración diaria de las Escrituras"
        case "por_blj": return "Inspiração diária das Escrituras"
        default: return "Daily inspiration from Scripture"
        }
    }
    
    static func streakWidgetDisplayName(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "連續天數"
        case "spa_r09": return "Racha"
        case "por_blj": return "Sequência"
        default: return "Streak"
        }
    }
    
    static func streakWidgetDescription(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "追蹤您的每日靈修連續天數"
        case "spa_r09": return "Rastrea tu racha devocional diaria"
        case "por_blj": return "Acompanhe sua sequência devocional diária"
        default: return "Track your daily devotional streak"
        }
    }
    
    static func planWidgetDisplayName(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "閱讀計劃"
        case "spa_r09": return "Plan de Lectura"
        case "por_blj": return "Plano de Leitura"
        default: return "Reading Plan"
        }
    }
    
    static func planWidgetDescription(languageCode: String) -> String {
        switch languageCode {
        case "cuv", "cu1": return "追蹤您的閱讀計劃進度"
        case "spa_r09": return "Rastrea el progreso de tu plan de lectura"
        case "por_blj": return "Acompanhe o progresso do seu plano de leitura"
        default: return "Track your reading plan progress"
        }
    }
    
    // MARK: - Book Name Localization
    
    /// Chinese book name mapping
    static let chineseBookNames: [String: String] = [
        // Old Testament
        "Genesis": "創世記",
        "Exodus": "出埃及記",
        "Leviticus": "利未記",
        "Numbers": "民數記",
        "Deuteronomy": "申命記",
        "Joshua": "約書亞記",
        "Judges": "士師記",
        "Ruth": "路得記",
        "1 Samuel": "撒母耳記上",
        "2 Samuel": "撒母耳記下",
        "1 Kings": "列王紀上",
        "2 Kings": "列王紀下",
        "1 Chronicles": "歷代志上",
        "2 Chronicles": "歷代志下",
        "Ezra": "以斯拉記",
        "Nehemiah": "尼希米記",
        "Esther": "以斯帖記",
        "Job": "約伯記",
        "Psalms": "詩篇",
        "Proverbs": "箴言",
        "Ecclesiastes": "傳道書",
        "Song of Solomon": "雅歌",
        "Isaiah": "以賽亞書",
        "Jeremiah": "耶利米書",
        "Lamentations": "耶利米哀歌",
        "Ezekiel": "以西結書",
        "Daniel": "但以理書",
        "Hosea": "何西阿書",
        "Joel": "約珥書",
        "Amos": "阿摩司書",
        "Obadiah": "俄巴底亞書",
        "Jonah": "約拿書",
        "Micah": "彌迦書",
        "Nahum": "那鴻書",
        "Habakkuk": "哈巴谷書",
        "Zephaniah": "西番雅書",
        "Haggai": "哈該書",
        "Zechariah": "撒迦利亞書",
        "Malachi": "瑪拉基書",
        // New Testament
        "Matthew": "馬太福音",
        "Mark": "馬可福音",
        "Luke": "路加福音",
        "John": "約翰福音",
        "Acts": "使徒行傳",
        "Romans": "羅馬書",
        "1 Corinthians": "哥林多前書",
        "2 Corinthians": "哥林多後書",
        "Galatians": "加拉太書",
        "Ephesians": "以弗所書",
        "Philippians": "腓立比書",
        "Colossians": "歌羅西書",
        "1 Thessalonians": "帖撒羅尼迦前書",
        "2 Thessalonians": "帖撒羅尼迦後書",
        "1 Timothy": "提摩太前書",
        "2 Timothy": "提摩太後書",
        "Titus": "提多書",
        "Philemon": "腓利門書",
        "Hebrews": "希伯來書",
        "James": "雅各書",
        "1 Peter": "彼得前書",
        "2 Peter": "彼得後書",
        "1 John": "約翰一書",
        "2 John": "約翰二書",
        "3 John": "約翰三書",
        "Jude": "猶大書",
        "Revelation": "啟示錄",
    ]
    
    /// Get localized book name based on language code
    static func localizedBookName(_ book: String, languageCode: String) -> String {
        if languageCode == "cuv" || languageCode == "cu1" {
            return chineseBookNames[book] ?? book
        }
        return book
    }
}

// MARK: - Helper Extension for WidgetData

extension WidgetData {
    /// Get localized string based on primary language code
    func localizedVerseOfTheDay() -> String {
        WidgetStrings.verseOfTheDay(languageCode: primaryLanguageCode)
    }
    
    func localizedStreak() -> String {
        WidgetStrings.dayStreak(currentStreak, languageCode: primaryLanguageCode)
    }
    
    func localizedTapToRead() -> String {
        WidgetStrings.tapToRead(languageCode: primaryLanguageCode)
    }
    
    func localizedTapToOpen() -> String {
        WidgetStrings.tapToOpen(languageCode: primaryLanguageCode)
    }
    
    func localizedDay() -> String? {
        guard let day = activePlanDay, let total = activePlanTotal else { return nil }
        return WidgetStrings.day(day, of: total, languageCode: primaryLanguageCode)
    }
    
    func localizedRead() -> String {
        WidgetStrings.read(languageCode: primaryLanguageCode)
    }
    
    func localizedPray() -> String {
        WidgetStrings.pray(languageCode: primaryLanguageCode)
    }
    
    /// Get localized verse reference (book name matches primary language)
    var localizedReference: String {
        let bookName = WidgetStrings.localizedBookName(verseBook, languageCode: primaryLanguageCode)
        return "\(bookName) \(verseChapter):\(verseNumber)"
    }
}

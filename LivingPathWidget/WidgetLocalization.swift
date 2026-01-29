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
}

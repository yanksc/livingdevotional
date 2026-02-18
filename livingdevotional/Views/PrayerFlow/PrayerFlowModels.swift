// PrayerFlowModels.swift
// Models and enums for the Prayer Flow feature

import Foundation

// MARK: - Verse Option Model

struct VerseOption: Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let verseText: String
    let source: VerseSource
    let sourceDescription: String
    let timestamp: Date
    
    enum VerseSource {
        case dailyVerse
        case recentReading
        case savedNote
        case qaHistory
        case newSearch
    }
}

// MARK: - Prayer Focus

enum PrayerFocus: String, CaseIterable {
    case recentFocus = "recent_focus"
    case worry = "worry"
    case gratitude = "gratitude"
    case guidance = "guidance"
    case strength = "strength"
    case custom = "custom"
    
    var displayName: String {
        let isChinese = SettingsStore.shared.appLanguage == .chineseTraditional
        switch self {
        case .recentFocus: return isChinese ? "最近的關注" : "Recent focus"
        case .worry: return isChinese ? "擔憂焦慮" : "Worry/anxiety"
        case .gratitude: return isChinese ? "感恩感謝" : "Gratitude/thanksgiving"
        case .guidance: return isChinese ? "指引決定" : "Guidance/decision"
        case .strength: return isChinese ? "力量鼓勵" : "Strength/encouragement"
        case .custom: return isChinese ? "自訂主題" : "Custom topic"
        }
    }
}

// MARK: - Prayer Intent

enum PrayerIntent: String, CaseIterable {
    case prayForMe = "pray_for_me"
    case helpMePray = "help_me_pray"
    
    var displayName: String {
        let languageCode = SettingsStore.shared.appLanguage.resolvedLanguageCode()
        let isSimplified = languageCode == "zh-Hans"
        let isChinese = languageCode == "zh-Hans" || languageCode == "zh-Hant"
        if isSimplified {
            switch self {
            case .prayForMe: return "为我祷告"
            case .helpMePray: return "帮我祷告"
            }
        } else if isChinese {
            switch self {
            case .prayForMe: return "為我禱告"
            case .helpMePray: return "幫我禱告"
            }
        } else {
            switch self {
            case .prayForMe: return "Pray for me"
            case .helpMePray: return "Help me pray"
            }
        }
    }
}

// MARK: - Emotional Need

enum EmotionalNeed: String, CaseIterable {
    case peace = "peace"
    case wisdom = "wisdom"
    case strength = "strength"
    case hope = "hope"
    case forgiveness = "forgiveness"
    case other = "other"
    
    var displayName: String {
        let isChinese = SettingsStore.shared.appLanguage == .chineseTraditional
        switch self {
        case .peace: return isChinese ? "平安安慰" : "Peace/comfort"
        case .wisdom: return isChinese ? "智慧指引" : "Wisdom/guidance"
        case .strength: return isChinese ? "力量勇氣" : "Strength/courage"
        case .hope: return isChinese ? "希望鼓勵" : "Hope/encouragement"
        case .forgiveness: return isChinese ? "寬恕醫治" : "Forgiveness/healing"
        case .other: return isChinese ? "其他" : "Other"
        }
    }
}

// MARK: - Question Type

enum PrayerQuestionType {
    case prayerIntent
    case heartFocus
    case chooseVerse
    case emotionalNeed
}

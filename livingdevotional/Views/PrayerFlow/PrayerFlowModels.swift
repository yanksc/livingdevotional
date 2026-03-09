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

// MARK: - Prayer Topic (9 options for first screen 3x3 grid)

enum PrayerTopic: String, CaseIterable {
    case worry
    case gratitude
    case guidance
    case hope
    case peace
    case strength
    case forgiveness
    case wisdom
    case courage
    
    var displayName: String {
        let isChinese = SettingsStore.shared.appLanguage == .chineseTraditional
        switch self {
        case .worry: return isChinese ? "擔憂" : "Worry"
        case .gratitude: return isChinese ? "感恩" : "Gratitude"
        case .guidance: return isChinese ? "指引" : "Guidance"
        case .hope: return isChinese ? "希望" : "Hope"
        case .peace: return isChinese ? "平安" : "Peace"
        case .strength: return isChinese ? "力量" : "Strength"
        case .forgiveness: return isChinese ? "寬恕" : "Forgiveness"
        case .wisdom: return isChinese ? "智慧" : "Wisdom"
        case .courage: return isChinese ? "勇氣" : "Courage"
        }
    }
}

// MARK: - Prayer Focus (deprecated - kept for PrayerGenerationWaitingView fallback)

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
        case .worry: return isChinese ? "擔憂焦慮" : "Worry and anxiety"
        case .gratitude: return isChinese ? "感恩感謝" : "Gratitude"
        case .guidance: return isChinese ? "指引決定" : "Guidance"
        case .strength: return isChinese ? "力量鼓勵" : "Strength"
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
            case .helpMePray: return "帮助我祷告"
            }
        } else if isChinese {
            switch self {
            case .prayForMe: return "為我禱告"
            case .helpMePray: return "幫助我禱告"
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
        case .peace: return isChinese ? "平安安慰" : "Peace and comfort"
        case .wisdom: return isChinese ? "智慧指引" : "Wisdom"
        case .strength: return isChinese ? "力量勇氣" : "Strength and courage"
        case .hope: return isChinese ? "希望鼓勵" : "Hope"
        case .forgiveness: return isChinese ? "寬恕醫治" : "Forgiveness and healing"
        case .other: return isChinese ? "其他" : "Other"
        }
    }
}

// MARK: - Question Type

enum PrayerQuestionType {
    case prayerIntro   // Intro screen with black-to-serene transition
    case firstScreen
    case chooseVerse
}

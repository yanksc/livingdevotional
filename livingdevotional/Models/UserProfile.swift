// UserProfile - Models for user spiritual profile and personalization

import Foundation

// MARK: - Spiritual Maturity

enum SpiritualMaturity: String, Codable, CaseIterable, Identifiable {
    case seeker = "seeker"
    case newBeliever = "newBeliever"
    case growing = "growing"
    case mature = "mature"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .seeker: return "Curious Seeker"
        case .newBeliever: return "New Believer"
        case .growing: return "Growing in Faith"
        case .mature: return "Mature in Faith"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .seeker: return "正在探索"
        case .newBeliever: return "信主不久"
        case .growing: return "持續成長中"
        case .mature: return "信主多年"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .seeker: return "正在探索"
            case .newBeliever: return "信主不久"
            case .growing: return "持续成长中"
            case .mature: return "信主多年"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
    
    /// Adaptive intro for Step 4 based on journey stage
    func adaptiveIntro(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans", "zh-Hant":
            switch self {
            case .seeker: return "每段旅程都有起點。"
            case .newBeliever: return "起初的腳步最珍貴。"
            case .growing: return "成長常在安靜中發生。"
            case .mature: return "根深的樹也需要水。"
            }
        case "es":
            switch self {
            case .seeker: return "Todo viaje comienza en algún lugar."
            case .newBeliever: return "Los primeros pasos son los más importantes."
            case .growing: return "El crecimiento a menudo viene en momentos de quietud."
            case .mature: return "Incluso las raíces profundas necesitan agua."
            }
        default:
            switch self {
            case .seeker: return "Every journey starts somewhere."
            case .newBeliever: return "The early steps matter most."
            case .growing: return "Growth often comes in quiet moments."
            case .mature: return "Even deep roots need water."
            }
        }
    }
}

// MARK: - Spiritual Goals

enum SpiritualGoal: String, Codable, CaseIterable, Identifiable {
    case peace = "peace"
    case understanding = "understanding"
    case habit = "habit"
    case healing = "healing"
    case deepStudy = "deepStudy"
    case community = "community"
    case guidance = "guidance"
    case comfort = "comfort"
    case purpose = "purpose"
    case gratitude = "gratitude"
    case forgiveness = "forgiveness"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .peace: return "Finding Peace"
        case .understanding: return "Understanding Scripture"
        case .habit: return "Building a Habit"
        case .healing: return "Healing"
        case .deepStudy: return "Deep Study"
        case .community: return "Growing in Community"
        case .guidance: return "Seeking Guidance"
        case .comfort: return "Finding Comfort"
        case .purpose: return "Discovering Purpose"
        case .gratitude: return "Cultivating Gratitude"
        case .forgiveness: return "Experiencing Forgiveness"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .peace: return "尋找平安"
        case .understanding: return "理解聖經"
        case .habit: return "建立習慣"
        case .healing: return "醫治"
        case .deepStudy: return "深入研讀"
        case .community: return "在群體中成長"
        case .guidance: return "尋求指引"
        case .comfort: return "尋找安慰"
        case .purpose: return "發現意義"
        case .gratitude: return "培養感恩"
        case .forgiveness: return "經歷寬恕"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .peace: return "寻找平安"
            case .understanding: return "理解圣经"
            case .habit: return "建立习惯"
            case .healing: return "医治"
            case .deepStudy: return "深入研读"
            case .community: return "在群体中成长"
            case .guidance: return "寻求指引"
            case .comfort: return "寻找安慰"
            case .purpose: return "发现意义"
            case .gratitude: return "培养感恩"
            case .forgiveness: return "经历宽恕"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
}

// MARK: - Christian Tradition

enum ChristianTradition: String, Codable, CaseIterable, Identifiable {
    case evangelical = "evangelical"
    case catholic = "catholic"
    case orthodox = "orthodox"
    case mainline = "mainline"
    case charismatic = "charismatic"
    case nondenominational = "nondenominational"
    case none = "none"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .evangelical: return "Evangelical"
        case .catholic: return "Catholic"
        case .orthodox: return "Orthodox"
        case .mainline: return "Mainline Protestant"
        case .charismatic: return "Charismatic"
        case .nondenominational: return "Nondenominational"
        case .none: return "Prefer not to say"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .evangelical: return "福音派"
        case .catholic: return "天主教"
        case .orthodox: return "東正教"
        case .mainline: return "主流新教"
        case .charismatic: return "靈恩派"
        case .nondenominational: return "非宗派"
        case .none: return "暫不回答"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .evangelical: return "福音派"
            case .catholic: return "天主教"
            case .orthodox: return "东正教"
            case .mainline: return "主流新教"
            case .charismatic: return "灵恩派"
            case .nondenominational: return "非宗派"
            case .none: return "暂不回答"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
}

// MARK: - Spiritual Companion Style

enum AICompanionStyle: String, Codable, CaseIterable, Identifiable {
    case mentor = "mentor"
    case shepherd = "shepherd"
    case friend = "friend"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mentor: return "Wise Mentor"
        case .shepherd: return "Gentle Shepherd"
        case .friend: return "Prayer Partner"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .mentor: return "智慧導師"
        case .shepherd: return "溫柔牧者"
        case .friend: return "禱告夥伴"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .mentor: return "智慧导师"
            case .shepherd: return "温柔牧者"
            case .friend: return "祷告伙伴"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
    
    var description: String {
        switch self {
        case .mentor: return "Teaches biblical truth with depth and theological insight."
        case .shepherd: return "Focuses on comfort, encouragement, and pastoral care."
        case .friend: return "Helps you apply scripture and pray in a relatable way."
        }
    }
    
    var descriptionChinese: String {
        switch self {
        case .mentor: return "以深度和神學理解教導聖經真理。"
        case .shepherd: return "專注於安慰、鼓勵和牧養關懷。"
        case .friend: return "以親切的方式幫助您應用經文和禱告。"
        }
    }
    
    func localizedDescription(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .mentor: return "以深度和神学理解教导圣经真理。"
            case .shepherd: return "专注于安慰、鼓励和牧养关怀。"
            case .friend: return "以亲切的方式帮助您应用经文和祷告。"
            }
        case "zh-Hant":
            return descriptionChinese
        default:
            return description
        }
    }
}

// MARK: - Life Focus Area

enum LifeFocusArea: String, Codable, CaseIterable, Identifiable {
    case work = "work"
    case family = "family"
    case relationships = "relationships"
    case health = "health"
    case finances = "finances"
    case personalGrowth = "personalGrowth"
    case servingOthers = "servingOthers"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .family: return "Family"
        case .relationships: return "Relationships"
        case .health: return "Health"
        case .finances: return "Finances"
        case .personalGrowth: return "Personal growth"
        case .servingOthers: return "Serving others"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .work: return "工作"
        case .family: return "家庭"
        case .relationships: return "關係"
        case .health: return "健康"
        case .finances: return "財務"
        case .personalGrowth: return "個人成長"
        case .servingOthers: return "服務他人"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .work: return "工作"
            case .family: return "家庭"
            case .relationships: return "关系"
            case .health: return "健康"
            case .finances: return "财务"
            case .personalGrowth: return "个人成长"
            case .servingOthers: return "服务他人"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
}

// MARK: - Daily Time Commitment

enum DailyTimeCommitment: String, Codable, CaseIterable, Identifiable {
    case fewMinutes = "fewMinutes"
    case tenMinutes = "tenMinutes"
    case twentyMinutes = "twentyMinutes"
    case thirtyPlus = "thirtyPlus"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fewMinutes: return "A few minutes"
        case .tenMinutes: return "10 minutes"
        case .twentyMinutes: return "20 minutes"
        case .thirtyPlus: return "30+ minutes"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .fewMinutes: return "幾分鐘"
        case .tenMinutes: return "10分鐘"
        case .twentyMinutes: return "20分鐘"
        case .thirtyPlus: return "30分鐘以上"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .fewMinutes: return "几分钟"
            case .tenMinutes: return "10分钟"
            case .twentyMinutes: return "20分钟"
            case .thirtyPlus: return "30分钟以上"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
}

// MARK: - Explanation Depth

enum ExplanationDepth: String, Codable, CaseIterable, Identifiable {
    case simple = "simple"
    case someBackground = "someBackground"
    case deeper = "deeper"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .simple: return "Keep it simple"
        case .someBackground: return "Some background"
        case .deeper: return "Go deeper"
        }
    }
    
    var displayDescription: String {
        switch self {
        case .simple: return "Everyday language, easy to digest"
        case .someBackground: return "A bit of context when helpful"
        case .deeper: return "More historical and scholarly detail"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .simple: return "保持簡單"
        case .someBackground: return "一些背景"
        case .deeper: return "深入探索"
        }
    }
    
    var displayDescriptionChinese: String {
        switch self {
        case .simple: return "日常語言，易於理解"
        case .someBackground: return "需要時提供一些背景"
        case .deeper: return "更多歷史和學術細節"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .simple: return "保持简单"
            case .someBackground: return "一些背景"
            case .deeper: return "深入探索"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
        }
    }
    
    func localizedDescription(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .simple: return "日常语言，易于理解"
            case .someBackground: return "需要时提供一些背景"
            case .deeper: return "更多历史和学术细节"
            }
        case "zh-Hant":
            return displayDescriptionChinese
        default:
            return displayDescription
        }
    }
}

// MARK: - Onboarding Saved Verse (lightweight struct for onboarding flow)

struct OnboardingSavedVerse: Codable, Equatable {
    let reference: String      // e.g., "Matthew 11:28"
    let text: String           // The verse text
    let savedAt: Date
    let source: OnboardingVerseSource
    
    enum OnboardingVerseSource: String, Codable {
        case onboarding
        case reading
        case search
    }
}

// MARK: - Recommended Book (for Bible view empty state)

struct RecommendedBook: Codable, Equatable {
    let bookName: String       // e.g., "Psalms"
    let personalizedIntro: String
    let recommendedAt: Date
}

// MARK: - Onboarding Recommended Verse (from onboarding Step 7)

struct OnboardingRecommendedVerse: Codable, Equatable {
    let reference: String       // e.g., "Philippians 4:6-7"
    let text: String            // The verse text
    let reason: String          // Brief explanation why this verse is recommended
    let recommendedAt: Date
}

// MARK: - Scripture Echo Response (from AI)

struct ScriptureEchoResponse: Codable, Equatable {
    let echo: String?          // nil if empty reflection
    let verseReference: String
    let verseText: String
}

// MARK: - Deep Dive Question (from onboarding Step 7)

struct DeepDiveQuestion: Codable, Equatable {
    let question: String       // AI-generated question based on reflection
    let options: [String]      // 4 options for user to choose from
}

struct DeepDiveSelection: Codable, Equatable {
    let selectedOption: String?    // One of the 4 options, or nil if "Other"
    let customInput: String?       // Custom input if "Other" selected
    
    var displayText: String {
        if let custom = customInput, !custom.isEmpty {
            return custom
        }
        return selectedOption ?? ""
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    var name: String
    var spiritualMaturity: SpiritualMaturity
    var spiritualGoals: [SpiritualGoal]
    var tradition: ChristianTradition
    var companionStyle: AICompanionStyle
    var lifeFocusAreas: [LifeFocusArea]
    var dailyTimeCommitment: DailyTimeCommitment
    var explanationDepth: ExplanationDepth
    
    // New onboarding fields
    var personalReflection: String?
    var savedOnboardingVerse: OnboardingSavedVerse?
    var recommendedBooks: [RecommendedBook]?
    var recommendedVerses: [OnboardingRecommendedVerse]?
    
    init(
        name: String = "",
        spiritualMaturity: SpiritualMaturity = .growing,
        spiritualGoals: [SpiritualGoal] = [],
        tradition: ChristianTradition = .nondenominational,
        companionStyle: AICompanionStyle = .mentor,
        lifeFocusAreas: [LifeFocusArea] = [],
        dailyTimeCommitment: DailyTimeCommitment = .tenMinutes,
        explanationDepth: ExplanationDepth = .someBackground,
        personalReflection: String? = nil,
        savedOnboardingVerse: OnboardingSavedVerse? = nil,
        recommendedBooks: [RecommendedBook]? = nil,
        recommendedVerses: [OnboardingRecommendedVerse]? = nil
    ) {
        self.name = name
        self.spiritualMaturity = spiritualMaturity
        self.spiritualGoals = spiritualGoals
        self.tradition = tradition
        self.companionStyle = companionStyle
        self.lifeFocusAreas = lifeFocusAreas
        self.dailyTimeCommitment = dailyTimeCommitment
        self.explanationDepth = explanationDepth
        self.personalReflection = personalReflection
        self.savedOnboardingVerse = savedOnboardingVerse
        self.recommendedBooks = recommendedBooks
        self.recommendedVerses = recommendedVerses
    }
}

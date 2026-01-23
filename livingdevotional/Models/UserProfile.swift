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
        case .mature: return "Mature/Leader"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .seeker: return "尋求者"
        case .newBeliever: return "初信者"
        case .growing: return "成長中"
        case .mature: return "成熟/領袖"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .seeker: return "寻求者"
            case .newBeliever: return "初信者"
            case .growing: return "成长中"
            case .mature: return "成熟/领袖"
            }
        case "zh-Hant":
            return displayNameChinese
        default:
            return displayName
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
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .peace: return "Finding Peace"
        case .understanding: return "Understanding Scripture"
        case .habit: return "Building a Habit"
        case .healing: return "Healing"
        case .deepStudy: return "Deep Study"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .peace: return "尋找平安"
        case .understanding: return "理解聖經"
        case .habit: return "建立習慣"
        case .healing: return "醫治"
        case .deepStudy: return "深入研讀"
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
        case .none: return "None / Not Applicable"
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
        case .none: return "無/不適用"
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
            case .none: return "无/不适用"
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
        case .fewMinutes: return "Just a few minutes"
        case .tenMinutes: return "About 10 minutes"
        case .twentyMinutes: return "Around 20 minutes"
        case .thirtyPlus: return "30 minutes or more"
        }
    }
    
    var displayNameChinese: String {
        switch self {
        case .fewMinutes: return "幾分鐘"
        case .tenMinutes: return "約10分鐘"
        case .twentyMinutes: return "約20分鐘"
        case .thirtyPlus: return "30分鐘以上"
        }
    }
    
    func localizedDisplayName(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .fewMinutes: return "几分钟"
            case .tenMinutes: return "约10分钟"
            case .twentyMinutes: return "约20分钟"
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
    
    init(
        name: String = "",
        spiritualMaturity: SpiritualMaturity = .growing,
        spiritualGoals: [SpiritualGoal] = [],
        tradition: ChristianTradition = .nondenominational,
        companionStyle: AICompanionStyle = .mentor,
        lifeFocusAreas: [LifeFocusArea] = [],
        dailyTimeCommitment: DailyTimeCommitment = .tenMinutes,
        explanationDepth: ExplanationDepth = .someBackground
    ) {
        self.name = name
        self.spiritualMaturity = spiritualMaturity
        self.spiritualGoals = spiritualGoals
        self.tradition = tradition
        self.companionStyle = companionStyle
        self.lifeFocusAreas = lifeFocusAreas
        self.dailyTimeCommitment = dailyTimeCommitment
        self.explanationDepth = explanationDepth
    }
}

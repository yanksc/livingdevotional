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
        case .mentor: return "以深度和神學洞察教導聖經真理。"
        case .shepherd: return "專注於安慰、鼓勵和牧養關懷。"
        case .friend: return "以親切的方式幫助您應用經文和禱告。"
        }
    }
    
    func localizedDescription(for language: AppLanguage) -> String {
        let languageCode = language.resolvedLanguageCode()
        switch languageCode {
        case "zh-Hans":
            switch self {
            case .mentor: return "以深度和神学洞察教导圣经真理。"
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

// MARK: - User Profile

struct UserProfile: Codable {
    var name: String
    var spiritualMaturity: SpiritualMaturity
    var spiritualGoals: [SpiritualGoal]
    var tradition: ChristianTradition
    var companionStyle: AICompanionStyle
    
    init(
        name: String = "",
        spiritualMaturity: SpiritualMaturity = .growing,
        spiritualGoals: [SpiritualGoal] = [],
        tradition: ChristianTradition = .nondenominational,
        companionStyle: AICompanionStyle = .mentor
    ) {
        self.name = name
        self.spiritualMaturity = spiritualMaturity
        self.spiritualGoals = spiritualGoals
        self.tradition = tradition
        self.companionStyle = companionStyle
    }
}

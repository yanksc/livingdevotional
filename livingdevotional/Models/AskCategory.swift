// AskCategory - Model for common Bible and spiritual growth questions

import Foundation

struct AskQuestion: Identifiable, Codable, Hashable {
    let id: String
    let question: String
    let questionZh: String // Traditional Chinese
    let questionZhHans: String // Simplified Chinese
    let verseReference: String? // Optional verse reference like "John 3:16"
    let verseBook: String? // Optional book name for navigation
    let verseChapter: Int? // Optional chapter for navigation
    let verseNumber: Int? // Optional verse number for navigation
    
    init(
        id: String = UUID().uuidString,
        question: String,
        questionZh: String,
        questionZhHans: String,
        verseReference: String? = nil,
        verseBook: String? = nil,
        verseChapter: Int? = nil,
        verseNumber: Int? = nil
    ) {
        self.id = id
        self.question = question
        self.questionZh = questionZh
        self.questionZhHans = questionZhHans
        self.verseReference = verseReference
        self.verseBook = verseBook
        self.verseChapter = verseChapter
        self.verseNumber = verseNumber
    }
    
    func localizedQuestion(for appLanguage: AppLanguage) -> String {
        switch appLanguage {
        case .chineseTraditional:
            return questionZh
        case .chineseSimplified:
            return questionZhHans
        default:
            return question
        }
    }
}

struct AskCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let titleZh: String // Traditional Chinese
    let titleZhHans: String // Simplified Chinese
    let description: String
    let descriptionZh: String
    let descriptionZhHans: String
    let icon: String // SF Symbol name
    let imageName: String // Asset image name
    let questions: [AskQuestion]
    
    init(
        id: String,
        title: String,
        titleZh: String,
        titleZhHans: String,
        description: String,
        descriptionZh: String,
        descriptionZhHans: String,
        icon: String,
        imageName: String,
        questions: [AskQuestion]
    ) {
        self.id = id
        self.title = title
        self.titleZh = titleZh
        self.titleZhHans = titleZhHans
        self.description = description
        self.descriptionZh = descriptionZh
        self.descriptionZhHans = descriptionZhHans
        self.icon = icon
        self.imageName = imageName
        self.questions = questions
    }
    
    func localizedTitle(for appLanguage: AppLanguage) -> String {
        switch appLanguage {
        case .chineseTraditional:
            return titleZh
        case .chineseSimplified:
            return titleZhHans
        default:
            return title
        }
    }
    
    func localizedDescription(for appLanguage: AppLanguage) -> String {
        switch appLanguage {
        case .chineseTraditional:
            return descriptionZh
        case .chineseSimplified:
            return descriptionZhHans
        default:
            return description
        }
    }
}

class AskCategoryStore: ObservableObject {
    static let shared = AskCategoryStore()
    
    @Published var categories: [AskCategory] = []
    
    private init() {
        loadCategories()
    }
    
    private func loadCategories() {
        categories = [
            // 1. Bible Knowledge & Understanding
            AskCategory(
                id: "bible-knowledge",
                title: "Bible Knowledge",
                titleZh: "聖經知識",
                titleZhHans: "圣经知识",
                description: "Understanding Scripture and biblical concepts",
                descriptionZh: "理解聖經經文和聖經概念",
                descriptionZhHans: "理解圣经经文和圣经概念",
                icon: "book.fill",
                imageName: "AskBackground_BibleKnowledge",
                questions: [
                    AskQuestion(
                        question: "What does it mean to be 'born again'?",
                        questionZh: "什麼是「重生」？",
                        questionZhHans: "什么是「重生」？",
                        verseReference: "John 3:3",
                        verseBook: "John",
                        verseChapter: 3,
                        verseNumber: 3
                    ),
                    AskQuestion(
                        question: "What is the meaning of grace?",
                        questionZh: "恩典的意義是什麼？",
                        questionZhHans: "恩典的意义是什么？",
                        verseReference: "Ephesians 2:8",
                        verseBook: "Ephesians",
                        verseChapter: 2,
                        verseNumber: 8
                    ),
                    AskQuestion(
                        question: "How should I interpret parables in the Bible?",
                        questionZh: "我應該如何理解聖經中的比喻？",
                        questionZhHans: "我应该如何理解圣经中的比喻？"
                    ),
                    AskQuestion(
                        question: "What is the difference between the Old and New Testament?",
                        questionZh: "舊約和新約有什麼區別？",
                        questionZhHans: "旧约和新约有什么区别？"
                    ),
                    AskQuestion(
                        question: "Why are there four Gospels?",
                        questionZh: "為什麼有四本福音書？",
                        questionZhHans: "为什么有四本福音书？"
                    )
                ]
            ),
            
            // 2. Spiritual Growth & Discipleship
            AskCategory(
                id: "spiritual-growth",
                title: "Spiritual Growth",
                titleZh: "屬靈成長",
                titleZhHans: "属灵成长",
                description: "Growing in faith and following Jesus",
                descriptionZh: "在信仰中成長並跟隨耶穌",
                descriptionZhHans: "在信仰中成长并跟随耶稣",
                icon: "leaf.fill",
                imageName: "AskBackground_SpiritualGrowth",
                questions: [
                    AskQuestion(
                        question: "How can I grow closer to God?",
                        questionZh: "我如何能更親近神？",
                        questionZhHans: "我如何能更亲近神？",
                        verseReference: "James 4:8",
                        verseBook: "James",
                        verseChapter: 4,
                        verseNumber: 8
                    ),
                    AskQuestion(
                        question: "What does it mean to be a disciple?",
                        questionZh: "作門徒是什麼意思？",
                        questionZhHans: "作门徒是什么意思？",
                        verseReference: "Matthew 16:24",
                        verseBook: "Matthew",
                        verseChapter: 16,
                        verseNumber: 24
                    ),
                    AskQuestion(
                        question: "How do I develop a consistent prayer life?",
                        questionZh: "我如何建立穩定的禱告生活？",
                        questionZhHans: "我如何建立稳定的祷告生活？",
                        verseReference: "1 Thessalonians 5:17",
                        verseBook: "1 Thessalonians",
                        verseChapter: 5,
                        verseNumber: 17
                    ),
                    AskQuestion(
                        question: "What is spiritual maturity?",
                        questionZh: "什麼是屬靈成熟？",
                        questionZhHans: "什么是属灵成熟？"
                    ),
                    AskQuestion(
                        question: "How can I overcome spiritual dryness?",
                        questionZh: "我如何克服屬靈乾旱？",
                        questionZhHans: "我如何克服属灵干旱？"
                    )
                ]
            ),
            
            // 3. Faith & Doubt
            AskCategory(
                id: "faith-doubt",
                title: "Faith & Doubt",
                titleZh: "信心與疑惑",
                titleZhHans: "信心与疑惑",
                description: "Questions about believing and dealing with doubts",
                descriptionZh: "關於相信和處理疑惑的問題",
                descriptionZhHans: "关于相信和处理疑惑的问题",
                icon: "heart.fill",
                imageName: "AskBackground_FaithDoubt",
                questions: [
                    AskQuestion(
                        question: "How can I strengthen my faith?",
                        questionZh: "我如何能增強我的信心？",
                        questionZhHans: "我如何能增强我的信心？",
                        verseReference: "Romans 10:17",
                        verseBook: "Romans",
                        verseChapter: 10,
                        verseNumber: 17
                    ),
                    AskQuestion(
                        question: "Is it okay to have doubts about God?",
                        questionZh: "對神有疑惑是可以的嗎？",
                        questionZhHans: "对神有疑惑是可以的吗？",
                        verseReference: "Mark 9:24",
                        verseBook: "Mark",
                        verseChapter: 9,
                        verseNumber: 24
                    ),
                    AskQuestion(
                        question: "How do I know God is real?",
                        questionZh: "我如何知道神是真實的？",
                        questionZhHans: "我如何知道神是真实的？"
                    ),
                    AskQuestion(
                        question: "What if I don't feel God's presence?",
                        questionZh: "如果我感受不到神的同在怎麼辦？",
                        questionZhHans: "如果我感受不到神的同在怎么办？"
                    ),
                    AskQuestion(
                        question: "How can I trust God in difficult times?",
                        questionZh: "在困難時期我如何能信靠神？",
                        questionZhHans: "在困难时期我如何能信靠神？",
                        verseReference: "Proverbs 3:5-6",
                        verseBook: "Proverbs",
                        verseChapter: 3,
                        verseNumber: 5
                    )
                ]
            ),
            
            // 4. Prayer & Worship
            AskCategory(
                id: "prayer-worship",
                title: "Prayer & Worship",
                titleZh: "禱告與敬拜",
                titleZhHans: "祷告与敬拜",
                description: "Learning to pray and worship God",
                descriptionZh: "學習禱告和敬拜神",
                descriptionZhHans: "学习祷告和敬拜神",
                icon: "hands.sparkles.fill",
                imageName: "AskBackground_PrayerWorship",
                questions: [
                    AskQuestion(
                        question: "How should I pray?",
                        questionZh: "我應該如何禱告？",
                        questionZhHans: "我应该如何祷告？",
                        verseReference: "Matthew 6:9-13",
                        verseBook: "Matthew",
                        verseChapter: 6,
                        verseNumber: 9
                    ),
                    AskQuestion(
                        question: "Does God always answer prayer?",
                        questionZh: "神總是會回應禱告嗎？",
                        questionZhHans: "神总是会回应祷告吗？",
                        verseReference: "1 John 5:14",
                        verseBook: "1 John",
                        verseChapter: 5,
                        verseNumber: 14
                    ),
                    AskQuestion(
                        question: "What is worship and how do I worship?",
                        questionZh: "什麼是敬拜？我如何敬拜？",
                        questionZhHans: "什么是敬拜？我如何敬拜？"
                    ),
                    AskQuestion(
                        question: "Why should I pray if God already knows everything?",
                        questionZh: "如果神已經知道一切，為什麼我還要禱告？",
                        questionZhHans: "如果神已经知道一切，为什么我还要祷告？"
                    ),
                    AskQuestion(
                        question: "How can I make prayer more meaningful?",
                        questionZh: "我如何讓禱告更有意義？",
                        questionZhHans: "我如何让祷告更有意义？"
                    )
                ]
            ),
            
            // 5. Christian Living & Application
            AskCategory(
                id: "christian-living",
                title: "Christian Living",
                titleZh: "基督徒生活",
                titleZhHans: "基督徒生活",
                description: "Applying faith to daily life",
                descriptionZh: "將信仰應用在日常生活中",
                descriptionZhHans: "将信仰应用在日常生活中",
                icon: "figure.walk",
                imageName: "AskBackground_ChristianLiving",
                questions: [
                    AskQuestion(
                        question: "How do I love my neighbor as myself?",
                        questionZh: "我如何愛鄰舍如同自己？",
                        questionZhHans: "我如何爱邻舍如同自己？",
                        verseReference: "Matthew 22:39",
                        verseBook: "Matthew",
                        verseChapter: 22,
                        verseNumber: 39
                    ),
                    AskQuestion(
                        question: "What does it mean to forgive others?",
                        questionZh: "饒恕別人是什麼意思？",
                        questionZhHans: "饶恕别人是什么意思？",
                        verseReference: "Ephesians 4:32",
                        verseBook: "Ephesians",
                        verseChapter: 4,
                        verseNumber: 32
                    ),
                    AskQuestion(
                        question: "How can I find peace in stressful situations?",
                        questionZh: "在壓力情況下我如何能找到平安？",
                        questionZhHans: "在压力情况下我如何能找到平安？",
                        verseReference: "Philippians 4:6-7",
                        verseBook: "Philippians",
                        verseChapter: 4,
                        verseNumber: 6
                    ),
                    AskQuestion(
                        question: "How do I handle conflict biblically?",
                        questionZh: "我如何按照聖經處理衝突？",
                        questionZhHans: "我如何按照圣经处理冲突？"
                    ),
                    AskQuestion(
                        question: "What is my purpose as a Christian?",
                        questionZh: "作為基督徒，我的目的是什麼？",
                        questionZhHans: "作为基督徒，我的目的是什么？"
                    )
                ]
            )
        ]
    }
    
    func getCategory(id: String) -> AskCategory? {
        return categories.first { $0.id == id }
    }
}

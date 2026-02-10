// ReadingPlanStore - Manages reading plans and user progress

import Foundation
import Combine
import WidgetKit

class ReadingPlanStore: ObservableObject {
    static let shared = ReadingPlanStore()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "readingPlanProgress"
    private let customPlansKey = "customReadingPlans"
    
    @Published var defaultPlans: [ReadingPlan] = []
    @Published var customPlans: [ReadingPlan] = []
    @Published var progress: [String: ReadingPlanProgress] = [:]
    
    var plans: [ReadingPlan] {
        defaultPlans + customPlans
    }
    
    private init() {
        loadDefaultPlans()
        loadCustomPlans()
        loadProgress()
    }
    
    // MARK: - Plan Definitions
    
    private func loadDefaultPlans() {
        // Define the 5 default reading plans
        defaultPlans = [
            // 1. Gospel of John (7 days)
            ReadingPlan(
                id: "gospel-of-john",
                title: "Gospel of John",
                description: "Journey through the Gospel of John and discover the life and teachings of Jesus.",
                extendedDescription: "The Gospel of John offers a unique perspective on Jesus' ministry, focusing on His divine nature and the profound spiritual truths He revealed. This seven-day journey will deepen your understanding of who Jesus is, His miracles, and His teachings about eternal life, love, and the Holy Spirit. Each chapter reveals different aspects of Jesus' character and mission, making this one of the most transformative books in the Bible.",
                icon: "book.fill",
                imageName: "PlanBackground_John",
                days: [
                    ReadingPlanDay(dayNumber: 1, book: "John", chapter: 1, description: "The Word Became Flesh", chapterDescription: "This foundational chapter introduces Jesus as the eternal Word who became flesh. It's worth reading because it establishes Jesus' divine nature and pre-existence, showing how He is both fully God and fully human. The chapter also introduces John the Baptist and the first disciples, setting the stage for Jesus' ministry."),
                    ReadingPlanDay(dayNumber: 2, book: "John", chapter: 2, description: "The Wedding at Cana", chapterDescription: "Jesus performs His first miracle at a wedding, turning water into wine. This chapter reveals Jesus' compassion, power, and attention to everyday needs. It's worth reading because it shows that Jesus cares about our celebrations and can transform ordinary situations into extraordinary moments of grace."),
                    ReadingPlanDay(dayNumber: 3, book: "John", chapter: 3, description: "Jesus and Nicodemus", chapterDescription: "The famous conversation with Nicodemus about being 'born again' contains one of the most quoted verses in the Bible (John 3:16). This chapter is essential because it explains the core of salvation - faith in Jesus Christ - and reveals God's incredible love for humanity. It's a foundational passage for understanding Christianity."),
                    ReadingPlanDay(dayNumber: 4, book: "John", chapter: 4, description: "The Woman at the Well", chapterDescription: "Jesus breaks cultural barriers by speaking with a Samaritan woman, offering her living water. This chapter is worth reading because it demonstrates Jesus' radical love for all people, regardless of their background or past. It shows how Jesus meets us where we are and offers us something far greater than we could imagine."),
                    ReadingPlanDay(dayNumber: 5, book: "John", chapter: 5, description: "The Healing at the Pool", chapterDescription: "Jesus heals a man who had been disabled for 38 years. This chapter reveals Jesus' authority over sickness and His compassion for those who have been waiting and hoping. It's worth reading because it shows that Jesus can heal not just physical ailments but also the deeper wounds of our hearts."),
                    ReadingPlanDay(dayNumber: 6, book: "John", chapter: 6, description: "Feeding the Five Thousand", chapterDescription: "Jesus feeds thousands with just five loaves and two fish, then declares Himself the Bread of Life. This chapter is worth reading because it reveals Jesus as the source of true spiritual nourishment. It challenges us to look beyond physical needs to the deeper hunger of our souls that only Jesus can satisfy."),
                    ReadingPlanDay(dayNumber: 7, book: "John", chapter: 7, description: "Jesus at the Feast", chapterDescription: "Jesus teaches at the Feast of Tabernacles, revealing profound truths about living water and His divine origin. This chapter is worth reading because it shows Jesus' wisdom in the face of opposition and His invitation to come to Him for true satisfaction. It reveals the ongoing tension between belief and unbelief.")
                ],
                category: .book
            ),
            
            // 2. Psalms of Comfort (5 days)
            ReadingPlan(
                id: "psalms-of-comfort",
                title: "Psalms of Comfort",
                description: "Find peace and comfort in these beautiful psalms during difficult times.",
                extendedDescription: "These five carefully selected psalms have brought comfort and hope to countless believers throughout history. Each psalm addresses different aspects of God's care, protection, and presence in our lives. Whether you're facing anxiety, fear, uncertainty, or simply need reassurance, these timeless words will remind you of God's unfailing love and faithfulness. These psalms are particularly powerful because they speak directly to the human heart, expressing both our struggles and God's response.",
                icon: "heart.fill",
                imageName: "PlanBackground_Psalms",
                days: [
                    ReadingPlanDay(dayNumber: 1, book: "Psalms", chapter: 23, description: "The Lord is My Shepherd", chapterDescription: "Perhaps the most beloved psalm, this chapter paints a beautiful picture of God as our caring shepherd. It's worth reading because it reminds us that we lack nothing when God is our guide. The imagery of green pastures, still waters, and the valley of the shadow of death speaks to every season of life, offering comfort and assurance of God's constant presence."),
                    ReadingPlanDay(dayNumber: 2, book: "Psalms", chapter: 46, description: "God is Our Refuge", chapterDescription: "This powerful psalm declares that God is our refuge and strength, an ever-present help in trouble. It's worth reading because it addresses our deepest fears - even when mountains fall and waters roar. The famous verse 'Be still and know that I am God' invites us into peace that transcends circumstances, making this essential reading for anyone facing uncertainty or chaos."),
                    ReadingPlanDay(dayNumber: 3, book: "Psalms", chapter: 91, description: "He Who Dwells in the Secret Place", chapterDescription: "A psalm of divine protection and security, this chapter promises God's covering for those who trust in Him. It's worth reading because it speaks directly to our need for safety and peace. The promises of protection, deliverance, and God's presence offer profound comfort, especially during times when we feel vulnerable or afraid."),
                    ReadingPlanDay(dayNumber: 4, book: "Psalms", chapter: 121, description: "My Help Comes from the Lord", chapterDescription: "This beautiful psalm of ascent reminds us that our help comes from the Lord, the Maker of heaven and earth. It's worth reading because it shifts our focus from our problems to God's power. The repeated assurance that God watches over us - never sleeping, never slumbering - provides incredible comfort for those who feel alone or overwhelmed."),
                    ReadingPlanDay(dayNumber: 5, book: "Psalms", chapter: 139, description: "Search Me, O God", chapterDescription: "A deeply personal psalm about God's intimate knowledge of us, this chapter celebrates being fully known and fully loved. It's worth reading because it addresses our deepest need for acceptance and understanding. The invitation to 'search me and know my heart' is both vulnerable and freeing, offering a path to authentic relationship with God.")
                ],
                category: .topical
            ),
            
            // 3. Sermon on the Mount (7 days)
            ReadingPlan(
                id: "sermon-on-the-mount",
                title: "Sermon on the Mount",
                description: "Explore Jesus' most famous teaching on living a blessed life.",
                extendedDescription: "The Sermon on the Mount is considered Jesus' most comprehensive teaching on how to live as citizens of God's kingdom. This revolutionary message turns worldly wisdom upside down, teaching that the poor in spirit, the meek, and the persecuted are actually blessed. Over seven days, you'll explore Jesus' teachings on prayer, forgiveness, worry, and authentic righteousness. This sermon challenges us to examine our hearts, motives, and priorities, offering a radical vision of what it means to follow Christ. It's worth reading because it provides the foundation for Christian ethics and reveals the heart of God's kingdom values.",
                icon: "mountain.2.fill",
                imageName: "PlanBackground_Sermon",
                days: [
                    ReadingPlanDay(dayNumber: 1, book: "Matthew", chapter: 5, verseStart: 1, verseEnd: 16, description: "The Beatitudes", chapterDescription: "The Beatitudes open Jesus' sermon with a revolutionary definition of blessing. This passage is worth reading because it completely redefines what it means to be blessed, challenging our cultural assumptions. Jesus declares that those who are poor in spirit, mourn, are meek, and hunger for righteousness are the truly blessed ones. This foundational teaching sets the tone for the entire sermon and invites us into a countercultural way of living."),
                    ReadingPlanDay(dayNumber: 2, book: "Matthew", chapter: 5, verseStart: 17, verseEnd: 48, description: "The Law and Righteousness", chapterDescription: "Jesus deepens the understanding of the Law, teaching that true righteousness goes beyond external actions to the heart. This passage is worth reading because it reveals God's standard of perfection and calls us to a higher level of love - even loving our enemies. The famous 'You have heard it said... but I tell you' statements challenge us to examine our motives and attitudes, not just our actions."),
                    ReadingPlanDay(dayNumber: 3, book: "Matthew", chapter: 6, verseStart: 1, verseEnd: 18, description: "Giving, Prayer, and Fasting", chapterDescription: "Jesus teaches about authentic spiritual practices done in secret, not for show. This passage is worth reading because it includes the Lord's Prayer - a model for how to pray. It challenges us to examine our motives in spiritual disciplines, reminding us that God sees what's done in secret and rewards genuine faith. This teaching transforms how we approach giving, prayer, and fasting."),
                    ReadingPlanDay(dayNumber: 4, book: "Matthew", chapter: 6, verseStart: 19, verseEnd: 34, description: "Treasures in Heaven", chapterDescription: "Jesus addresses our relationship with money and worry, teaching us to store up treasures in heaven and trust God for our daily needs. This passage is worth reading because it speaks directly to our anxieties about provision and security. The famous 'do not worry' teaching reminds us of God's care for even the smallest creatures and invites us into a life of trust and freedom from anxiety."),
                    ReadingPlanDay(dayNumber: 5, book: "Matthew", chapter: 7, verseStart: 1, verseEnd: 14, description: "Judging Others", chapterDescription: "Jesus warns against judgmentalism and teaches about asking, seeking, and knocking. This passage is worth reading because it addresses our tendency to be critical of others while ignoring our own faults. The 'plank in your own eye' teaching is both humorous and convicting, while the promise that God gives good gifts to those who ask encourages us to approach God with confidence."),
                    ReadingPlanDay(dayNumber: 6, book: "Matthew", chapter: 7, verseStart: 15, verseEnd: 29, description: "True and False Disciples", chapterDescription: "Jesus concludes with warnings about false prophets and the importance of building on a solid foundation. This passage is worth reading because it challenges us to examine whether we're truly following Jesus or just going through the motions. The parable of the wise and foolish builders reminds us that hearing Jesus' words isn't enough - we must put them into practice."),
                    ReadingPlanDay(dayNumber: 7, book: "Matthew", chapter: 5, description: "Review: The Entire Sermon", chapterDescription: "Take time to review the entire Sermon on the Mount (chapters 5-7) to see how all the teachings connect. This review is worth doing because it helps you see the big picture of Jesus' message and how each part relates to the whole. Reflecting on the entire sermon allows you to grasp the comprehensive vision Jesus offers for kingdom living.")
                ],
                category: .devotional
            ),
            
            // 4. Finding Peace (5 days)
            ReadingPlan(
                id: "finding-peace",
                title: "Finding Peace",
                description: "Discover God's peace through these verses that bring comfort and hope.",
                extendedDescription: "In a world filled with anxiety, stress, and uncertainty, God offers us a peace that transcends understanding. This five-day plan brings together powerful passages from both Old and New Testaments that speak directly to our need for peace. These verses reveal that God's peace isn't the absence of trouble, but a deep sense of security and well-being that comes from trusting in Him. Whether you're facing personal struggles, global concerns, or simply the daily pressures of life, these passages will guide you toward the peace that only God can provide.",
                icon: "leaf.fill",
                imageName: "PlanBackground_Peace",
                days: [
                    ReadingPlanDay(dayNumber: 1, book: "Philippians", chapter: 4, verseStart: 4, verseEnd: 9, description: "The Peace of God", chapterDescription: "Paul writes from prison about a peace that 'transcends all understanding.' This passage is worth reading because it shows that peace is possible even in difficult circumstances. The call to rejoice, pray, and give thanks leads to God's peace guarding our hearts. It's a practical guide for finding peace through prayer and gratitude, regardless of our situation."),
                    ReadingPlanDay(dayNumber: 2, book: "Isaiah", chapter: 26, verseStart: 1, verseEnd: 12, description: "Perfect Peace", chapterDescription: "Isaiah promises 'perfect peace' to those whose minds are stayed on God. This passage is worth reading because it reveals the connection between our focus and our peace. When we trust in God and keep our minds fixed on Him, we experience a stability and peace that the world cannot give or take away. It's a powerful promise for anxious hearts."),
                    ReadingPlanDay(dayNumber: 3, book: "John", chapter: 14, verseStart: 25, verseEnd: 31, description: "Peace I Leave with You", chapterDescription: "Jesus promises His disciples a peace that is different from what the world offers. This passage is worth reading because it comes from Jesus' final words before His crucifixion - a time when peace seemed impossible. Jesus' peace isn't dependent on circumstances but on His presence and the Holy Spirit's work in our lives. It's a peace we can have even when everything around us is chaotic."),
                    ReadingPlanDay(dayNumber: 4, book: "Romans", chapter: 8, verseStart: 28, verseEnd: 39, description: "More Than Conquerors", chapterDescription: "Paul declares that nothing can separate us from God's love and that we are 'more than conquerors.' This passage is worth reading because it addresses our deepest fears about being alone or abandoned. The assurance that God works all things for good and that nothing can separate us from His love provides profound peace, even in the face of trials and difficulties."),
                    ReadingPlanDay(dayNumber: 5, book: "Psalms", chapter: 37, verseStart: 1, verseEnd: 11, description: "Trust in the Lord", chapterDescription: "This psalm encourages us to trust in the Lord and not fret about evildoers. It's worth reading because it addresses our tendency to worry about injustice and unfairness. The promise that those who trust in the Lord will inherit the land and delight themselves in abundance offers peace by shifting our focus from what's wrong to who God is. It's a call to rest in God's timing and justice.")
                ],
                category: .topical
            ),
            
            // 5. Proverbs Wisdom (7 days)
            ReadingPlan(
                id: "proverbs-wisdom",
                title: "Proverbs Wisdom",
                description: "Daily wisdom from Proverbs to guide your life and decisions.",
                extendedDescription: "The book of Proverbs is a treasure trove of practical wisdom for everyday living. Written primarily by King Solomon, the wisest man who ever lived, these proverbs offer guidance on relationships, work, money, speech, and character. This seven-day journey through key chapters will help you develop wisdom that goes beyond knowledge - wisdom that leads to a life of blessing, favor, and purpose. Each chapter addresses different aspects of wise living, from the fear of the Lord (the beginning of wisdom) to practical advice for daily decisions. It's worth reading because wisdom is more valuable than gold and leads to a life well-lived.",
                icon: "lightbulb.fill",
                imageName: "PlanBackground_Proverbs",
                days: [
                    ReadingPlanDay(dayNumber: 1, book: "Proverbs", chapter: 1, description: "The Beginning of Knowledge", chapterDescription: "This opening chapter establishes that 'the fear of the Lord is the beginning of knowledge.' It's worth reading because it sets the foundation for all wisdom - recognizing God's authority and seeking His guidance. The chapter warns against the enticement of sinners and personifies wisdom as calling out in the streets, inviting us to choose the path of understanding over foolishness."),
                    ReadingPlanDay(dayNumber: 2, book: "Proverbs", chapter: 3, description: "Trust in the Lord", chapterDescription: "One of the most beloved chapters, this passage teaches us to trust in the Lord with all our heart and lean not on our own understanding. It's worth reading because it contains some of the most quoted verses about wisdom, including promises about God directing our paths and giving us favor. The chapter emphasizes the connection between trusting God and experiencing His blessing in our lives."),
                    ReadingPlanDay(dayNumber: 3, book: "Proverbs", chapter: 4, description: "Get Wisdom", chapterDescription: "This chapter emphasizes the supreme value of wisdom, encouraging us to 'get wisdom' above all else. It's worth reading because it shows wisdom as something to be pursued, guarded, and cherished. The imagery of wisdom as a crown and a path of light encourages us to make wisdom a priority in our lives, recognizing it as more valuable than any material possession."),
                    ReadingPlanDay(dayNumber: 4, book: "Proverbs", chapter: 8, description: "Wisdom's Call", chapterDescription: "Wisdom is personified as calling out to humanity, describing her value and benefits. This chapter is worth reading because it reveals wisdom as something accessible and desirable, not hidden or exclusive. The description of wisdom being present at creation and delighting in humanity shows that wisdom is foundational to how the world works and is available to all who seek it."),
                    ReadingPlanDay(dayNumber: 5, book: "Proverbs", chapter: 10, description: "Wise Sayings", chapterDescription: "This chapter begins a collection of individual proverbs, each offering practical wisdom for daily life. It's worth reading because it covers topics like work ethic, speech, integrity, and relationships. These bite-sized pieces of wisdom are easy to remember and apply, making them valuable for daily decision-making and character development."),
                    ReadingPlanDay(dayNumber: 6, book: "Proverbs", chapter: 15, description: "A Gentle Answer", chapterDescription: "This chapter focuses on the power of words and attitudes, teaching that 'a gentle answer turns away wrath.' It's worth reading because it addresses how we communicate and relate to others. The contrast between wise and foolish speech, as well as the emphasis on a cheerful heart, provides practical guidance for improving our relationships and daily interactions."),
                    ReadingPlanDay(dayNumber: 7, book: "Proverbs", chapter: 31, description: "The Virtuous Woman", chapterDescription: "This famous chapter describes an excellent wife and mother, but its principles apply to all who seek to live wisely. It's worth reading because it shows wisdom in action - not just in words but in character, work ethic, and care for others. The description of someone who fears the Lord and is praised by her family offers a beautiful picture of wisdom lived out in everyday life.")
                ],
                category: .book
            )
        ]
    }
    
    // MARK: - Progress Management
    
    func startPlan(_ planId: String) {
        var planProgress = progress[planId] ?? ReadingPlanProgress(planId: planId)
        if planProgress.currentDay < 0 {
            planProgress.currentDay = 0
            planProgress.startedAt = Date()
        }
        progress[planId] = planProgress
        saveProgress()
        syncToWidget()
    }
    
    func completeDay(_ planId: String, dayNumber: Int) {
        var planProgress = progress[planId] ?? ReadingPlanProgress(planId: planId)
        planProgress.completedDays.insert(dayNumber)
        planProgress.lastReadAt = Date()
        
        // Advance to next day if this was the current day
        if planProgress.currentDay == dayNumber - 1 {
            planProgress.currentDay = dayNumber
        }
        
        progress[planId] = planProgress
        saveProgress()
        syncToWidget()
    }
    
    // MARK: - Widget Sync
    
    private func syncToWidget() {
        Task { @MainActor in
            WidgetDataSync.shared.syncToWidget()
        }
    }
    
    func getProgress(for planId: String) -> ReadingPlanProgress? {
        return progress[planId]
    }
    
    func getProgressPercentage(for planId: String) -> Double {
        guard let plan = plans.first(where: { $0.id == planId }),
              let planProgress = progress[planId] else {
            return 0
        }
        
        if planProgress.completedDays.isEmpty {
            return 0
        }
        
        return Double(planProgress.completedDays.count) / Double(plan.duration) * 100
    }
    
    func getCurrentDay(for planId: String) -> ReadingPlanDay? {
        guard let plan = plans.first(where: { $0.id == planId }),
              let planProgress = progress[planId],
              planProgress.currentDay >= 0,
              planProgress.currentDay < plan.days.count else {
            // Return first day if plan exists, nil otherwise
            if let plan = plans.first(where: { $0.id == planId }) {
                return plan.days.first
            }
            return nil
        }
        
        return plan.days[planProgress.currentDay]
    }
    
    func getTodayReading(for planId: String) -> ReadingPlanDay? {
        guard let plan = plans.first(where: { $0.id == planId }) else {
            return nil
        }
        
        guard let planProgress = progress[planId] else {
            return plan.days.first
        }
        
        if planProgress.currentDay < 0 {
            return plan.days.first
        }
        
        // Return current day if not completed, otherwise next day
        let currentDay = plan.days[planProgress.currentDay]
        if planProgress.completedDays.contains(currentDay.dayNumber) {
            // Move to next day if current is completed
            if planProgress.currentDay + 1 < plan.days.count {
                return plan.days[planProgress.currentDay + 1]
            }
        }
        
        return currentDay
    }
    
    // MARK: - Persistence
    
    private func loadProgress() {
        guard let data = userDefaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: ReadingPlanProgress].self, from: data) else {
            progress = [:]
            return
        }
        
        progress = decoded
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            userDefaults.set(encoded, forKey: progressKey)
        }
    }
    
    // MARK: - Today's Progress Stats
    
    /// Get the count of plan days completed today across all active plans
    func getTodayPlanDaysCompleted() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var count = 0
        for (_, planProgress) in progress {
            if let lastReadAt = planProgress.lastReadAt,
               calendar.isDate(lastReadAt, inSameDayAs: today) {
                // Count days completed today
                // We track this by checking if lastReadAt is today and there are completed days
                count += 1
            }
        }
        return count
    }
    
    /// Get all active plans (plans that have been started but not completed)
    func getActivePlans() -> [(plan: ReadingPlan, progress: ReadingPlanProgress)] {
        return plans.compactMap { plan in
            guard let planProgress = progress[plan.id],
                  planProgress.isStarted,
                  planProgress.completedDays.count < plan.duration else {
                return nil
            }
            return (plan, planProgress)
        }
    }
    
    /// Get total days completed across all plans
    func getTotalDaysCompleted() -> Int {
        return progress.values.reduce(0) { $0 + $1.completedDays.count }
    }
    
    // MARK: - Custom Plans Management
    
    // Valid SF Symbols for reading plans
    private static let validIcons: Set<String> = [
        "book.fill", "heart.fill", "lightbulb.fill", "leaf.fill", "mountain.2.fill",
        "star.fill", "sun.max.fill", "sparkles", "cross.fill",
        "hand.raised.fill", "person.fill", "figure.walk", "figure.mind.and.body",
        "water.waves", "moon.fill", "bolt.fill", "shield.fill", "crown.fill",
        "graduationcap.fill", "book.closed.fill", "text.book.closed.fill",
        "globe.americas.fill", "hands.clap.fill", "heart.text.square.fill"
    ]
    
    private func loadCustomPlans() {
        guard let data = userDefaults.data(forKey: customPlansKey),
              let decoded = try? JSONDecoder().decode([ReadingPlan].self, from: data) else {
            customPlans = []
            return
        }
        // Sanitize icons for any plans with invalid SF Symbols
        customPlans = decoded.map { plan in
            if Self.validIcons.contains(plan.icon) {
                return plan
            } else {
                // Return plan with valid fallback icon
                return ReadingPlan(
                    id: plan.id,
                    title: plan.title,
                    description: plan.description,
                    extendedDescription: plan.extendedDescription,
                    icon: "book.fill",
                    imageName: plan.imageName,
                    days: plan.days,
                    category: plan.category
                )
            }
        }
    }
    
    private func saveCustomPlans() {
        if let encoded = try? JSONEncoder().encode(customPlans) {
            userDefaults.set(encoded, forKey: customPlansKey)
        }
    }
    
    func addCustomPlan(_ plan: ReadingPlan) {
        // Ensure ID is unique
        var planToAdd = plan
        if planToAdd.id.isEmpty || plans.contains(where: { $0.id == planToAdd.id }) {
            planToAdd = ReadingPlan(
                id: "custom-\(UUID().uuidString)",
                title: plan.title,
                description: plan.description,
                extendedDescription: plan.extendedDescription,
                icon: plan.icon,
                imageName: plan.imageName,
                days: plan.days,
                category: plan.category
            )
        }
        customPlans.append(planToAdd)
        saveCustomPlans()
    }
    
    func deleteCustomPlan(_ planId: String) {
        customPlans.removeAll { $0.id == planId }
        // Also remove progress if exists
        progress.removeValue(forKey: planId)
        // Release the background assignment so it can be reused
        SereneBackgroundManager.shared.removePlanBackground(for: planId)
        saveCustomPlans()
        saveProgress()
    }
    
    func isCustomPlan(_ planId: String) -> Bool {
        return customPlans.contains(where: { $0.id == planId })
    }
}

// AIService+Defaults - Fallback content when AI calls fail

import Foundation

extension AIService {

    // MARK: - Fallback Content

    func getFallbackVerse(for reflection: String, language: AppLanguage) -> ScriptureEchoResponse {
        let isChinese = isChineseLanguage(language)
        let lowercasedReflection = reflection.lowercased()

        let anxietyKeywords = ["stress", "anxious", "worry", "afraid", "fear", "overwhelm", "pressure", "壓力", "焦慮", "擔心", "害怕"]
        let griefKeywords = ["loss", "grief", "death", "died", "miss", "gone", "sad", "mourn", "失去", "傷心", "難過", "思念"]
        let directionKeywords = ["lost", "direction", "purpose", "confused", "uncertain", "future", "path", "迷失", "方向", "未來", "困惑"]
        let healingKeywords = ["sick", "heal", "pain", "hurt", "broken", "病", "醫治", "痛", "受傷"]
        let peaceKeywords = ["peace", "calm", "rest", "quiet", "still", "平安", "安靜", "休息"]

        if anxietyKeywords.contains(where: { lowercasedReflection.contains($0) }) {
            return ScriptureEchoResponse(
                echo: nil,
                verseReference: "Philippians 4:6-7",
                verseText: isChinese
                    ? "應當一無掛慮，只要凡事藉著禱告、祈求和感謝，將你們所要的告訴神。神所賜出人意外的平安，必在基督耶穌裡保守你們的心懷意念。"
                    : "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus."
            )
        }

        if griefKeywords.contains(where: { lowercasedReflection.contains($0) }) {
            return ScriptureEchoResponse(
                echo: nil,
                verseReference: "Psalm 34:18",
                verseText: isChinese
                    ? "耶和華靠近傷心的人，拯救靈性痛悔的人。"
                    : "The Lord is close to the brokenhearted and saves those who are crushed in spirit."
            )
        }

        if directionKeywords.contains(where: { lowercasedReflection.contains($0) }) {
            return ScriptureEchoResponse(
                echo: nil,
                verseReference: "Proverbs 3:5-6",
                verseText: isChinese
                    ? "你要專心仰賴耶和華，不可倚靠自己的聰明，在你一切所行的事上都要認定他，他必指引你的路。"
                    : "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight."
            )
        }

        if healingKeywords.contains(where: { lowercasedReflection.contains($0) }) {
            return ScriptureEchoResponse(
                echo: nil,
                verseReference: "Psalm 147:3",
                verseText: isChinese
                    ? "他醫好傷心的人，裹好他們的傷處。"
                    : "He heals the brokenhearted and binds up their wounds."
            )
        }

        if peaceKeywords.contains(where: { lowercasedReflection.contains($0) }) {
            return ScriptureEchoResponse(
                echo: nil,
                verseReference: "Isaiah 41:10",
                verseText: isChinese
                    ? "你不要害怕，因為我與你同在；不要驚惶，因為我是你的神。我必堅固你，我必幫助你，我必用我公義的右手扶持你。"
                    : "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand."
            )
        }

        return ScriptureEchoResponse(
            echo: nil,
            verseReference: "Psalm 46:10",
            verseText: isChinese
                ? "你們要休息，要知道我是神。"
                : "Be still, and know that I am God."
        )
    }

    func getDefaultBookIntros(language: AppLanguage) -> [RecommendedBook] {
        let isChinese = isChineseLanguage(language)
        let now = Date()

        if isChinese {
            return [
                RecommendedBook(bookName: "Psalms", personalizedIntro: "給每個季節的心靈詩歌", recommendedAt: now),
                RecommendedBook(bookName: "Matthew", personalizedIntro: "與耶穌同行，日復一日", recommendedAt: now),
                RecommendedBook(bookName: "Philippians", personalizedIntro: "不論環境如何都有的喜樂", recommendedAt: now)
            ]
        } else {
            return [
                RecommendedBook(bookName: "Psalms", personalizedIntro: "Songs for every season of the heart", recommendedAt: now),
                RecommendedBook(bookName: "Matthew", personalizedIntro: "Walking with Jesus, day by day", recommendedAt: now),
                RecommendedBook(bookName: "Philippians", personalizedIntro: "Joy that doesn't depend on circumstances", recommendedAt: now)
            ]
        }
    }

    func getDefaultPrayer(name: String, language: AppLanguage) -> String {
        let isChinese = isChineseLanguage(language)
        let displayName = name.isEmpty ? (isChinese ? "這位朋友" : "this friend") : name

        if isChinese {
            return """
            親愛的天父，
            
            感謝祢帶領\(displayName)來到這裡，開始這段與祢同行的旅程。
            祢知道\(displayName)心中所承載的一切渴望與疑問。
            求祢在每一天中與\(displayName)同行，賜下智慧與平安。
            願祢的話語成為腳前的燈、路上的光，照亮前方的道路。
            求祢堅固\(displayName)的信心，在每一個季節中都能經歷祢豐盛的愛。
            
            奉耶穌的名禱告，
            """
        } else {
            return """
            Dear Heavenly Father,
            
            Thank you for bringing \(displayName) here to begin this journey with You.
            You know the questions, hopes, and longings that \(displayName) carries.
            Walk with \(displayName) each day, granting wisdom and peace along the way.
            May Your Word be a lamp for their feet and a light on their path.
            Strengthen \(displayName)'s faith and let them experience Your abundant love in every season.
            
            In Jesus' name,
            """
        }
    }

    func getDefaultRelatedVerses(language: AppLanguage) -> [OnboardingRecommendedVerse] {
        let isChinese = isChineseLanguage(language)
        let now = Date()

        if isChinese {
            return [OnboardingRecommendedVerse(
                reference: "詩篇 46:10",
                text: "你們要休息，要知道我是神！",
                reason: "在忙碌中找到安息，認識神的同在。",
                recommendedAt: now
            )]
        } else {
            return [OnboardingRecommendedVerse(
                reference: "Psalm 46:10",
                text: "Be still, and know that I am God.",
                reason: "A moment of stillness as you begin your journey with Scripture.",
                recommendedAt: now
            )]
        }
    }

    func getDefaultDeepDiveQuestion(language: AppLanguage) -> DeepDiveQuestion {
        let isChinese = isChineseLanguage(language)
        let isSpanish = language == .spanish

        if isChinese {
            return DeepDiveQuestion(
                question: "在你的信仰旅程中，你最想深入探索什麼？",
                options: [
                    "更認識神的話語",
                    "在禱告中經歷更深的連結",
                    "在困難中找到平安",
                    "在日常生活中活出信仰"
                ]
            )
        } else if isSpanish {
            return DeepDiveQuestion(
                question: "En tu camino de fe, ¿qué te gustaría explorar más profundamente?",
                options: [
                    "Conocer mejor la Palabra de Dios",
                    "Experimentar una conexión más profunda en la oración",
                    "Encontrar paz en los momentos difíciles",
                    "Vivir mi fe en la vida diaria"
                ]
            )
        } else {
            return DeepDiveQuestion(
                question: "In your faith journey, what would you most like to explore?",
                options: [
                    "Understanding God's Word more deeply",
                    "Experiencing deeper connection in prayer",
                    "Finding peace in difficult times",
                    "Living out my faith in daily life"
                ]
            )
        }
    }
}

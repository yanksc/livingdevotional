// AIService+Journey - Faith journey analysis

import Foundation

extension AIService {

    // MARK: - Journey Analysis

    func analyzeJourney(data: JourneyDataForAI, appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)

        let readingBooksStr = data.readingHistory.isEmpty ? (isChinese ? "尚無閱讀記錄" : "No reading history yet") : data.readingHistory.joined(separator: ", ")
        let savedBooksStr = data.savedVerseBooks.isEmpty ? (isChinese ? "尚無保存經文" : "No saved verses yet") : data.savedVerseBooks.joined(separator: ", ")
        let labelsStr = data.savedVerseLabels.isEmpty ? (isChinese ? "無標籤" : "No labels") : data.savedVerseLabels.joined(separator: ", ")
        let goalsStr = data.spiritualGoals.isEmpty ? (isChinese ? "尚未設定目標" : "No goals set") : data.spiritualGoals.joined(separator: ", ")

        let customPrayersStr = formatIntentionalActions(data.customPrayers, typeLabel: isChinese ? "自訂禱告" : "Custom Prayers", isChinese: isChinese)
        let prayerTopicsStr = formatIntentionalActions(data.prayerTopics, typeLabel: isChinese ? "禱告主題" : "Prayer Topics", isChinese: isChinese)
        let questionsStr = formatIntentionalActions(data.questions, typeLabel: isChinese ? "提問" : "Questions", isChinese: isChinese)
        let savedNotesWithContentStr = formatIntentionalActions(data.savedNotesWithContent, typeLabel: isChinese ? "有筆記的保存經文" : "Saved Notes with Content", isChinese: isChinese)
        let savedNotesWithoutContentStr = formatIntentionalActions(data.savedNotesWithoutContent, typeLabel: isChinese ? "無筆記的保存經文" : "Saved Notes (no content)", isChinese: isChinese)
        let recentActionsStr = formatIntentionalActions(data.recentActions, typeLabel: isChinese ? "最近5個行動" : "Recent 5 Actions", isChinese: isChinese)

        let prompt: String
        if isChinese {
            prompt = """
            你是一位溫暖的聖經學者和屬靈導師。請根據以下用戶的信仰成長數據，生成一份個人化的分析報告——深入探討用戶所接觸的具體經文的神學意義（救恩、恩典、重生、犧牲、禱告的力量、神的公義等），不要流於表面或給出空洞的鼓勵；要具體且以聖經為根基。

            用戶資料：
            - 名字：\(data.userName.isEmpty ? "朋友" : data.userName)
            - 靈命階段：\(data.spiritualMaturity)
            - 目標：\(goalsStr)

            **【最重要】最近5個行動 - 這些最能反映用戶目前的屬靈狀態和關注焦點：**
            \(recentActionsStr)

            **【最近閱讀歷程】（高優先級 - 反映用戶的閱讀模式和關注領域）：**
            \(readingBooksStr)

            **請優先分析用戶的「有意識行為」，這些行為更能反映他們的屬靈狀態和成長：**

            【優先級1 - 自訂禱告】（最重要，反映用戶的具體需要和與神的互動）
            \(customPrayersStr)

            【優先級2 - 禱告主題】（反映用戶的禱告模式）
            \(prayerTopicsStr)

            【優先級3 - 提問】（反映用戶的思考和探索）
            \(questionsStr)

            【優先級4 - 有筆記的保存經文】（反映用戶對經文的深入思考）
            \(savedNotesWithContentStr)

            【優先級5 - 無筆記的保存經文】（反映用戶感興趣的經文）
            \(savedNotesWithoutContentStr)

            【背景數據】（參考用，權重較低）
            - 總共閱讀章數：\(data.stats.totalChaptersRead)
            - 保存經文數：\(data.stats.totalVersesSaved)
            - 連續簽到天數：\(data.currentStreak)
            - 總活躍天數：\(data.totalDaysActive)
            - 保存經文的書卷：\(savedBooksStr)
            - 使用的標籤：\(labelsStr)

            請生成以下內容（以JSON格式回應）：

            {
              "pathStatus": {
                "title": "路上的你 - 必須基於最近5個行動中的實際經文內容和用戶行為，創造一個具體、有創意、令人印象深刻的狀態描述。例如：如果用戶最近保存了約翰福音3:16並寫了關於愛的筆記，可以說「在愛的真理中扎根」；如果最近為焦慮禱告並使用腓立比書4:6-7，可以說「在憂慮中尋求平安」。絕對不要用模糊的詞彙如「成長中」、「理解中」等。要具體引用經文主題或用戶關注的屬靈主題。",
                "subtitle": "溫暖的一句話（15-20字），回應用戶最近的行動。要具體且貼近他們當前的狀態。",
                "description": "深入的經文神學反思（約600字）。針對用戶最近互動的每節經文，深入解釋那節經文的核心屬靈意義——它所承載的神學真理（例如：以弗所書2:8，解釋恩典作為神的白白恩賜；約翰福音3:3，解釋屬靈重生意味著身份的徹底更新；腓立比書4:6，解釋代禱禱告的力量；羅馬書1，解釋神藉信心所顯明的公義）。當引用某節經文時，若能幫助讀者更深理解，請選擇性地直接引用經文原文（例如：「你們要將一切的憂慮卸給神，因為他顧念你們。」（彼得前書5:7）），但不必每節都引用——只在能讓閱讀體驗更流暢時才使用。絕不要只說「信心成長」「屬靈成長」這類空泛的詞；要明確指出用戶所專注的具體屬靈維度，例如：救贖（他付出的代價）、犧牲（捨己的呼召）、慈善（對他人的憐憫行動）、神聖的愛/agape（無條件的愛）、誠信（在神面前的正直）、信心（在試煉中的倚靠）、順服（回應神的呼召）、盼望（末世的應許）、悔改（更新的轉向）、恩典（白白的恩賜）、公義（神的聖潔標準）、成聖（被神分別出來的過程）等。然後，將這些具體真理與用戶對這些經文的實際互動方式聯繫起來，呈現一幅有深度的屬靈圖像。避免使用「很好地投入聖經」「建立穩固基礎」「豐富屬靈生命」等空洞套話。每一句話都要紮根於用戶實際閱讀的經文內容，讓讀者感受到這份分析是為他們量身定做的。請寫出完整、豐富的反思，不要截短，這是用戶閱讀的主要內容。",
                "iconName": "SF Symbol 名稱（如 figure.walk, heart.fill, lightbulb.fill, star.fill, cross.fill, sparkles, hands.sparkles.fill）"
              },
              "pathHighlights": [
                {"emoji": "📖", "fact": "第一個亮點：必須直接引用用戶的具體行為。例如：若用戶保存了詩篇23:4，就寫「你將詩篇23:4納入收藏——『我雖然行過死蔭的幽谷，也不怕遭害，因為你與我同在。』」；若為焦慮禱告，就寫「你根據腓立比書4:6——『應當一無掛慮，只要凡事藉著禱告、祈求』——帶著這份掛慮來到神面前」。加引文時只在該經文真正有助讀者理解時使用，不必每條都引用。禁止泛泛建議如「親近神」「保持信心」"},
                {"emoji": "⭐", "fact": "第二個亮點：必須基於閱讀歷史或實際數據。例如：若讀了約翰福音，就寫「你最近探索約翰福音——那本記錄神成為肉身、以救贖的愛進入世界的書卷」；若有連續簽到，就寫「連續7天堅持讀經，展現出日常順服的操練」。禁止空洞鼓勵"},
                {"emoji": "✨", "fact": "第三個亮點：必須是從筆記、禱告或提問中觀察到的具體主題。例如：筆記提到「愛」，就寫「你的筆記聚焦於愛——那種出於agape、無條件的神聖之愛」；若提問關於苦難，就寫「你在思考苦難的意義——這是信仰誠實性的標誌」。禁止通用靈修套話"}
              ],
              "recommendedReading": {
                "book": "英文書名（如 Philippians）",
                "chapter": 4,
                "reason": "為什麼推薦這一章（20-30字），要與用戶目前的焦點相關"
              }
            }

            **重要規則：**
            1. 語氣要溫暖但分析性 - 避免過度情緒化的語言
            2. **pathStatus.subtitle 必須是溫暖的一句話（15-20字）**：回應用戶最近的行動，要具體且貼近他們當前的狀態
            3. **pathStatus.description 是主要內容（約600字）**：深入的經文神學反思——針對用戶互動的每節經文，深入解釋它真正的屬靈意義（例如：以弗所書2:8 = 恩典是神白白賜予的禮物，不是人的努力所能得；約翰福音3:3 = 屬靈重生意味著身份的徹底更新；腓立比書4:6 = 禱告是將憂慮交託給神的具體行動；羅馬書1 = 神藉信心所顯明的公義）。當引用某節經文有助於讀者理解時，選擇性地直接引用原文（如「你們要將一切的憂慮卸給神，因為他顧念你們。」彼得前書5:7），但無需每節都引用。絕不要只說「信心成長」「屬靈成長」；要明確點出具體屬靈維度：救贖、犧牲、慈善、神聖的愛/agape、誠信、信心、順服、盼望、悔改、恩典、公義、成聖等。將這些具體真理與用戶的實際互動聯繫起來，呈現有深度的個人化屬靈圖像。不要用「很好地投入聖經」「建立穩固基礎」「豐富屬靈生命」等空洞套話——每一句話都要紮根於用戶實際接觸的經文內容。這是用戶閱讀的主要內容，請寫出完整、豐富的反思，不要截短
            4. **pathStatus的title必須基於最近5個行動的實際內容**：仔細閱讀最近5個行動中的經文內容、筆記、禱告主題，創造一個具體、有創意、令人印象深刻的狀態描述
            5. **絕對避免模糊詞彙**：不要用「成長中」、「理解中」、「學習中」等泛泛而談的詞。要具體引用經文主題、屬靈主題或用戶關注的焦點
            6. **必須引用具體內容**：如果用戶最近保存了某節經文，pathStatus應該反映那節經文的主題；如果最近為某個主題禱告，應該反映那個主題；如果有筆記，應該反映筆記中的思考
            7. 優先分析用戶的「有意識行為」（自訂禱告、提問、筆記），這些比單純閱讀更能反映屬靈狀態
            8. 仔細閱讀用戶保存的經文內容和筆記，分析他們關注的主題和屬靈需要
            9. 「pathStatus」要描述用戶「在路徑上的狀態」，而不是「性格類型」。要反映他們如何與神的話語互動，以及目前的屬靈狀態
            10. 如果用戶有自訂禱告或筆記，要特別關注這些內容，分析他們關注的主題和需要
            11. **recommendedReading 必須推薦用戶尚未閱讀的章節**：根據他們最近的主題和屬靈需要，推薦一個具體的章節。book 必須用英文書名
            12. **pathHighlights 必須具體連結用戶的歷史數據**：每個亮點都要引用具體的經文、章節、禱告主題、筆記內容或閱讀行為。絕對禁止泛泛的靈修建議（如「親近神」「保持信心」「繼續成長」等）
            13. 只回傳JSON，不要其他文字
            """
        } else {
            prompt = """
            You are a warm biblical scholar and spiritual guide. Based on the following user's faith journey data, generate a personalized analysis that goes deep into the actual theological meaning of the specific verses they've engaged with — explaining what salvation, grace, rebirth, sacrifice, the power of prayer, God's righteousness, or any other doctrine those verses carry. Do not be generic or flattering; be specific and scripturally grounded.

            User Profile:
            - Name: \(data.userName.isEmpty ? "Friend" : data.userName)
            - Stage: \(data.spiritualMaturity)
            - Goals: \(goalsStr)

            **[MOST IMPORTANT] Recent 5 Actions - These best reflect user's current spiritual state and focus:**
            \(recentActionsStr)

            **[Recent Reading History] (High priority - reflects user's reading patterns and focus areas):**
            \(readingBooksStr)

            **IMPORTANT: Prioritize analyzing user's "intentional actions" - these better reflect their spiritual state and growth:**

            [Priority 1 - Custom Prayers] (Most important - reflects user's specific needs and interaction with God)
            \(customPrayersStr)

            [Priority 2 - Prayer Topics] (Reflects user's prayer patterns)
            \(prayerTopicsStr)

            [Priority 3 - Questions] (Reflects user's thinking and exploration)
            \(questionsStr)

            [Priority 4 - Saved Notes with Content] (Reflects user's deep reflection on verses)
            \(savedNotesWithContentStr)

            [Priority 5 - Saved Notes without Content] (Reflects verses user is interested in)
            \(savedNotesWithoutContentStr)

            [Background Data] (Reference only, lower weight)
            - Total chapters read: \(data.stats.totalChaptersRead)
            - Verses saved: \(data.stats.totalVersesSaved)
            - Current streak: \(data.currentStreak) days
            - Total active days: \(data.totalDaysActive)
            - Books with saved verses: \(savedBooksStr)
            - Labels used: \(labelsStr)

            Please generate the following content (respond in JSON format):

            {
              "pathStatus": {
                "title": "Along the Path - MUST be based on actual verse content and user actions from the recent 5 actions. Create a specific, creative, and impressive status description. For example: if user recently saved John 3:16 with a note about love, say 'Rooted in Love's Truth'; if recently prayed about anxiety using Philippians 4:6-7, say 'Seeking Peace in Worry'. NEVER use vague terms like 'growing', 'understanding', 'learning'. Must specifically reference verse themes or spiritual themes the user is focusing on.",
                "subtitle": "A warm one-liner (15-20 words) that echoes the user's most recent action. Be specific and close to their current state.",
                "description": "Deep scriptural reflection tied to the user's actual verses (~500 words). For each verse the user recently engaged with, explain in depth what that verse actually means spiritually — the core doctrine or truth it carries (e.g. for Ephesians 2:8, explain what grace as God's unearned gift means; for John 3:3, explain what spiritual rebirth entails; for Philippians 4:6, explain the power and posture of intercessory prayer; for Romans 1, explain the revelation of God's righteousness through faith). When quoting a specific verse, selectively include the actual verse text inline to make the reading experience smooth — e.g., 'Cast all your anxiety on him because he cares for you' (1 Peter 5:7) — but do NOT quote every verse, only when it helps the reader connect more deeply. Never say just 'growing faith' or 'building faith' — instead name the precise spiritual dimension the reader is engaged with, such as: redemption (the cost Christ paid), sacrifice (the call to self-denial), charity (acts of compassion toward others), agape love (unconditional love), integrity (uprightness before God), confidence (trust amid trials), obedience (responding to God's call), hope (eschatological promise), repentance (turning toward renewal), grace (unearned gift), righteousness (God's holy standard), sanctification (being set apart). Then weave in how the user's engagement with these specific truths shapes their personal journey. Root every sentence in the actual content of the verses they read. Go deep — do not truncate the analysis; this is the primary content the user reads.",
                "iconName": "SF Symbol name (e.g., figure.walk, heart.fill, lightbulb.fill, star.fill, cross.fill, sparkles, hands.sparkles.fill)"
              },
              "pathHighlights": [
                {"emoji": "📖", "fact": "First highlight: MUST cite a specific user action. E.g. if they saved Psalm 23:4, write 'You saved Psalm 23:4 — \"Even though I walk through the darkest valley, I will fear no evil, for you are with me.\"'; if they prayed about anxiety, write 'You brought your anxiety before God — as Philippians 4:6 invites: \"Do not be anxious about anything, but in every situation, by prayer and petition, present your requests to God.\"' Include the verse text only when it helps the reader connect more deeply, not for every entry. NEVER generic advice like 'stay close to God' or 'keep the faith'"},
                {"emoji": "⭐", "fact": "Second highlight: MUST be based on reading history or concrete data. E.g. if they read John, write 'You've been exploring John's gospel — the account of the Word made flesh, entering the world through sacrificial love'; if they have a streak, write '7 consecutive days of reading — a practice of daily obedience taking shape'. NEVER vague encouragement"},
                {"emoji": "✨", "fact": "Third highlight: MUST observe a specific theme from their notes, prayers, or questions. E.g. if a note mentions love, write 'Your notes orbit around agape love — the unconditional, self-giving love that defines the heart of the gospel'; if a question is about suffering, write 'You are wrestling with the meaning of suffering — one of the most honest marks of a searching faith'. NEVER generic spiritual platitudes"}
              ],
              "recommendedReading": {
                "book": "English book name (e.g., Philippians)",
                "chapter": 4,
                "reason": "Why this chapter is recommended (20-30 words), tied to user's current focus"
              }
            }

            **Important Rules:**
            1. Tone should be warm but analytical - avoid excessive emotional language
            2. **pathStatus.subtitle MUST be a warm one-liner (15-20 words)**: Echo the user's most recent action, be specific and close to their current state
            3. **pathStatus.description is the MAIN content (~500 words)**: Deep scriptural reflection — for each verse the user engaged with, explain in depth what it actually means theologically (e.g. Ephesians 2:8 = grace as God's unearned gift, not human effort; John 3:3 = spiritual rebirth as a complete transformation of identity; Philippians 4:6 = prayer as the act of casting anxiety onto God; Romans 1 = God's righteousness revealed through faith). When quoting a verse, selectively include the actual verse text inline (e.g., "Cast all your anxiety on him because he cares for you" — 1 Peter 5:7) to make the reading flow smooth — but NOT for every verse, only when it meaningfully helps the reader connect. Never say just "growing faith" or "building faith" — name the precise spiritual dimension: redemption, sacrifice, charity, agape love, integrity, confidence, obedience, hope, repentance, grace, righteousness, or sanctification. Weave these specific truths around the user's actual engagement. Never use generic phrases like "wonderful commitment", "building a strong foundation", or "enriching your spiritual journey" — root every sentence in the real content of the verses. This is the most important field — write a full, rich, comprehensive reflection that does not feel truncated
            4. **pathStatus title MUST be based on actual content from recent 5 actions**: Carefully read the verse content, notes, and prayer topics from the recent 5 actions, create a specific, creative, and impressive status description
            5. **Absolutely avoid vague terms**: Don't use generic phrases like "growing", "understanding", "learning". Must specifically reference verse themes, spiritual themes, or focus areas the user is engaging with
            6. **Must reference specific content**: If user recently saved a verse, pathStatus should reflect that verse's theme; if recently prayed about a topic, should reflect that topic; if has notes, should reflect the thoughts in those notes
            7. Prioritize analyzing user's "intentional actions" (custom prayers, questions, notes) - these better reflect spiritual state than just reading
            8. Carefully read the verse content and notes user saved, analyze themes they're focusing on and spiritual needs
            9. "pathStatus" should describe user's "status along the path", NOT a "personality type". Reflect how they interact with God's Word and their current spiritual state
            10. If user has custom prayers or notes, pay special attention to these contents, analyze themes and needs they're focusing on
            11. **recommendedReading MUST recommend a chapter the user has NOT yet read**: Based on their recent themes and spiritual needs, recommend a specific chapter. book must use English book names
            12. **pathHighlights MUST be tied to concrete user history**: Each highlight must cite specific verses, chapters, prayer topics, note content, or reading behavior. NEVER use generic spiritual advice (e.g. "stay close to God", "keep the faith", "continue growing")
            13. Return only JSON, no other text
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 5000
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "analyzeJourney")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8),
              let analysisJson = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }

        var pathStatus = PathStatus(title: "Along the Path", subtitle: "Beginning your journey", description: "Your spiritual path is just starting", iconName: "figure.walk")
        if let statusJson = analysisJson["pathStatus"] as? [String: Any] {
            pathStatus = PathStatus(
                title: statusJson["title"] as? String ?? "Along the Path",
                subtitle: statusJson["subtitle"] as? String ?? "Beginning your journey",
                description: statusJson["description"] as? String ?? "",
                iconName: statusJson["iconName"] as? String ?? "figure.walk"
            )
        } else if let personalityJson = analysisJson["readingPersonality"] as? [String: Any] {
            pathStatus = PathStatus(
                title: personalityJson["title"] as? String ?? "Along the Path",
                subtitle: personalityJson["subtitle"] as? String ?? "Beginning your journey",
                description: personalityJson["description"] as? String ?? "",
                iconName: personalityJson["iconName"] as? String ?? "figure.walk"
            )
        }

        var pathHighlights: [PathHighlight] = []
        if let highlightsJson = analysisJson["pathHighlights"] as? [[String: Any]] {
            pathHighlights = highlightsJson.map { PathHighlight(emoji: $0["emoji"] as? String ?? "✨", fact: $0["fact"] as? String ?? "") }
        } else if let factsJson = analysisJson["funFacts"] as? [[String: Any]] {
            pathHighlights = factsJson.map { PathHighlight(emoji: $0["emoji"] as? String ?? "✨", fact: $0["fact"] as? String ?? "") }
        }

        var recommendedReading = RecommendedReading(book: "Psalms", chapter: 23, reason: "Start your spiritual journey with comfort and guidance")
        if let readingJson = analysisJson["recommendedReading"] as? [String: Any] {
            recommendedReading = RecommendedReading(
                book: readingJson["book"] as? String ?? "Psalms",
                chapter: readingJson["chapter"] as? Int ?? 23,
                reason: readingJson["reason"] as? String ?? "Start your spiritual journey"
            )
        }

        return AIJourneyAnalysis(pathStatus: pathStatus, pathHighlights: pathHighlights, recommendedReading: recommendedReading)
    }

    // MARK: - Private helpers

    private func formatIntentionalActions(_ actions: [IntentionalAction], typeLabel: String, isChinese: Bool) -> String {
        if actions.isEmpty {
            return isChinese ? "尚無\(typeLabel)" : "No \(typeLabel.lowercased())"
        }
        let verseLabel = isChinese ? "經文" : "Verse"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        return actions.enumerated().map { index, action in
            var result = "\(index + 1). \(action.verseReference)"
            if let content = action.content, !content.isEmpty {
                result += ": \(content)"
            }
            if !action.verseText.isEmpty {
                result += "\n   \(verseLabel): \"\(action.verseText)\""
            }
            if let metadata = action.metadata {
                result += "\n   (\(metadata))"
            }
            if typeLabel.contains("Recent") || typeLabel.contains("最近") {
                result += "\n   \(isChinese ? "日期" : "Date"): \(dateFormatter.string(from: action.date))"
            }
            return result
        }.joined(separator: "\n\n")
    }
}

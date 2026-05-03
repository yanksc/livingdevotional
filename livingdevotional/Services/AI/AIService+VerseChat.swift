// AIService+VerseChat - Verse and chapter-level chat, suggested questions

import Foundation

extension AIService {

    func explainVerse(
        book: String,
        chapter: Int,
        verse: Int,
        verseText: String,
        language: Language,
        mode: AIMode,
        appLanguage: AppLanguage,
        conversationHistory: [ChatMessage]?,
        userPrompt: String?
    ) async throws -> AsyncThrowingStream<String, Error> {
        var messages: [[String: Any]] = []

        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        let languageInstruction: String

        if isSimplified {
            languageInstruction = "请用简体中文提供简洁且有帮助的回答。"
        } else if isChinese {
            languageInstruction = "請用繁體中文（台灣用語）提供簡潔且有幫助的回答。"
        } else {
            languageInstruction = "Please provide concise and helpful responses in English."
        }

        let userContext = buildUserContext(appLanguage: appLanguage)
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            \(userContext)
            
            你正在幫助讀者理解以下經文：
            
            經卷：\(book)
            章：\(chapter)
            節：\(verse)
            經文：「\(verseText)」
            
            \(languageInstruction)
            直接給出完整的解釋，不要以反思問題作結。
            不要在回覆中重複經卷名稱、章節或節數（例如不要說「在創世記第三章中」），讀者已經知道自己在讀哪段經文。
            """ : """
            \(userContext)
            
            You are helping readers understand the following verse:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(verseText)"
            
            \(languageInstruction)
            Give a complete explanation. Do not end with a reflective question.
            Do not repeat the source book, chapter, or verse number in your response (e.g. don't say "In Genesis chapter 3…"). The reader already knows which verse they are reading.
            """
        ]
        messages.append(systemMessage)

        if let history = conversationHistory {
            for msg in history {
                if msg.role != .system {
                    messages.append(["role": msg.role.rawValue, "content": msg.content])
                }
            }
        }

        if let prompt = userPrompt {
            messages.append(["role": "user", "content": prompt])
        } else {
            let lengthConstraint = isChinese ? "請控制在 120-180 字以內，精簡扼要。" : "Please keep it concise, around 75-120 words."
            let initialPrompt: String

            switch mode {
            case .insight:
                if isChinese {
                    initialPrompt = """
                    請簡潔地解釋這節經文的歷史背景、文化脈絡和上下文。
                    
                    請精簡地包含：
                    1. 這節經文的歷史背景和當時的文化情境
                    2. 經文在整章或整卷書中的上下文位置和意義
                    3. 重要的神學概念或教義背景
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭，不要重複經卷名稱或章節號。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please provide concise insight into the historical background, cultural context, and surrounding context of this verse.
                    
                    Briefly include:
                    1. The historical background and cultural situation of this verse
                    2. The verse's position and meaning within the chapter or book
                    3. Important theological concepts or doctrinal background
                    
                    Please write in English, starting with "This verse". Do not restate the book name, chapter, or verse number. \(lengthConstraint)
                    """
                }
            case .reflect:
                if isChinese {
                    initialPrompt = """
                    請簡潔地幫助讀者將這節經文應用到現代生活中，進行靈修反思。
                    
                    請精簡地包含：
                    1. 這節經文對現代生活的啟發和應用
                    2. 具體的生活情境或例子來說明如何實踐
                    3. 如何在日常生活中活出這節經文的教導
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭，不要重複經卷名稱或章節號。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please help readers apply this verse to modern life and provide concise devotional reflection.
                    
                    Briefly include:
                    1. How this verse inspires and applies to modern life
                    2. Specific life situations or examples of how to practice it
                    3. How to live out this verse's teaching in daily life
                    
                    Please write in English, starting with "This verse". Do not restate the book name, chapter, or verse number. \(lengthConstraint)
                    """
                }
            case .pray:
                let prayerLengthConstraint = isChinese ? "篇幅請落在 260-360 字之間，讓禱告有足夠的呼吸與深度，不要倉促作結。" : "Aim for 160-220 words — give the prayer room to breathe and deepen; don't rush the close."
                if isChinese {
                    initialPrompt = """
                    請根據這節經文撰寫一篇真摯、富有靈性深度的禱告文。讓禱告緩緩展開，像是讀者真實向神傾心吐意，而不是條列式的祈求。

                    請自然地融入以下元素（不需逐項標明，讓它們在禱告中流淌）：
                    1. 凝視這節經文所啟示的神的本性或真理，向神獻上具體的感謝或敬拜
                    2. 在這節經文的光照下誠實地省察自己——可能是認罪、可能是渴慕、可能是承認自己的軟弱或掙扎
                    3. 將這節經文中的應許或教導帶入今日的生活情境，求神的同在與幫助
                    4. 在某處留下一個安靜的時刻——也許是「主，我在這裡聆聽你」、「我願意」這類的短語，讓禱告有停頓與呼吸
                    5. 以信心與順服作結，而不只是「奉耶穌的名禱告，阿們」

                    語氣要溫暖、誠實、富有畫面感——可以使用譬喻、聖經中的意象、第一人稱的真情流露。避免空泛的宗教套語。請用繁體中文（台灣用語）書寫，以「親愛的天父」或「主啊」開頭。\(prayerLengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please compose a sincere, spiritually thoughtful prayer rooted in this verse. Let the prayer unfold slowly — as if the reader is truly opening their heart before God, not ticking through a checklist of requests.

                    Weave the following naturally into the prayer (don't label them; let them flow):
                    1. Gaze at the truth this verse reveals about God's character, and offer specific thanksgiving or worship
                    2. In the light of this verse, lead the reader into honest self-examination — confession, longing, an admission of weakness, or a wrestling with where they fall short
                    3. Bring the verse's promise or teaching into a real present-day moment, asking for God's presence and help
                    4. Include a quiet, listening pause somewhere — phrases like "Lord, I'm here", "I am willing", or "Speak to me" — so the prayer has breath, not just words
                    5. End with faith and surrender, not a formulaic "in Jesus' name, amen"

                    The tone should be warm, honest, and concrete — feel free to use metaphor, biblical imagery, and first-person vulnerability. Avoid hollow religious cliché. Write in English, starting with "Dear Heavenly Father" or "Lord". \(prayerLengthConstraint)
                    """
                }
            }

            messages.append(["role": "user", "content": initialPrompt])
        }

        let maxTokens = mode == .pray ? 900 : (mode == .insight || mode == .reflect ? 700 : 1100)
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_completion_tokens": maxTokens
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "explainVerse")
    }

    func chatWithVerse(
        book: String,
        chapter: Int,
        verse: Int,
        verseText: String,
        appLanguage: AppLanguage,
        conversationHistory: [ChatMessage],
        userQuestion: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        var messages: [[String: Any]] = []

        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
        let languageInstruction = isChinese ? "請用繁體中文（台灣用語）回答。" : "Please answer in English."

        let userContext = buildUserContext(isChinese: isChinese)
        let verseProfile = UserProfileStore.shared.profile
        let readerName = verseProfile.name.isEmpty ? (isChinese ? "一位讀者" : "a reader") : verseProfile.name

        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            \(userContext)
            
            你正在幫助讀者理解以下經文，並回答他們的問題：
            
            經卷：\(book)
            章：\(chapter)
            節：\(verse)
            經文：「\(verseText)」
            
            \(languageInstruction)
            
            **回應結構（自然地整合，勿使用標題或條列）：**
            1. 先以同理心回應問題背後的心情或關切
            2. 提供紮實的釋經洞見——這節經文的意義、語境、以及神學要點，並引用一至兩處相關的聖經交叉引用來加深理解
            3. 提供具體且貼近生活的個人應用——\(readerName)如何在今天的生活中活出這真理
            
            **重要規則：**
            - 回應目標為 600-800 字，提供深度豐富的解答
            - 不需要重複經文內容，直接深化理解
            - 引用其他經文請使用標準格式如「約翰福音 3:16」
            - 以溫暖、有牧者確信的語調發言
            - 直接給出完整答案，不要以問題作結
            """ : """
            \(userContext)
            
            You are helping \(readerName) understand the following verse and answering their questions:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(verseText)"
            
            \(languageInstruction)
            
            **Response structure (weave naturally — no headers or bullet points in output):**
            1. Open by meeting the heart or curiosity behind the question with genuine warmth
            2. Offer substantive exegetical insight — the meaning, context, and theological weight of this verse, anchored with 1–2 cross-references from Scripture
            3. Offer a concrete personal application — how \(readerName) might live this truth today
            
            **Important rules:**
            - Aim for 600–800 words — give a rich, thorough, and deeply substantive answer
            - Do not repeat the verse text; deepen understanding instead
            - Cite other verses in standard format like "John 3:16" or "Psalm 23:1"
            - Speak with pastoral warmth and spiritual confidence
            - End with a complete, satisfying answer — do not close with a question
            """
        ]
        messages.append(systemMessage)

        for msg in conversationHistory {
            if msg.role != .system {
                messages.append(["role": msg.role.rawValue, "content": msg.content])
            }
        }
        messages.append(["role": "user", "content": userQuestion])

        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_completion_tokens": 2700
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "chatWithVerse")
    }

    func chatWithChapterContext(
        book: String,
        chapter: Int,
        chapterContent: String,
        contentType: String,
        appLanguage: AppLanguage,
        conversationHistory: [ChatMessage],
        userQuestion: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        var messages: [[String: Any]] = []

        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        let languageInstruction: String
        if isSimplified {
            languageInstruction = "请用简体中文回答。"
        } else if isChinese {
            languageInstruction = "請用繁體中文（台灣用語）回答。"
        } else {
            languageInstruction = "Please answer in English."
        }

        let userContext = buildUserContext(appLanguage: appLanguage)
        let profile = UserProfileStore.shared.profile
        let readerName = profile.name.isEmpty ? (isChinese ? "一位讀者" : "a reader") : profile.name

        let contentTypeLabel: String
        if isSimplified {
            contentTypeLabel = contentType == "summary" ? "摘要" : "背景"
        } else if isChinese {
            contentTypeLabel = contentType == "summary" ? "摘要" : "背景"
        } else {
            contentTypeLabel = contentType == "summary" ? "summary" : "context"
        }

        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isSimplified ? """
            \(userContext)

            你正在帮助读者理解以下圣经章节，并回答他们的问题。

            经卷：\(book)
            章：\(chapter)
            章节\(contentTypeLabel)：
            \(chapterContent)

            \(languageInstruction)

            **回应结构（自然地整合，勿使用标题或条列）：**
            1. 先以同理心回应问题背后的心情或关切
            2. 以上述\(contentTypeLabel)为锚点，提供扎实的释经洞见，并引用一至两处相关的圣经交叉引用来加深理解
            3. 在适当时，简要提及基督徒不同传统如何理解这段经文或其中的神学要点
            4. 提供具体且贴近生活的个人应用——读者如何在今天的生活中活出这真理
            5. 以一个温和的反思问题结尾，邀请更深的默想或对话

            **重要规则：**
            - 回应目标为 200-280 字，提供有深度的解答
            - 不需要重复\(contentTypeLabel)内容，直接深化理解
            - 引用经文请使用标准格式如「约翰福音 3:16」
            - 以温暖、有牧者确信的语调发言
            """ : isChinese ? """
            \(userContext)

            你正在幫助讀者理解以下聖經章節，並回答他們的問題。

            經卷：\(book)
            章：\(chapter)
            章節\(contentTypeLabel)：
            \(chapterContent)

            \(languageInstruction)

            **回應結構（自然地整合，勿使用標題或條列）：**
            1. 先以同理心回應問題背後的心情或關切
            2. 以上述\(contentTypeLabel)為錨點，提供紮實的釋經洞見，並引用一至兩處相關的聖經交叉引用來加深理解
            3. 在適當時，簡要提及基督徒不同傳統如何理解這段經文或其中的神學要點
            4. 提供具體且貼近生活的個人應用——讀者如何在今天的生活中活出這真理
            5. 以一個溫和的反思問題結尾，邀請更深的默想或對話

            **重要規則：**
            - 回應目標為 200-280 字，提供有深度的解答
            - 不需要重複\(contentTypeLabel)內容，直接深化理解
            - 引用其他經文請使用標準格式如「約翰福音 3:16」
            - 以溫暖、有牧者確信的語調發言
            """ : """
            \(userContext)

            You are helping \(readerName) understand the following Bible chapter and answering their questions.

            Book: \(book)
            Chapter: \(chapter)
            Chapter \(contentTypeLabel):
            \(chapterContent)

            \(languageInstruction)

            **Response structure (weave naturally — no headers or bullet points in output):**
            1. Open by meeting the heart or curiosity behind the question with genuine warmth
            2. Use the \(contentTypeLabel) above as your anchor, offering substantive insight with 1–2 cross-references from Scripture to enrich understanding
            3. Where fitting, briefly note how different Christian traditions have understood this passage or its key theological point
            4. Offer a concrete personal application — how \(readerName) might live this truth today
            5. Close with a gentle reflective question that invites deeper meditation or continued conversation

            **Important rules:**
            - Aim for 200–280 words — give a rich, substantive answer
            - Do not repeat the \(contentTypeLabel) content; deepen understanding instead
            - Cite other verses in standard format like "John 3:16" or "Psalm 23:1"
            - Speak with pastoral warmth and spiritual confidence
            """
        ]
        messages.append(systemMessage)

        for msg in conversationHistory {
            if msg.role != .system {
                messages.append(["role": msg.role.rawValue, "content": msg.content])
            }
        }
        messages.append(["role": "user", "content": userQuestion])

        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_completion_tokens": 2000
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "chatWithChapterContext")
    }

    func generateChapterSuggestedQuestions(
        book: String,
        chapter: Int,
        chapterContent: String,
        contentType: String,
        appLanguage: AppLanguage
    ) async throws -> [String] {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let contentTypeLabel: String
        if isSimplified || isChinese {
            contentTypeLabel = contentType == "summary" ? "摘要" : "背景"
        } else {
            contentTypeLabel = contentType == "summary" ? "summary" : "context"
        }

        let prompt: String
        if isSimplified {
            prompt = """
            请根据以下圣经章节的\(contentTypeLabel)，提供 2 个读者可能会问的简短问题，以便更深入了解这章内容。
            问题应简洁明了（20字以内）。
            请直接列出这两个问题，用换行分隔，不要有编号或其他文字。

            经卷：\(book) 第\(chapter)章
            章节\(contentTypeLabel)：
            \(chapterContent.prefix(600))
            """
        } else if isChinese {
            prompt = """
            請根據以下聖經章節的\(contentTypeLabel)，提供 2 個讀者可能會問的簡短問題，以便更深入了解這章內容。
            問題應簡潔明瞭（20字以內）。
            請直接列出這兩個問題，用換行分隔，不要有編號或其他文字。

            經卷：\(book) 第\(chapter)章
            章節\(contentTypeLabel)：
            \(chapterContent.prefix(600))
            """
        } else {
            prompt = """
            Based on the following chapter \(contentTypeLabel), provide 2 short questions a reader might ask to better understand this chapter.
            Questions should be concise (under 15 words).
            List the two questions directly, separated by a newline, without numbers or other text.

            Book: \(book) Chapter \(chapter)
            Chapter \(contentTypeLabel):
            \(chapterContent.prefix(600))
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = ["model": openAIModel, "messages": messages, "max_completion_tokens": 120]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateChapterSuggestedQuestions") else {
            return []
        }

        return content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { String($0) }
    }

    func generateSuggestedQuestions(
        book: String,
        chapter: Int,
        verse: Int,
        verseText: String,
        appLanguage: AppLanguage
    ) async throws -> [String] {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let prompt: String
        if isSimplified {
            prompt = """
            请针对以下经文提供 2 个简短的相关问题，供读者提问以更深入了解经文。
            问题应简洁明了（20字以内）。
            请直接列出这两个问题，用换行分隔，不要有编号或其他文字。
            
            经文：\(book) \(chapter):\(verse) 「\(verseText)」
            """
        } else if isChinese {
            prompt = """
            請針對以下經文提供 2 個簡短的相關問題，供讀者提問以更深入了解經文。
            問題應簡潔明瞭（20字以內）。
            請直接列出這兩個問題，用換行分隔，不要有編號或其他文字。
            
            經文：\(book) \(chapter):\(verse) 「\(verseText)」
            """
        } else {
            prompt = """
            Please provide 2 short, relevant questions about the following verse that a reader might ask to understand it better.
            Questions should be concise (under 15 words).
            List the two questions directly, separated by a newline, without numbers or other text.
            
            Verse: \(book) \(chapter):\(verse) "\(verseText)"
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = ["model": openAIModel, "messages": messages, "max_completion_tokens": 100]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateSuggestedQuestions") else {
            return []
        }

        return content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { String($0) }
    }
}

// AIService+Prayer - Prayer verse finding and verse rationale

import Foundation

extension AIService {

    func searchBible(query: String, language: Language) async throws -> [SearchResult] {
        // TODO: Implement Bible search
        // Reference: migration/api/bible-search/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    func findVerseForPrayer(focus: String, need: String, language: Language, appLanguage: AppLanguage, excludeReferences: [String]) async throws -> DailyVerse {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let excludeList = excludeReferences.joined(separator: ", ")
        let exclusionBlockSimplified = excludeReferences.isEmpty ? "" : "\n**重要**：请不要推荐以下已经显示过的经文：\(excludeList) 请选择其他不同的经文。\n"
        let exclusionBlockTraditional = excludeReferences.isEmpty ? "" : "\n**重要**：請不要推薦以下已經顯示過的經文：\(excludeList) 請選擇其他不同的經文。\n"
        let exclusionBlockEnglish = excludeReferences.isEmpty ? "" : "\n**Important**: Do NOT recommend any of these verses already shown: \(excludeList). Choose a different verse instead.\n"

        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者专家。用户想要为以下情况祷告：
            
            心中的关注：\(focus)
            需要的帮助：\(need)
            \(exclusionBlockSimplified)
            请推荐 1 节最相关且重要的圣经经文来帮助用户祷告。请选择：
            1. 经典且广为人知的经文
            2. 与主题直接相关的重要经文
            3. 能帮助读者深入理解的关键经文
            
            请以JSON格式回应：
            {
              "reference": "Book Chapter:Verse",
              "relevance": "相关性说明"
            }
            
            **重要**: 书卷名称必须使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            只回传JSON，不要其他文字。
            """
        } else if isChinese {
            prompt = """
            你是一位聖經學者專家。用戶想要為以下情況禱告：
            
            心中的關注：\(focus)
            需要的幫助：\(need)
            \(exclusionBlockTraditional)
            請推薦 1 節最相關且重要的聖經經文來幫助用戶禱告。請選擇：
            1. 經典且廣為人知的經文
            2. 與主題直接相關的重要經文
            3. 能幫助讀者深入理解的關鍵經文
            
            請以JSON格式回應：
            {
              "reference": "Book Chapter:Verse",
              "relevance": "相關性說明"
            }
            
            **重要**: 書卷名稱必須使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            只回傳JSON，不要其他文字。
            """
        } else {
            prompt = """
            You are a Bible scholar expert. A user wants to pray for the following situation:
            
            What's on their heart: \(focus)
            What they need: \(need)
            \(exclusionBlockEnglish)
            Please recommend 1 most relevant and important Bible verse to help the user pray. Choose:
            1. Classic and well-known verses
            2. Important verses directly related to the theme
            3. Key verses that help readers understand deeply
            
            Please respond in JSON format:
            {
              "reference": "Book Chapter:Verse",
              "relevance": "Relevance explanation"
            }
            
            **Important**: Book names must be in English, e.g., Matthew, Mark, Luke, John, Romans, Genesis, Psalms, etc.
            Return only JSON, no other text.
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.3,
            "max_completion_tokens": 200
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "findVerseForPrayer")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8),
              let suggestion = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let reference = suggestion["reference"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }

        let refPattern = #"^(\d*\s*\w+)\s+(\d+):(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: refPattern, options: []),
              let match = regex.firstMatch(in: reference, options: [], range: NSRange(reference.startIndex..., in: reference)),
              let bookRange = Range(match.range(at: 1), in: reference),
              let chapterRange = Range(match.range(at: 2), in: reference),
              let verseRange = Range(match.range(at: 3), in: reference) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse verse reference: \(reference)"])
        }

        let bookName = String(reference[bookRange]).trimmingCharacters(in: .whitespaces)
        guard let chapter = Int(String(reference[chapterRange])),
              let verseNumber = Int(String(reference[verseRange])) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid chapter or verse number"])
        }

        guard let book = BibleData.book(named: bookName) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Book not found: \(bookName)"])
        }

        let bibleService = BibleService.shared
        let verses = try await bibleService.loadVerses(book: book.name, chapter: chapter, translation: language)

        guard let verse = verses.first(where: { $0.verseNumber == verseNumber }) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verse not found: \(bookName) \(chapter):\(verseNumber)"])
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        return DailyVerse(
            book: book.name,
            chapter: chapter,
            verseNumber: verseNumber,
            textBsb: verse.textBsb,
            textCuv: verse.textCuv,
            textCu1: verse.textCu1,
            textKjv: verse.textKjv,
            textWeb: verse.textWeb,
            textSpa: verse.textSpa,
            textPor: verse.textPor,
            reference: "\(book.name) \(chapter):\(verseNumber)",
            selectedDate: dateString
        )
    }

    // MARK: - Verse Rationale Generation

    func generateVerseRationale(verseReference: String, verseText: String, userAction: String, appLanguage: AppLanguage) async throws -> String {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let prompt: String
        if isSimplified {
            prompt = """
            用户最近的活动：\(userAction)
            
            推荐的经文：\(verseReference)
            经文内容："\(verseText)"
            
            请用2-3句话解释为什么我们为用户推荐这节经文。解释应该包含：
            1. 第一句：描述用户具体做了什么（例如：您最近在祷告中关注了...，您阅读了...，您问了关于...的问题）
            2. 第二句：说明这节经文如何与用户的行为或需求相关
            3. 第三句：简短说明这节经文如何能帮助用户的属灵成长或当前处境
            
            语气要温暖、个人化，像是朋友在分享。不要使用"用户"，而是直接用"您"。
            只返回解释文字，不要其他格式。
            """
        } else if isChinese {
            prompt = """
            用戶最近的活動：\(userAction)
            
            推薦的經文：\(verseReference)
            經文內容："\(verseText)"
            
            請用2-3句話解釋為什麼我們為用戶推薦這節經文。解釋應該包含：
            1. 第一句：描述用戶具體做了什麼（例如：您最近在禱告中關注了...，您閱讀了...，您問了關於...的問題）
            2. 第二句：說明這節經文如何與用戶的行為或需求相關
            3. 第三句：簡短說明這節經文如何能幫助用戶的屬靈成長或當前處境
            
            語氣要溫暖、個人化，像是朋友在分享。不要使用「用戶」，而是直接用「您」。
            只返回解釋文字，不要其他格式。
            """
        } else {
            prompt = """
            User's recent activity: \(userAction)
            
            Recommended verse: \(verseReference)
            Verse text: "\(verseText)"
            
            Please provide a 2-3 sentence explanation of why we recommend this verse to the user. The explanation should include:
            1. First sentence: Describe what the user specifically did (e.g., "You recently prayed about...", "You were reading...", "You asked about...")
            2. Second sentence: Explain how this verse relates to the user's action or need
            3. Third sentence: Briefly describe how this verse might help with their spiritual journey or current situation
            
            Use a warm, personal tone like a friend sharing. Use "you" instead of "the user".
            Return only the explanation text, no other formatting.
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_completion_tokens": 250
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "generateVerseRationale")
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// AIService+Search - Verse search and related verses

import Foundation

extension AIService {

    func findRelatedVerses(book: String, chapter: Int, verse: Int, text: String, appLanguage: AppLanguage) async throws -> [RelatedVerse] {
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)

        let prompt: String
        if isChinese {
            prompt = """
            你是一位聖經學者。針對以下經文：
            
            經卷：\(book)
            章：\(chapter)
            節：\(verse)
            經文：「\(text)」
            
            請找出 3 節最相關且重要的聖經經文，讀者應該與此經文一起研讀。
            
            **重要規則：**
            1. **不要**列出同一章（\(book) \(chapter)章）的經文，因為讀者已經在閱讀該章節
            2. 優先選擇：
               - 經典且廣為人知的經文
               - 與主題直接相關的重要經文
               - 能幫助讀者更深入理解的關鍵經文
            3. 按照相關性和重要性排序（最相關的放在前面）
            
            對於每一節相關經文，請提供：
            1. 經文出處（英文書卷名 章:節，例如 "John 3:16"）
            2. 經文內容（完整的經文文字）
            3. 相關性說明（非常簡短，不超過10個字，例如「強調信心」或「回應相同主題」）
            
            請以JSON陣列格式回應，結構如下：
            [
              {
                "book": "Book",
                "chapter": 3,
                "verse": 16,
                "reference": "Book 3:16",
                "text": "完整的經文內容",
                "relevance": "相關性說明"
              }
            ]
            
            **重要**: 書卷名稱必須使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            使用繁體中文（台灣用語）書寫相關性說明。只回傳JSON陣列，不要其他文字。
            """
        } else {
            prompt = """
            You are a Bible scholar. For the following verse:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(text)"
            
            Please find 3 most relevant and important Bible verses that readers should study together with this verse.
            
            **Important Rules:**
            1. **Do NOT** list verses from the same chapter (\(book) \(chapter)), because the reader is already reading that chapter
            2. Prioritize:
               - Classic and well-known verses
               - Important verses directly related to the theme
               - Key verses that help readers understand more deeply
            3. Sort by relevance and importance (most relevant first)
            
            For each related verse, please provide:
            1. Verse reference (English book name Chapter:Verse, e.g., "John 3:16")
            2. Verse text (complete verse content)
            3. Relevance explanation (Very brief, max 10 words, e.g. "Emphasizes faith" or "Echoes same theme")
            
            Please respond in JSON array format:
            [
              {
                "book": "Book",
                "chapter": 3,
                "verse": 16,
                "reference": "Book 3:16",
                "text": "Complete verse text",
                "relevance": "Relevance explanation"
              }
            ]
            
            **Important**: Book names must be in English, e.g., Matthew, Mark, Luke, John, Romans, Genesis, Psalms, etc.
            Return only JSON array, no other text.
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1200
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "findRelatedVerses")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8),
              let verses = try? JSONDecoder().decode([RelatedVerse].self, from: jsonData) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }

        return verses
    }

    func searchVerses(query: String, appLanguage: AppLanguage) async throws -> VerseSearchResponse {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者专家。用户问了以下问题或搜索：
            
            问题：「\(query)」
            
            请：
            1. 先提供你对这个问题或搜索的理解（interpretation），请非常简短（不超过 30 字）
            2. 推荐 3 节最相关且重要的圣经经文来回答这个问题
            
            请选择：
            - 经典且广为人知的经文
            - 与主题直接相关的重要经文
            - 能帮助读者深入理解的关键经文
            
            对于每一节经文，请提供：
            1. 经文出处（英文书卷名 章:节，例如 "John 3:16"）
            2. 经文内容（完整的经文文字）
            3. 相关性说明（简短，不超过 10 个字）
            
            请以JSON格式回应，结构如下：
            {
              "interpretation": "你对这个问题或搜索的理解",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "完整的经文内容",
                  "relevance": "相关性说明"
                }
              ]
            }
            
            **重要**: 书卷名称必须使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            使用简体中文书写。只回传JSON，不要其他文字。
            """
        } else if isChinese {
            prompt = """
            你是一位聖經學者專家。用戶問了以下問題或搜尋：
            
            問題：「\(query)」
            
            請：
            1. 先提供你對這個問題或搜尋的理解（interpretation），請非常簡短（不超過 30 字）
            2. 推薦 3 節最相關且重要的聖經經文來回答這個問題
            
            請選擇：
            - 經典且廣為人知的經文
            - 與主題直接相關的重要經文
            - 能幫助讀者深入理解的關鍵經文
            
            對於每一節經文，請提供：
            1. 經文出處（英文書卷名 章:節，例如 "John 3:16"）
            2. 經文內容（完整的經文文字）
            3. 相關性說明（簡短，不超過 10 個字）
            
            請以JSON格式回應，結構如下：
            {
              "interpretation": "你對這個問題或搜尋的理解",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "完整的經文內容",
                  "relevance": "相關性說明"
                }
              ]
            }
            
            **重要**: 書卷名稱必須使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            使用繁體中文（台灣用語）書寫。只回傳JSON，不要其他文字。
            """
        } else {
            prompt = """
            You are a Bible scholar expert. A user asked the following question or search:
            
            Query: "\(query)"
            
            Please:
            1. First provide your interpretation of this question or search (very brief, max 20 words)
            2. Recommend 3 most relevant and important Bible verses to answer this question
            
            Choose:
            - Classic and well-known verses
            - Important verses directly related to the theme
            - Key verses that help readers understand deeply
            
            For each verse, please provide:
            1. Verse reference (English book name Chapter:Verse, e.g., "John 3:16")
            2. Verse text (complete verse content)
            3. Relevance explanation (Brief, max 10 words)
            
            Please respond in JSON format:
            {
              "interpretation": "Your interpretation of this question or search",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "Complete verse text",
                  "relevance": "Relevance explanation"
                }
              ]
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
            "max_tokens": 1200
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "searchVerses")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to process search results. Please try again."])
        }

        do {
            return try JSONDecoder().decode(VerseSearchResponse.self, from: jsonData)
        } catch {
            if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                let interpretation = jsonObj["interpretation"] as? String ?? ""
                let verses = parseRelatedVersesFromJSON(jsonObj["results"] as? [[String: Any]] ?? [])
                if !verses.isEmpty {
                    return VerseSearchResponse(interpretation: interpretation, results: verses)
                }
            }
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to process search results. Please try a different search term."])
        }
    }

    func searchMoreVerses(query: String, excludeReferences: [String], appLanguage: AppLanguage) async throws -> VerseSearchResponse {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let excludeList = excludeReferences.joined(separator: ", ")

        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者专家。用户问了以下问题或搜索：
            
            问题：「\(query)」
            
            请推荐 3 节相关的圣经经文来回答这个问题。
            
            **重要**：请不要推荐以下已经找到的经文：\(excludeList)
            
            请选择其他相关且重要的经文：
            - 经典且广为人知的经文
            - 与主题直接相关的重要经文
            - 能帮助读者深入理解的关键经文
            
            对于每一节经文，请提供：
            1. 经文出处（英文书卷名 章:节，例如 "John 3:16"）
            2. 经文内容（完整的经文文字）
            3. 相关性说明（简短，不超过 10 个字）
            
            请以JSON格式回应，结构如下：
            {
              "interpretation": "",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "完整的经文内容",
                  "relevance": "相关性说明"
                }
              ]
            }
            
            **重要**: 书卷名称必须使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            使用简体中文书写。只回传JSON，不要其他文字。
            """
        } else if isChinese {
            prompt = """
            你是一位聖經學者專家。用戶問了以下問題或搜尋：
            
            問題：「\(query)」
            
            請推薦 3 節相關的聖經經文來回答這個問題。
            
            **重要**：請不要推薦以下已經找到的經文：\(excludeList)
            
            請選擇其他相關且重要的經文：
            - 經典且廣為人知的經文
            - 與主題直接相關的重要經文
            - 能幫助讀者深入理解的關鍵經文
            
            對於每一節經文，請提供：
            1. 經文出處（英文書卷名 章:節，例如 "John 3:16"）
            2. 經文內容（完整的經文文字）
            3. 相關性說明（簡短，不超過 10 個字）
            
            請以JSON格式回應，結構如下：
            {
              "interpretation": "",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "完整的經文內容",
                  "relevance": "相關性說明"
                }
              ]
            }
            
            **重要**: 書卷名稱必須使用英文，例如: Matthew, Mark, Luke, John, Romans, Genesis, Psalms 等。
            使用繁體中文（台灣用語）書寫。只回傳JSON，不要其他文字。
            """
        } else {
            prompt = """
            You are a Bible scholar expert. A user asked the following question or search:
            
            Query: "\(query)"
            
            Please recommend 3 relevant Bible verses to answer this question.
            
            **Important**: Do NOT recommend these verses that were already found: \(excludeList)
            
            Choose other relevant and important verses:
            - Classic and well-known verses
            - Important verses directly related to the theme
            - Key verses that help readers understand deeply
            
            For each verse, please provide:
            1. Verse reference (English book name Chapter:Verse, e.g., "John 3:16")
            2. Verse text (complete verse content)
            3. Relevance explanation (Brief, max 10 words)
            
            Please respond in JSON format:
            {
              "interpretation": "",
              "results": [
                {
                  "book": "Book",
                  "chapter": 3,
                  "verse": 16,
                  "reference": "Book 3:16",
                  "text": "Complete verse text",
                  "relevance": "Relevance explanation"
                }
              ]
            }
            
            **Important**: Book names must be in English, e.g., Matthew, Mark, Luke, John, Romans, Genesis, Psalms, etc.
            Return only JSON, no other text.
            """
        }

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.5,
            "max_tokens": 1200
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "loadMoreRelatedVerses")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to process results."])
        }

        do {
            return try JSONDecoder().decode(VerseSearchResponse.self, from: jsonData)
        } catch {
            if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                let verses = parseRelatedVersesFromJSON(jsonObj["results"] as? [[String: Any]] ?? [])
                if !verses.isEmpty {
                    return VerseSearchResponse(interpretation: "", results: verses)
                }
            }
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find more verses."])
        }
    }

    // MARK: - Shared JSON parsing helper

    private func parseRelatedVersesFromJSON(_ resultsArray: [[String: Any]]) -> [RelatedVerse] {
        return resultsArray.compactMap { result -> RelatedVerse? in
            let book = result["book"] as? String ?? ""
            let chapter = (result["chapter"] as? Int) ?? Int(result["chapter"] as? String ?? "1") ?? 1
            let verse = (result["verse"] as? Int) ?? Int(result["verse"] as? String ?? "1") ?? 1
            let reference = result["reference"] as? String ?? "\(book) \(chapter):\(verse)"
            let text = result["text"] as? String ?? ""
            let relevance = result["relevance"] as? String ?? ""
            guard !book.isEmpty && !text.isEmpty else { return nil }
            return RelatedVerse(book: book, chapter: chapter, verse: verse, reference: reference, text: text, relevance: relevance)
        }
    }
}

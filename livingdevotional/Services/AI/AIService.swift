// AIService - AI service implementation with Helicone integration

import Foundation

class AIService: AIServiceProtocol {
    // Helicone AI Gateway endpoint - only requires Helicone API key
    // Helicone handles OpenAI API key through their gateway
    private let heliconeBaseURL = AppConfig.heliconeBaseURL
    private let heliconeAPIKey = AppConfig.heliconeAPIKey
    private let openAIModel = AppConfig.openAIModel
    
    // MARK: - User Profile Context
    
    private func isChineseLanguage(_ appLanguage: AppLanguage) -> Bool {
        let languageCode = appLanguage.resolvedLanguageCode()
        return languageCode == "zh-Hans" || languageCode == "zh-Hant"
    }
    
    private func isSimplifiedChinese(_ appLanguage: AppLanguage) -> Bool {
        return appLanguage.resolvedLanguageCode() == "zh-Hans"
    }
    
    private func buildUserContext(appLanguage: AppLanguage) -> String {
        let profile = UserProfileStore.shared.profile
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        let goals = profile.spiritualGoals.isEmpty ? 
            (isChinese ? (isSimplified ? "无特定目标" : "無特定目標") : "no specific goals") :
            profile.spiritualGoals.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", ")
        let tradition = profile.tradition.localizedDisplayName(for: appLanguage)
        let companionStyle = profile.companionStyle.localizedDisplayName(for: appLanguage)
        
        if isChinese {
            return """
            你是一位\(companionStyle)。你正在與\(profile.name.isEmpty ? "一位讀者" : profile.name)對話，他是一位\(maturity)的信徒。
            
            背景資訊：
            - 屬靈階段：\(maturity)
            - 目標：\(goals)
            - 教會背景：\(tradition)
            
            請根據這些資訊調整你的語調和深度，使其更貼近這位讀者的需要。
            """
        } else {
            return """
            You are a \(companionStyle). You are speaking with \(profile.name.isEmpty ? "a reader" : profile.name), who is a \(maturity) believer.
            
            Background:
            - Spiritual Stage: \(maturity)
            - Goals: \(goals)
            - Church Background: \(tradition)
            
            Please adjust your tone and depth based on this information to better serve this reader's needs.
            """
        }
    }
    
    // Legacy method for backward compatibility
    private func buildUserContext(isChinese: Bool) -> String {
        let appLanguage: AppLanguage = isChinese ? .chineseTraditional : .english
        return buildUserContext(appLanguage: appLanguage)
    }
    
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
        // Build messages array for OpenAI-compatible API
        var messages: [[String: Any]] = []
        
        // Determine response language based on appLanguage
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
        
        // Build personalized system message with user context
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
            """ : """
            \(userContext)
            
            You are helping readers understand the following verse:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(verseText)"
            
            \(languageInstruction)
            """
        ]
        messages.append(systemMessage)
        
        // If there's conversation history, add it
        if let history = conversationHistory {
            for msg in history {
                if msg.role != .system {
                    let message: [String: Any] = [
                        "role": msg.role.rawValue,
                        "content": msg.content
                    ]
                    messages.append(message)
                }
            }
        }
        
        // Add the current user prompt (either initial explanation or follow-up)
        if let prompt = userPrompt {
            // Follow-up question/prompt
            let userMessage: [String: Any] = [
                "role": "user",
                "content": prompt
            ]
            messages.append(userMessage)
        } else {
            // Initial prompt based on mode and language
            let initialPrompt: String
            let lengthConstraint = isChinese ? "請控制在 80-120 字以內，精簡扼要。" : "Please keep it concise, around 50-80 words."
            
            switch mode {
            case .insight:
                if isChinese {
                    initialPrompt = """
                    請簡潔地解釋這節經文的歷史背景、文化脈絡和上下文。
                    
                    請精簡地包含：
                    1. 這節經文的歷史背景和當時的文化情境
                    2. 經文在整章或整卷書中的上下文位置和意義
                    3. 重要的神學概念或教義背景
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please provide concise insight into the historical background, cultural context, and surrounding context of this verse.
                    
                    Briefly include:
                    1. The historical background and cultural situation of this verse
                    2. The verse's position and meaning within the chapter or book
                    3. Important theological concepts or doctrinal background
                    
                    Please write in English, starting with "This verse". \(lengthConstraint)
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
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please help readers apply this verse to modern life and provide concise devotional reflection.
                    
                    Briefly include:
                    1. How this verse inspires and applies to modern life
                    2. Specific life situations or examples of how to practice it
                    3. How to live out this verse's teaching in daily life
                    
                    Please write in English, starting with "This verse". \(lengthConstraint)
                    """
                }
            case .pray:
                let prayerLengthConstraint = isChinese ? "請控制在 80-120 字以內，精簡而深刻。" : "Please keep it concise and meaningful, around 60-100 words."
                if isChinese {
                    initialPrompt = """
                    請根據這節經文撰寫一篇簡短而深刻的禱告文。
                    
                    請簡潔地包含：
                    1. 感謝神在這節經文中顯明的真理
                    2. 認罪和悔改（如果經文相關）
                    3. 祈求神幫助我們活出這節經文的教導
                    
                    請用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭。\(prayerLengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please compose a concise and meaningful prayer based on this verse.
                    
                    Briefly include:
                    1. Thanksgiving for the truth revealed in this verse
                    2. Confession and repentance (if relevant to the verse)
                    3. Request for God's help to live out this verse's teaching
                    
                    Please write in English, starting with "Dear Heavenly Father" or "Lord". \(prayerLengthConstraint)
                    """
                }
            }
            
            let userMessage: [String: Any] = [
                "role": "user",
                "content": initialPrompt
            ]
            messages.append(userMessage)
        }
        
        // Create request body
        // Use fewer tokens for pray mode since prayers should be concise
        // Reduce tokens for insight and reflect modes to enforce shorter responses
        let maxTokens = mode == .pray ? 400 : (mode == .insight || mode == .reflect ? 300 : 500)
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": maxTokens
        ]
        
        // Create URL request
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Helicone AI Gateway - only needs Helicone API key in Authorization header
        // Helicone handles the OpenAI API key connection through their gateway
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        // Create async stream for streaming response
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        // Read error response body
                        var errorData = Data()
                        do {
                            for try await byte in asyncBytes {
                                errorData.append(byte)
                            }
                        } catch {
                            // If we can't read the error body, use status code
                        }
                        
                        var errorMessage = "HTTP \(httpResponse.statusCode)"
                        if !errorData.isEmpty,
                           let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                            if let error = json["error"] as? [String: Any],
                               let message = error["message"] as? String {
                                errorMessage = message
                            } else if let message = json["message"] as? String {
                                errorMessage = message
                            } else if let errorString = String(data: errorData, encoding: .utf8) {
                                errorMessage = errorString
                            }
                        }
                        
                        // Log error for debugging
                        print("AIService Error: \(errorMessage)")
                        print("Status Code: \(httpResponse.statusCode)")
                        if let headers = httpResponse.allHeaderFields as? [String: Any] {
                            print("Response Headers: \(headers)")
                        }
                        
                        continuation.finish(throwing: NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                        return
                    }
                    
                    // Parse Server-Sent Events (SSE) stream
                    // Accumulate bytes and decode incrementally
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        // Try to decode accumulated bytes as UTF-8 string
                        // If decoding fails, it means we have an incomplete UTF-8 sequence - keep accumulating
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            // Process complete lines
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                // Skip empty lines and event type lines
                                if line.isEmpty || line.hasPrefix("event:") || line.hasPrefix(":") {
                                    continue
                                }
                                
                                // Parse data lines
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6)) // Remove "data: "
                                    
                                    // Check for [DONE] marker
                                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    // Parse JSON chunk
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        continuation.yield(content)
                                    }
                                }
                            }
                            
                            // Keep any remaining text (incomplete line) in buffer for next iteration
                            if !remainingString.isEmpty {
                                byteBuffer = remainingString.data(using: .utf8) ?? Data()
                            } else {
                                byteBuffer.removeAll()
                            }
                        }
                        // If decoding failed, byteBuffer contains incomplete UTF-8 sequence - keep accumulating
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
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
        // Build messages array for OpenAI-compatible API
        var messages: [[String: Any]] = []
        
        // Determine response language based on appLanguage
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
        let languageInstruction = isChinese ? "請用繁體中文（台灣用語）回答。" : "Please answer in English."
        
        // Build personalized system message with user context
        let userContext = buildUserContext(isChinese: isChinese)
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
            請保持回答友善、有深度且符合聖經真理。
            
            **重要規則：**
            - 回答請簡潔扼要，控制在 100-150 字以內
            - 直接回答問題，不需要重複經文內容
            - 如果引用其他經文，請使用標準格式如「約翰福音 3:16」或「John 3:16」
            """ : """
            \(userContext)
            
            You are helping readers understand the following verse and answering their questions:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(verseText)"
            
            \(languageInstruction)
            Please keep answers friendly, insightful, and biblically accurate.
            
            **Important rules:**
            - Keep responses concise, around 80-120 words
            - Answer directly without repeating the verse content
            - When referencing other verses, use standard format like "John 3:16" or "Genesis 1:1"
            """
        ]
        messages.append(systemMessage)
        
        // Add conversation history
        for msg in conversationHistory {
            if msg.role != .system {
                let message: [String: Any] = [
                    "role": msg.role.rawValue,
                    "content": msg.content
                ]
                messages.append(message)
            }
        }
        
        // Add current question
        let userMessage: [String: Any] = [
            "role": "user",
            "content": userQuestion
        ]
        messages.append(userMessage)
        
        // Create request body - limit to 500 tokens for concise responses
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 500
        ]
        
        // Create URL request
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        // Return async stream (reusing the streaming logic structure)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }
                    
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        continuation.yield(content)
                                    }
                                }
                            }
                            
                            if !remainingString.isEmpty {
                                byteBuffer = remainingString.data(using: .utf8) ?? Data()
                            } else {
                                byteBuffer.removeAll()
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
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
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "max_tokens": 100
        ]
        
        guard let url = URL(string: heliconeBaseURL) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return []
        }
        
        return content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { String($0) }
    }
    
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
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1200
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract JSON array from response
        guard let jsonData2 = cleanedContent.data(using: .utf8),
              let verses = try? JSONDecoder().decode([RelatedVerse].self, from: jsonData2) else {
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
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1200
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to complete search. Please try again."])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to process search results. Please try again."])
        }
        
        // Try to decode with more flexibility
        do {
            let searchResponse = try JSONDecoder().decode(VerseSearchResponse.self, from: jsonData2)
            return searchResponse
        } catch {
            // Try manual parsing as fallback
            if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData2) as? [String: Any] {
                let interpretation = jsonObj["interpretation"] as? String ?? ""
                var verses: [RelatedVerse] = []
                
                if let resultsArray = jsonObj["results"] as? [[String: Any]] {
                    for result in resultsArray {
                        let book = result["book"] as? String ?? ""
                        let chapter = (result["chapter"] as? Int) ?? Int(result["chapter"] as? String ?? "1") ?? 1
                        let verse = (result["verse"] as? Int) ?? Int(result["verse"] as? String ?? "1") ?? 1
                        let reference = result["reference"] as? String ?? "\(book) \(chapter):\(verse)"
                        let text = result["text"] as? String ?? ""
                        let relevance = result["relevance"] as? String ?? ""
                        
                        if !book.isEmpty && !text.isEmpty {
                            verses.append(RelatedVerse(book: book, chapter: chapter, verse: verse, reference: reference, text: text, relevance: relevance))
                        }
                    }
                }
                
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
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.5,
            "max_tokens": 1200
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find more verses. Please try again."])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to process results."])
        }
        
        // Try to decode with more flexibility
        do {
            let searchResponse = try JSONDecoder().decode(VerseSearchResponse.self, from: jsonData2)
            return searchResponse
        } catch {
            // Try manual parsing as fallback
            if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData2) as? [String: Any] {
                var verses: [RelatedVerse] = []
                
                if let resultsArray = jsonObj["results"] as? [[String: Any]] {
                    for result in resultsArray {
                        let book = result["book"] as? String ?? ""
                        let chapter = (result["chapter"] as? Int) ?? Int(result["chapter"] as? String ?? "1") ?? 1
                        let verse = (result["verse"] as? Int) ?? Int(result["verse"] as? String ?? "1") ?? 1
                        let reference = result["reference"] as? String ?? "\(book) \(chapter):\(verse)"
                        let text = result["text"] as? String ?? ""
                        let relevance = result["relevance"] as? String ?? ""
                        
                        if !book.isEmpty && !text.isEmpty {
                            verses.append(RelatedVerse(book: book, chapter: chapter, verse: verse, reference: reference, text: text, relevance: relevance))
                        }
                    }
                }
                
                if !verses.isEmpty {
                    return VerseSearchResponse(interpretation: "", results: verses)
                }
            }
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to find more verses."])
        }
    }
    
    func askQuestion(question: String, context: String?) async throws -> String {
        // TODO: Implement Q&A
        // Reference: migration/api/ask-question/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func chatGeneral(
        appLanguage: AppLanguage,
        conversationHistory: [ChatMessage],
        userQuestion: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        // Build messages array for OpenAI-compatible API
        var messages: [[String: Any]] = []
        
        // Determine response language based on appLanguage
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
        
        // Build personalized system message with user context
        let userContext = buildUserContext(appLanguage: appLanguage)
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            \(userContext)
            
            你是一位溫暖且鼓勵人的屬靈導師，幫助讀者理解聖經、屬靈成長和信仰問題。
            
            \(languageInstruction)
            請保持回答友善、有深度且符合聖經真理。當問題涉及特定經文時，可以引用相關經文來支持你的回答。
            
            **重要規則：**
            - 回答請簡潔扼要，控制在 100-150 字以內
            - 直接回答問題，不要長篇大論
            - 如果引用經文，請使用標準格式如「約翰福音 3:16」或「John 3:16」
            """ : """
            \(userContext)
            
            You are a warm and encouraging spiritual mentor, helping readers understand the Bible, spiritual growth, and faith questions.
            
            \(languageInstruction)
            Please keep answers friendly, insightful, and biblically accurate. When questions involve specific verses, you may reference relevant verses to support your answers.
            
            **Important rules:**
            - Keep responses concise, around 80-120 words
            - Answer directly without being verbose
            - When referencing verses, use standard format like "John 3:16" or "Genesis 1:1"
            """
        ]
        messages.append(systemMessage)
        
        // Add conversation history
        for msg in conversationHistory {
            if msg.role != .system {
                let message: [String: Any] = [
                    "role": msg.role.rawValue,
                    "content": msg.content
                ]
                messages.append(message)
            }
        }
        
        // Add current question
        let userMessage: [String: Any] = [
            "role": "user",
            "content": userQuestion
        ]
        messages.append(userMessage)
        
        // Create request body - limit to 500 tokens for concise responses
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 500
        ]
        
        // Create URL request
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        // Return async stream (reusing the streaming logic structure)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }
                    
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        continuation.yield(content)
                                    }
                                }
                            }
                            
                            if !remainingString.isEmpty {
                                byteBuffer = remainingString.data(using: .utf8) ?? Data()
                            } else {
                                byteBuffer.removeAll()
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func summarizeChapter(book: String, chapter: Int, language: Language) async throws -> String {
        // TODO: Implement chapter summary
        // Reference: migration/api/summarize-chapter/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func summarizeChapterStream(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error> {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        let userContext = buildUserContext(appLanguage: appLanguage)
        
        let systemContent: String
        if isSimplified {
            systemContent = """
            \(userContext)
            
            你正在幫助讀者理解以下聖經章節：
            
            經卷：\(book)
            章：\(chapter)
            
            請用簡體中文提供簡潔且有幫助的回答。
            """
        } else if isChinese {
            systemContent = """
            \(userContext)
            
            你正在幫助讀者理解以下聖經章節：
            
            經卷：\(book)
            章：\(chapter)
            
            請用繁體中文（台灣用語）提供簡潔且有幫助的回答。
            """
        } else {
            systemContent = """
            \(userContext)
            
            You are helping readers understand the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Please provide concise and helpful responses in English.
            """
        }
        
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": systemContent
        ]
        
        let prompt: String
        if isSimplified {
            prompt = """
            请为以下圣经章节提供简短的摘要：
            
            经卷：\(book)
            章：\(chapter)
            
            请用1-2段简短的段落（总共约120-170字）概述这一章的内容，包括：
            
            1. 主要主题和中心思想
            2. 重要事件或教导的精华
            
            请直接开始摘要，不需要标题或开场白。使用简体中文书写。
            """
        } else if isChinese {
            prompt = """
            請為以下聖經章節提供簡短的摘要：
            
            經卷：\(book)
            章：\(chapter)
            
            請用1-2段簡短的段落（總共約120-170字）概述這一章的內容，包括：
            
            1. 主要主題和中心思想
            2. 重要事件或教導的精華
            
            請直接開始摘要，不需要標題或開場白。使用繁體中文（台灣用語）書寫。
            """
        } else {
            prompt = """
            Please provide a brief summary of the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Please summarize this chapter in 1-2 short paragraphs (approximately 80-110 words total), including:
            
            1. Main themes and central ideas
            2. Key events or teachings
            
            Please start directly with the summary, no title or introduction. Write in English. Keep it concise.
            """
        }
        
        let userMessage: [String: Any] = [
            "role": "user",
            "content": prompt
        ]
        
        let messages: [[String: Any]] = [systemMessage, userMessage]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 400
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }
                    
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        continuation.yield(content)
                                    }
                                }
                            }
                            
                            if !remainingString.isEmpty {
                                byteBuffer = remainingString.data(using: .utf8) ?? Data()
                            } else {
                                byteBuffer.removeAll()
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func getChapterContext(book: String, chapter: Int, appLanguage: AppLanguage) async throws -> AsyncThrowingStream<String, Error> {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        let userContext = buildUserContext(appLanguage: appLanguage)
        
        let systemContent: String
        if isSimplified {
            systemContent = """
            \(userContext)
            
            你正在幫助讀者理解以下聖經章節的背景和作者資訊：
            
            經卷：\(book)
            章：\(chapter)
            
            請用簡體中文提供簡潔且有幫助的回答。
            """
        } else if isChinese {
            systemContent = """
            \(userContext)
            
            你正在幫助讀者理解以下聖經章節的背景和作者資訊：
            
            經卷：\(book)
            章：\(chapter)
            
            請用繁體中文（台灣用語）提供簡潔且有幫助的回答。
            """
        } else {
            systemContent = """
            \(userContext)
            
            You are helping readers understand the background and author information of the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Please provide concise and helpful responses in English.
            """
        }
        
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": systemContent
        ]
        
        let prompt: String
        if isSimplified {
            prompt = """
            请为以下圣经章节提供背景和作者信息：
            
            经卷：\(book)
            章：\(chapter)
            
            请简要包含：
            1. 作者和写作背景
            2. 历史背景和文化脉络要点
            3. 这一章的核心位置和重要性
            
            请用1-2段简短的段落（总共约120-170字）说明，直接开始，不需要标题或开场白。使用简体中文书写。
            """
        } else if isChinese {
            prompt = """
            請為以下聖經章節提供背景和作者資訊：
            
            經卷：\(book)
            章：\(chapter)
            
            請簡要包含：
            1. 作者和寫作背景
            2. 歷史背景和文化脈絡要點
            3. 這一章的核心位置和重要性
            
            請用1-2段簡短的段落（總共約120-170字）說明，直接開始，不需要標題或開場白。使用繁體中文（台灣用語）書寫。
            """
        } else {
            prompt = """
            Please provide background and author information for the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Please briefly include:
            1. Author and writing background
            2. Key historical and cultural context
            3. Position and importance of this chapter
            
            Please explain in 1-2 short paragraphs (approximately 80-110 words total), start directly without title or introduction. Write in English. Keep it concise.
            """
        }
        
        let userMessage: [String: Any] = [
            "role": "user",
            "content": prompt
        ]
        
        let messages: [[String: Any]] = [systemMessage, userMessage]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 400
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }
                    
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        continuation.yield(content)
                                    }
                                }
                            }
                            
                            if !remainingString.isEmpty {
                                byteBuffer = remainingString.data(using: .utf8) ?? Data()
                            } else {
                                byteBuffer.removeAll()
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func searchBible(query: String, language: Language) async throws -> [SearchResult] {
        // TODO: Implement Bible search
        // Reference: migration/api/bible-search/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func findVerseForPrayer(focus: String, need: String, language: Language, appLanguage: AppLanguage) async throws -> DailyVerse {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        // Build prompt for AI to suggest a verse
        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者专家。用户想要为以下情况祷告：
            
            心中的关注：\(focus)
            需要的帮助：\(need)
            
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
        
        // Call OpenAI API
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 200
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8),
              let suggestion = try? JSONSerialization.jsonObject(with: jsonData2) as? [String: Any],
              let reference = suggestion["reference"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }
        
        // Parse reference like "John 3:16" or "1 Corinthians 13:4"
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
        
        // Find the book in BibleData
        guard let book = BibleData.book(named: bookName) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Book not found: \(bookName)"])
        }
        
        // Load verse from BibleService
        let bibleService = BibleService.shared
        let verses = try await bibleService.loadVerses(book: book.name, chapter: chapter, translation: language)
        
        guard let verse = verses.first(where: { $0.verseNumber == verseNumber }) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verse not found: \(bookName) \(chapter):\(verseNumber)"])
        }
        
        // Convert to DailyVerse
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
        
        // Build prompt for AI to generate rationale - 2-3 sentences
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
        
        // Call OpenAI API
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 250
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Clean and return the rationale
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Journey Analysis
    
    func analyzeJourney(data: JourneyDataForAI, appLanguage: AppLanguage) async throws -> AIJourneyAnalysis {
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
        
        // Helper function to format intentional actions for prompt
        func formatIntentionalActions(_ actions: [IntentionalAction], typeLabel: String, isChinese: Bool) -> String {
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
                // Add date for recent actions to show recency
                if typeLabel.contains("Recent") || typeLabel.contains("最近") {
                    result += "\n   \(isChinese ? "日期" : "Date"): \(dateFormatter.string(from: action.date))"
                }
                return result
            }.joined(separator: "\n\n")
        }
        
        // Build prioritized data summary for AI
        let readingBooksStr = data.readingHistory.isEmpty ? (isChinese ? "尚無閱讀記錄" : "No reading history yet") : data.readingHistory.joined(separator: ", ")
        let savedBooksStr = data.savedVerseBooks.isEmpty ? (isChinese ? "尚無保存經文" : "No saved verses yet") : data.savedVerseBooks.joined(separator: ", ")
        let labelsStr = data.savedVerseLabels.isEmpty ? (isChinese ? "無標籤" : "No labels") : data.savedVerseLabels.joined(separator: ", ")
        let goalsStr = data.spiritualGoals.isEmpty ? (isChinese ? "尚未設定目標" : "No goals set") : data.spiritualGoals.joined(separator: ", ")
        
        // Format intentional actions by priority
        let customPrayersStr = formatIntentionalActions(data.customPrayers, typeLabel: isChinese ? "自訂禱告" : "Custom Prayers", isChinese: isChinese)
        let prayerTopicsStr = formatIntentionalActions(data.prayerTopics, typeLabel: isChinese ? "禱告主題" : "Prayer Topics", isChinese: isChinese)
        let questionsStr = formatIntentionalActions(data.questions, typeLabel: isChinese ? "提問" : "Questions", isChinese: isChinese)
        let savedNotesWithContentStr = formatIntentionalActions(data.savedNotesWithContent, typeLabel: isChinese ? "有筆記的保存經文" : "Saved Notes with Content", isChinese: isChinese)
        let savedNotesWithoutContentStr = formatIntentionalActions(data.savedNotesWithoutContent, typeLabel: isChinese ? "無筆記的保存經文" : "Saved Notes (no content)", isChinese: isChinese)
        
        // Format recent 5 actions (most important for status generation)
        let recentActionsStr = formatIntentionalActions(data.recentActions, typeLabel: isChinese ? "最近5個行動" : "Recent 5 Actions", isChinese: isChinese)
        
        let prompt: String
        if isChinese {
            prompt = """
            你是一位溫暖且鼓勵人的屬靈導師。請根據以下用戶的信仰成長數據，生成一份個人化的分析報告。

            用戶資料：
            - 名字：\(data.userName.isEmpty ? "朋友" : data.userName)
            - 靈命階段：\(data.spiritualMaturity)
            - 目標：\(goalsStr)

            **【最重要】最近5個行動 - 這些最能反映用戶目前的屬靈狀態和關注焦點：**
            \(recentActionsStr)

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
            - 總共閱讀章數：\(data.stats.totalChaptersRead)（用戶可能只是快速瀏覽，不要過度解讀）
            - 保存經文數：\(data.stats.totalVersesSaved)
            - 連續簽到天數：\(data.currentStreak)
            - 總活躍天數：\(data.totalDaysActive)
            - 閱讀過的書卷：\(readingBooksStr)
            - 保存經文的書卷：\(savedBooksStr)
            - 使用的標籤：\(labelsStr)

            請生成以下內容（以JSON格式回應）：

            {
              "encouragement": "簡短的一句鼓勵（15-20字以內）。要具體且溫暖但簡潔。例如：「你在箴言中尋求智慧，顯示一顆渴望成長的心。」",
              "journeySummary": "簡短總結用戶的信仰歷程特點（30-50字），重點分析他們與經文的互動模式和屬靈狀態",
              "pathStatus": {
                "title": "路上的你 - 必須基於最近5個行動中的實際經文內容和用戶行為，創造一個具體、有創意、令人印象深刻的狀態描述。例如：如果用戶最近保存了約翰福音3:16並寫了關於愛的筆記，可以說「在愛的真理中扎根」；如果最近為焦慮禱告並使用腓立比書4:6-7，可以說「在憂慮中尋求平安」。絕對不要用模糊的詞彙如「成長中」、「理解中」等。要具體引用經文主題或用戶關注的屬靈主題。",
                "description": "擴展的情境分析（約60字）。分析用戶最近的行動，提供具體洞察。結構：以一句簡短的鼓勵開頭，然後提供關於他們旅程的分析內容。引用他們歷史中的具體經文、筆記、禱告或問題。避免泛泛的鼓勵 - 專注於他們的行動揭示了什麼關於他們的屬靈焦點和成長。要有洞察力但不過度情緒化。",
                "iconName": "SF Symbol 名稱（如 figure.walk, heart.fill, lightbulb.fill, star.fill, flame.fill, sparkles, hands.sparkles.fill）"
              },
              "recommendedVerse": {
                "reference": "推薦經文出處（英文書名 章:節，如 Philippians 4:13）",
                "text": "經文內容（繁體中文）",
                "reason": "為什麼推薦這節經文（15-25字），要與用戶的屬靈狀態和需要相關"
              },
              "pathHighlights": [
                {"emoji": "📖", "fact": "第一個路徑亮點（15-25字），基於用戶的有意識行為"},
                {"emoji": "⭐", "fact": "第二個路徑亮點（15-25字），觀察他們的屬靈成長模式"},
                {"emoji": "✨", "fact": "第三個路徑亮點（15-25字），鼓勵或洞察"}
              ],
              "nextStep": "下一步建議（20-30字），具體且可執行，要與用戶目前的狀態相關"
            }

            **重要規則：**
            1. 語氣要溫暖但分析性 - 避免過度情緒化的語言
            2. **encouragement 必須是簡短的一句話（15-20字）**：這只是一個簡短的開場，不是主要內容
            3. **pathStatus.description 是主要內容（約60字）**：在這裡提供實質性分析。引用最近行動中的具體經文/主題。解釋他們的行動揭示了什麼關於他們的屬靈旅程
            4. **pathStatus的title必須基於最近5個行動的實際內容**：仔細閱讀最近5個行動中的經文內容、筆記、禱告主題，創造一個具體、有創意、令人印象深刻的狀態描述
            5. **絕對避免模糊詞彙**：不要用「成長中」、「理解中」、「學習中」等泛泛而談的詞。要具體引用經文主題、屬靈主題或用戶關注的焦點
            6. **必須引用具體內容**：如果用戶最近保存了某節經文，pathStatus應該反映那節經文的主題；如果最近為某個主題禱告，應該反映那個主題；如果有筆記，應該反映筆記中的思考
            7. 優先分析用戶的「有意識行為」（自訂禱告、提問、筆記），這些比單純閱讀更能反映屬靈狀態
            8. 仔細閱讀用戶保存的經文內容和筆記，分析他們關注的主題和屬靈需要
            9. 「pathStatus」要描述用戶「在路徑上的狀態」，而不是「性格類型」。要反映他們如何與神的話語互動，以及目前的屬靈狀態
            10. 如果用戶有自訂禱告或筆記，要特別關注這些內容，分析他們關注的主題和需要
            11. 閱讀章節數只是背景資訊，不要過度解讀（用戶可能只是快速瀏覽）
            12. recommendedVerse 的 reference 必須用英文書名
            13. 只回傳JSON，不要其他文字
            """
        } else {
            prompt = """
            You are a warm and encouraging mentor. Based on the following user's faith journey data, generate a personalized analysis report.

            User Profile:
            - Name: \(data.userName.isEmpty ? "Friend" : data.userName)
            - Stage: \(data.spiritualMaturity)
            - Goals: \(goalsStr)

            **[MOST IMPORTANT] Recent 5 Actions - These best reflect user's current spiritual state and focus:**
            \(recentActionsStr)

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
            - Total chapters read: \(data.stats.totalChaptersRead) (User may have just skimmed, don't over-interpret)
            - Verses saved: \(data.stats.totalVersesSaved)
            - Current streak: \(data.currentStreak) days
            - Total active days: \(data.totalDaysActive)
            - Books read: \(readingBooksStr)
            - Books with saved verses: \(savedBooksStr)
            - Labels used: \(labelsStr)

            Please generate the following content (respond in JSON format):

            {
              "encouragement": "A SHORT 1-sentence encouragement (15-20 words max). Be specific and warm but concise. Example: 'Your pursuit of wisdom in Proverbs shows a heart eager to grow.'",
              "journeySummary": "Brief summary of the user's journey characteristics (20-40 words), focus on their interaction patterns with Scripture and spiritual state",
              "pathStatus": {
                "title": "Along the Path - MUST be based on actual verse content and user actions from the recent 5 actions. Create a specific, creative, and impressive status description. For example: if user recently saved John 3:16 with a note about love, say 'Rooted in Love's Truth'; if recently prayed about anxiety using Philippians 4:6-7, say 'Seeking Peace in Worry'. NEVER use vague terms like 'growing', 'understanding', 'learning'. Must specifically reference verse themes or spiritual themes the user is focusing on.",
                "description": "EXPANDED in-context analysis (~60 words). Analyze the user's recent actions to provide specific insights. Structure: Start with one brief encouraging sentence, then provide analytical content about their journey. Reference specific verses, notes, prayers, or questions from their history. Avoid generic encouragement - focus on what their actions reveal about their spiritual focus and growth. Be insightful but not overly emotional.",
                "iconName": "SF Symbol name (e.g., figure.walk, heart.fill, lightbulb.fill, star.fill, flame.fill, sparkles, hands.sparkles.fill)"
              },
              "recommendedVerse": {
                "reference": "Recommended verse reference (English book name Chapter:Verse, e.g., Philippians 4:13)",
                "text": "The verse text in English",
                "reason": "Why this verse is recommended (15-25 words), should relate to user's spiritual state and needs"
              },
              "pathHighlights": [
                {"emoji": "📖", "fact": "First path highlight (15-25 words), based on user's intentional actions"},
                {"emoji": "⭐", "fact": "Second path highlight (15-25 words), observe their spiritual growth patterns"},
                {"emoji": "✨", "fact": "Third path highlight (15-25 words), encouragement or insight"}
              ],
              "nextStep": "Suggested next step (15-25 words), specific and actionable, should relate to user's current state"
            }

            **Important Rules:**
            1. Tone should be warm but analytical - avoid excessive emotional language
            2. **encouragement MUST be 1 short sentence (15-20 words)**: This is just a brief opener, not the main content
            3. **pathStatus.description is the MAIN content (~60 words)**: Provide substantive analysis here. Reference specific verses/themes from recent actions. Explain what their actions reveal about their spiritual journey
            4. **pathStatus title MUST be based on actual content from recent 5 actions**: Carefully read the verse content, notes, and prayer topics from the recent 5 actions, create a specific, creative, and impressive status description
            5. **Absolutely avoid vague terms**: Don't use generic phrases like "growing", "understanding", "learning". Must specifically reference verse themes, spiritual themes, or focus areas the user is engaging with
            6. **Must reference specific content**: If user recently saved a verse, pathStatus should reflect that verse's theme; if recently prayed about a topic, should reflect that topic; if has notes, should reflect the thoughts in those notes
            7. Prioritize analyzing user's "intentional actions" (custom prayers, questions, notes) - these better reflect spiritual state than just reading
            8. Carefully read the verse content and notes user saved, analyze themes they're focusing on and spiritual needs
            9. "pathStatus" should describe user's "status along the path", NOT a "personality type". Reflect how they interact with God's Word and their current spiritual state
            10. If user has custom prayers or notes, pay special attention to these contents, analyze themes and needs they're focusing on
            11. Chapter reading count is just background info, don't over-interpret (user may have just skimmed)
            12. recommendedVerse reference must use English book names
            13. Return only JSON, no other text
            """
        }
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1500
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8),
              let analysisJson = try? JSONSerialization.jsonObject(with: jsonData2) as? [String: Any] else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }
        
        // Parse the response into our model
        let encouragement = analysisJson["encouragement"] as? String ?? ""
        let journeySummary = analysisJson["journeySummary"] as? String ?? ""
        let nextStep = analysisJson["nextStep"] as? String ?? ""
        
        // Parse path status (formerly readingPersonality)
        var pathStatus = PathStatus(title: "Along the Path", description: "Beginning your journey", iconName: "figure.walk")
        if let statusJson = analysisJson["pathStatus"] as? [String: Any] {
            pathStatus = PathStatus(
                title: statusJson["title"] as? String ?? "Along the Path",
                description: statusJson["description"] as? String ?? "",
                iconName: statusJson["iconName"] as? String ?? "figure.walk"
            )
        } else if let personalityJson = analysisJson["readingPersonality"] as? [String: Any] {
            // Fallback for old format
            pathStatus = PathStatus(
                title: personalityJson["title"] as? String ?? "Along the Path",
                description: personalityJson["description"] as? String ?? "",
                iconName: personalityJson["iconName"] as? String ?? "figure.walk"
            )
        }
        
        // Parse recommended verse
        var recommendedVerse: RecommendedVerse? = nil
        if let verseJson = analysisJson["recommendedVerse"] as? [String: Any] {
            recommendedVerse = RecommendedVerse(
                reference: verseJson["reference"] as? String ?? "",
                text: verseJson["text"] as? String ?? "",
                reason: verseJson["reason"] as? String ?? ""
            )
        }
        
        // Parse path highlights (formerly funFacts)
        var pathHighlights: [PathHighlight] = []
        if let highlightsJson = analysisJson["pathHighlights"] as? [[String: Any]] {
            pathHighlights = highlightsJson.map { highlightJson in
                PathHighlight(
                    emoji: highlightJson["emoji"] as? String ?? "✨",
                    fact: highlightJson["fact"] as? String ?? ""
                )
            }
        } else if let factsJson = analysisJson["funFacts"] as? [[String: Any]] {
            // Fallback for old format
            pathHighlights = factsJson.map { factJson in
                PathHighlight(
                    emoji: factJson["emoji"] as? String ?? "✨",
                    fact: factJson["fact"] as? String ?? ""
                )
            }
        }
        
        return AIJourneyAnalysis(
            encouragement: encouragement,
            journeySummary: journeySummary,
            pathStatus: pathStatus,
            recommendedVerse: recommendedVerse,
            pathHighlights: pathHighlights,
            nextStep: nextStep
        )
    }
    
    // MARK: - Personalized Reading Plan Generation
    
    struct UserHistoryContext {
        let recentNotes: [String] // Recent note contents or verse references
        let recentPrayers: [String] // Recent prayer topics or custom prayers
        let recentQuestions: [String] // Recent questions asked
        let readingHistory: [String] // Books/chapters read
        let savedVerseReferences: [String] // Verse references saved
    }
    
    struct PlanQuestion {
        let question: String
        let contextCaption: String // Why we asked this question
        let options: [QuestionOption]
        let allowsMultipleSelection: Bool
    }
    
    struct QuestionOption: Codable {
        let id: String
        let text: String
    }
    
    func generatePersonalizedPlanQuestions(
        profile: UserProfile,
        history: UserHistoryContext?,
        appLanguage: AppLanguage
    ) async throws -> [PlanQuestion] {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        // Build context string
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        let goals = profile.spiritualGoals.isEmpty ? 
            (isChinese ? (isSimplified ? "无特定目标" : "無特定目標") : "no specific goals") :
            profile.spiritualGoals.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", ")
        let focusAreas = profile.lifeFocusAreas.isEmpty ?
            (isChinese ? (isSimplified ? "未设定" : "未設定") : "not set") :
            profile.lifeFocusAreas.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", ")
        
        var contextString = ""
        if let history = history {
            // Warm start - use history
            let recentActivity = [
                history.recentNotes.isEmpty ? nil : "Recent notes: \(history.recentNotes.prefix(3).joined(separator: ", "))",
                history.recentPrayers.isEmpty ? nil : "Recent prayers: \(history.recentPrayers.prefix(3).joined(separator: ", "))",
                history.recentQuestions.isEmpty ? nil : "Recent questions: \(history.recentQuestions.prefix(2).joined(separator: ", "))",
                history.readingHistory.isEmpty ? nil : "Reading history: \(history.readingHistory.prefix(5).joined(separator: ", "))"
            ].compactMap { $0 }.joined(separator: "\n")
            
            contextString = """
            User Profile:
            - Spiritual Maturity: \(maturity)
            - Goals: \(goals)
            - Life Focus Areas: \(focusAreas)
            
            Recent Activity:
            \(recentActivity)
            """
        } else {
            // Cold start - use profile only
            contextString = """
            User Profile:
            - Spiritual Maturity: \(maturity)
            - Goals: \(goals)
            - Life Focus Areas: \(focusAreas)
            - Daily Time Commitment: \(profile.dailyTimeCommitment.localizedDisplayName(for: appLanguage))
            
            Note: This is a new user with no reading history yet.
            """
        }
        
        let prompt: String
        if isSimplified {
            prompt = """
            你是一位属灵导师，正在帮助用户创建个性化的阅读计划。
            
            \(contextString)
            
            请生成2-3个深入且相关的问题，帮助了解用户的具体需求和期望。每个问题应该：
            1. 基于用户的属灵阶段、目标和生活焦点领域
            2. 如果用户有活动历史，要参考他们的笔记、祷告和问题
            3. 问题应该具体、有针对性，能帮助生成更个性化的阅读计划
            
            请以JSON数组格式返回，每个问题包含：
            {
              "question": "问题内容",
              "contextCaption": "为什么问这个问题（简短说明，不超过30字）",
              "allowsMultipleSelection": false（true表示可多选，false表示单选）,
              "options": [
                {"id": "option1", "text": "选项1"},
                {"id": "option2", "text": "选项2"},
                {"id": "option3", "text": "选项3"},
                {"id": "option4", "text": "选项4"}
              ]
            }
            
            每个问题应有3-5个选项。只返回JSON数组，不要其他文字。
            """
        } else if isChinese {
            prompt = """
            你是一位屬靈導師，正在幫助用戶創建個性化的閱讀計劃。
            
            \(contextString)
            
            請生成2-3個深入且相關的問題，幫助了解用戶的具體需求和期望。每個問題應該：
            1. 基於用戶的屬靈階段、目標和生活焦點領域
            2. 如果用戶有活動歷史，要參考他們的筆記、禱告和問題
            3. 問題應該具體、有針對性，能幫助生成更個性化的閱讀計劃
            
            請以JSON陣列格式返回，每個問題包含：
            {
              "question": "問題內容",
              "contextCaption": "為什麼問這個問題（簡短說明，不超過30字）",
              "allowsMultipleSelection": false（true表示可多選，false表示單選）,
              "options": [
                {"id": "option1", "text": "選項1"},
                {"id": "option2", "text": "選項2"},
                {"id": "option3", "text": "選項3"},
                {"id": "option4", "text": "選項4"}
              ]
            }
            
            每個問題應有3-5個選項。只返回JSON陣列，不要其他文字。
            """
        } else {
            prompt = """
            You are a spiritual mentor helping a user create a personalized reading plan.
            
            \(contextString)
            
            Please generate 2-3 insightful and relevant questions to understand the user's specific needs and expectations. Each question should:
            1. Be based on the user's spiritual maturity, goals, and life focus areas
            2. If the user has activity history, reference their notes, prayers, and questions
            3. Be specific and targeted to help generate a more personalized reading plan
            
            Please return in JSON array format, each question containing:
            {
              "question": "Question text",
              "contextCaption": "Why we're asking this (brief explanation, max 30 words)",
              "allowsMultipleSelection": false (true for multiple choice, false for single choice),
              "options": [
                {"id": "option1", "text": "Option 1"},
                {"id": "option2", "text": "Option 2"},
                {"id": "option3", "text": "Option 3"},
                {"id": "option4", "text": "Option 4"}
              ]
            }
            
            Each question should have 3-5 options. Return only JSON array, no other text.
            """
        }
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Parse JSON response
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8),
              let questionsArray = try? JSONSerialization.jsonObject(with: jsonData2) as? [[String: Any]] else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }
        
        return questionsArray.compactMap { questionJson -> PlanQuestion? in
            guard let question = questionJson["question"] as? String,
                  let caption = questionJson["contextCaption"] as? String,
                  let optionsArray = questionJson["options"] as? [[String: Any]] else {
                return nil
            }
            
            let allowsMultiple = questionJson["allowsMultipleSelection"] as? Bool ?? false
            
            let options = optionsArray.compactMap { optionJson -> QuestionOption? in
                guard let id = optionJson["id"] as? String,
                      let text = optionJson["text"] as? String else {
                    return nil
                }
                return QuestionOption(id: id, text: text)
            }
            
            guard !options.isEmpty else { return nil }
            
            return PlanQuestion(
                question: question,
                contextCaption: caption,
                options: options,
                allowsMultipleSelection: allowsMultiple
            )
        }
    }
    
    func generateReadingPlan(
        answers: [String: String],
        profile: UserProfile,
        appLanguage: AppLanguage
    ) async throws -> ReadingPlan {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        // Build context from profile and answers
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        let goals = profile.spiritualGoals.isEmpty ? 
            (isChinese ? (isSimplified ? "无特定目标" : "無特定目標") : "no specific goals") :
            profile.spiritualGoals.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", ")
        
        let answersText = answers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        
        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者和属灵导师。请根据以下信息生成一个个性化的阅读计划。
            
            用户资料：
            - 属灵阶段：\(maturity)
            - 目标：\(goals)
            - 生活焦点：\(profile.lifeFocusAreas.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", "))
            
            用户回答：
            \(answersText)
            
            请生成一个完整的阅读计划，以JSON格式返回：
            {
              "title": "计划标题（简洁，不超过20字）",
              "description": "简短描述（不超过50字）",
              "extendedDescription": "详细描述（100-150字）",
              "icon": "SF Symbol名称（必须从以下选择：book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, flame.fill, sparkles）",
              "category": "book|topical|devotional",
              "days": [
                {
                  "dayNumber": 1,
                  "book": "BookName（英文书名）",
                  "chapter": 1,
                  "verseStart": null（可选，如果只读部分章节）,
                  "verseEnd": null（可选）,
                  "description": "简短标题（不超过15字）",
                  "chapterDescription": "为什么读这一章（50-80字）"
                }
              ]
            }
            
            重要规则：
            1. 根据用户的属灵阶段选择合适的深度和内容
            2. 如果用户是初学者，推荐经典且广为人知的故事（如大卫和歌利亚、浪子回头等）
            3. 如果用户有特定目标（如寻找平安、理解圣经等），选择相关主题的经文
            4. 计划天数根据用户回答的"duration"决定（3-14天）
            5. 每天一章或相关章节，确保内容连贯且有意义
            6. 书名必须使用英文（如John, Psalms, Matthew等）
            7. 只返回JSON，不要其他文字
            
            请确保JSON格式正确，可以直接解析。
            """
        } else if isChinese {
            prompt = """
            你是一位聖經學者和屬靈導師。請根據以下資訊生成一個個性化的閱讀計劃。
            
            用戶資料：
            - 屬靈階段：\(maturity)
            - 目標：\(goals)
            - 生活焦點：\(profile.lifeFocusAreas.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", "))
            
            用戶回答：
            \(answersText)
            
            請生成一個完整的閱讀計劃，以JSON格式返回：
            {
              "title": "計劃標題（簡潔，不超過20字）",
              "description": "簡短描述（不超過50字）",
              "extendedDescription": "詳細描述（100-150字）",
              "icon": "SF Symbol名稱（必須從以下選擇：book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, flame.fill, sparkles）",
              "category": "book|topical|devotional",
              "days": [
                {
                  "dayNumber": 1,
                  "book": "BookName（英文書名）",
                  "chapter": 1,
                  "verseStart": null（可選，如果只讀部分章節）,
                  "verseEnd": null（可選）,
                  "description": "簡短標題（不超過15字）",
                  "chapterDescription": "為什麼讀這一章（50-80字）"
                }
              ]
            }
            
            重要規則：
            1. 根據用戶的屬靈階段選擇合適的深度和內容
            2. 如果用戶是初學者，推薦經典且廣為人知的故事（如大衛和歌利亞、浪子回頭等）
            3. 如果用戶有特定目標（如尋找平安、理解聖經等），選擇相關主題的經文
            4. 計劃天數根據用戶回答的"duration"決定（3-14天）
            5. 每天一章或相關章節，確保內容連貫且有意義
            6. 書名必須使用英文（如John, Psalms, Matthew等）
            7. 只返回JSON，不要其他文字
            
            請確保JSON格式正確，可以直接解析。
            """
        } else {
            prompt = """
            You are a Bible scholar and spiritual mentor. Please generate a personalized reading plan based on the following information.
            
            User Profile:
            - Spiritual Maturity: \(maturity)
            - Goals: \(goals)
            - Life Focus Areas: \(profile.lifeFocusAreas.map { $0.localizedDisplayName(for: appLanguage) }.joined(separator: ", "))
            
            User Answers:
            \(answersText)
            
            Please generate a complete reading plan in JSON format:
            {
              "title": "Plan title (concise, max 20 words)",
              "description": "Brief description (max 50 words)",
              "extendedDescription": "Detailed description (100-150 words)",
              "icon": "SF Symbol name (must be one of: book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, flame.fill, sparkles)",
              "category": "book|topical|devotional",
              "days": [
                {
                  "dayNumber": 1,
                  "book": "BookName (English book name)",
                  "chapter": 1,
                  "verseStart": null (optional, if reading partial chapter),
                  "verseEnd": null (optional),
                  "description": "Short title (max 15 words)",
                  "chapterDescription": "Why read this chapter (50-80 words)"
                }
              ]
            }
            
            Important Rules:
            1. Choose appropriate depth and content based on user's spiritual maturity
            2. If user is a beginner, recommend classic well-known stories (like David and Goliath, Prodigal Son, etc.)
            3. If user has specific goals (like finding peace, understanding Scripture, etc.), choose relevant thematic verses
            4. Plan duration based on user's "duration" answer (3-14 days)
            5. One chapter or related chapters per day, ensuring coherent and meaningful content
            6. Book names must be in English (e.g., John, Psalms, Matthew)
            7. Return only JSON, no other text
            
            Ensure JSON format is correct and can be parsed directly.
            """
        }
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get AI response"])
        }
        
        // Parse JSON response with retry logic
        let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData2 = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }
        
        // Try to decode the plan
        do {
            let planJson = try JSONSerialization.jsonObject(with: jsonData2) as? [String: Any]
            guard let planJson = planJson else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
            }
            
            // Parse the plan
            guard let title = planJson["title"] as? String,
                  let description = planJson["description"] as? String,
                  let rawIcon = planJson["icon"] as? String,
                  let categoryStr = planJson["category"] as? String,
                  let category = ReadingPlan.PlanCategory(rawValue: categoryStr),
                  let daysArray = planJson["days"] as? [[String: Any]] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields in plan JSON"])
            }
            
            // Validate the icon - use a fallback if the AI returns an invalid SF Symbol
            let validIcons = [
                "book.fill", "heart.fill", "lightbulb.fill", "leaf.fill", "mountain.2.fill",
                "star.fill", "sun.max.fill", "flame.fill", "sparkles", "cross.fill",
                "hand.raised.fill", "person.fill", "figure.walk", "figure.mind.and.body",
                "water.waves", "moon.fill", "bolt.fill", "shield.fill", "crown.fill",
                "graduationcap.fill", "book.closed.fill", "text.book.closed.fill",
                "globe.americas.fill", "hands.clap.fill", "heart.text.square.fill"
            ]
            let icon = validIcons.contains(rawIcon) ? rawIcon : "book.fill"
            
            // imageName is no longer used - SereneBackgroundManager assigns backgrounds automatically
            let imageName = "auto-assigned"
            
            let extendedDescription = planJson["extendedDescription"] as? String
            
            let days = try daysArray.map { dayJson -> ReadingPlanDay in
                guard let dayNumber = dayJson["dayNumber"] as? Int,
                      let book = dayJson["book"] as? String,
                      let chapter = dayJson["chapter"] as? Int else {
                    throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid day structure"])
                }
                
                let verseStart = dayJson["verseStart"] as? Int
                let verseEnd = dayJson["verseEnd"] as? Int
                let dayDescription = dayJson["description"] as? String
                let chapterDescription = dayJson["chapterDescription"] as? String
                
                return ReadingPlanDay(
                    dayNumber: dayNumber,
                    book: book,
                    chapter: chapter,
                    verseStart: verseStart,
                    verseEnd: verseEnd,
                    description: dayDescription,
                    chapterDescription: chapterDescription
                )
            }
            
            // Generate unique ID for custom plan
            let planId = "custom-\(UUID().uuidString)"
            
            return ReadingPlan(
                id: planId,
                title: title,
                description: description,
                extendedDescription: extendedDescription,
                icon: icon,
                imageName: imageName,
                days: days,
                category: category
            )
        } catch {
            // If parsing fails, try to repair JSON (basic attempt)
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse reading plan: \(error.localizedDescription)"])
        }
    }
}

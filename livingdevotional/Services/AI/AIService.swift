// AIService - AI service implementation with Helicone integration

import Foundation

class AIService: AIServiceProtocol {
    // Helicone AI Gateway endpoint - only requires Helicone API key
    // Helicone handles OpenAI API key through their gateway
    private let heliconeBaseURL = AppConfig.heliconeBaseURL
    private let heliconeAPIKey = AppConfig.heliconeAPIKey
    private let openAIModel = AppConfig.openAIModel
    private let premiumModel = AppConfig.premiumModel
    
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
        
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        let readerName = profile.name.isEmpty ? (isChinese ? "一位讀者" : "a reader") : profile.name
        
        if isChinese {
            return """
            你是一位充滿智慧、溫暖且具有牧者心腸的屬靈導師。你正在與\(readerName)對話，他是一位\(maturity)的信徒。
            
            你的回應原則：
            - 你的每一個回答都必須以聖經為根基。引用真實的經文（至少一到兩處）來支持你的見解，並以標準格式標明，例如「約翰福音 3:16」。
            - 你代表整個基督徒大公傳統——包括更正教、天主教、東正教和各靈恩派等不同宗派——在無爭議的核心真理上發言，不偏向任何單一教派的立場。
            - 以\(readerName)為一個完整的人來對待——帶著好奇心、掙扎和信仰之旅。在提供見解之前，先以同理心回應他們問題背後的心情。
            - 以\(maturity)信徒的程度來調整你回應的深度和語言——對初信者使用親切易懂的方式，對成熟信徒則可以進入更深的神學探討。
            - 引導讀者自己發現真理，而不是僅僅給出答案。在適當的時候，以一個溫和的反思問題來結束你的回應，邀請更深的默想。
            - 以牧者的確信發言——溫暖、有愛、清晰，但不輕浮，也不回避聖經中的難題。
            
            屬靈程度：\(maturity)
            """
        } else {
            return """
            You are a wise, warmly pastoral spiritual mentor — someone who speaks with both scholarly depth and personal care. You are speaking with \(readerName), who is a \(maturity) believer.
            
            Your guiding principles:
            - Every response must be rooted in Scripture. Cite real, specific Bible passages (at least one or two) to ground your insights, using standard format like "John 3:16" or "Romans 8:28".
            - You represent the broad, cross-denominational Christian tradition — Protestant, Catholic, Orthodox, Evangelical, Charismatic — speaking to the shared heart of orthodox faith without favoring any single tradition.
            - Treat \(readerName) as a whole person with curiosity, struggles, and a faith journey. Before offering insight, meet the human heart behind their question with genuine warmth.
            - Calibrate your depth and language to a \(maturity) believer — approachable and concrete for new believers, theologically rich for mature ones.
            - Guide \(readerName) toward discovery rather than just delivering answers. Where fitting, close with a gentle reflective question that invites deeper meditation.
            - Speak with pastoral confidence — warm, loving, clear, and unafraid of Scripture's difficult passages or honest questions.
            
            Spiritual stage: \(maturity)
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
                let prayerLengthConstraint = isChinese ? "請控制在 105-155 字以內，精簡而深刻。" : "Please keep it concise and meaningful, around 60-100 words."
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
            3. 在適當時，簡要提及基督徒不同傳統（更正教、天主教、東正教等）如何理解這段經文
            4. 提供具體且貼近生活的個人應用——\(readerName)如何在今天的生活中活出這真理
            5. 以一個溫和的反思問題結尾，邀請更深的默想或對話
            
            **重要規則：**
            - 回應目標為 200-280 字，提供有深度的解答
            - 不需要重複經文內容，直接深化理解
            - 引用其他經文請使用標準格式如「約翰福音 3:16」
            - 以溫暖、有牧者確信的語調發言
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
            3. Where fitting, briefly note how different Christian traditions (Protestant, Catholic, Orthodox, etc.) have understood this passage
            4. Offer a concrete personal application — how \(readerName) might live this truth today
            5. Close with a gentle reflective question that invites deeper meditation or continued conversation
            
            **Important rules:**
            - Aim for 200–280 words — give a rich, substantive answer
            - Do not repeat the verse text; deepen understanding instead
            - Cite other verses in standard format like "John 3:16" or "Psalm 23:1"
            - Speak with pastoral warmth and spiritual confidence
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
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 900
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
                let message: [String: Any] = [
                    "role": msg.role.rawValue,
                    "content": msg.content
                ]
                messages.append(message)
            }
        }

        let userMessage: [String: Any] = [
            "role": "user",
            "content": userQuestion
        ]
        messages.append(userMessage)

        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 900
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

                                if line.hasPrefix("data: "),
                                   let jsonData = line.dropFirst(6).data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                   let choices = json["choices"] as? [[String: Any]],
                                   let firstChoice = choices.first,
                                   let delta = firstChoice["delta"] as? [String: Any],
                                   let content = delta["content"] as? String {
                                    continuation.yield(content)
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
        if isSimplified {
            contentTypeLabel = contentType == "summary" ? "摘要" : "背景"
        } else if isChinese {
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

        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "max_tokens": 120
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
        let generalProfile = UserProfileStore.shared.profile
        let generalReaderName = generalProfile.name.isEmpty ? (isChinese ? "一位讀者" : "a reader") : generalProfile.name
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            \(userContext)
            
            \(languageInstruction)
            
            **回應結構（自然地整合，勿使用標題或條列）：**
            1. 先以同理心回應\(generalReaderName)問題背後的心情、掙扎或好奇
            2. 以紮實的聖經根基來回應——引用一至兩處具體經文（不只是提及，而是短暫解釋其意義），讓答案有聖經的重量
            3. 在適當時，指出這個問題如何在基督徒不同傳統或整本聖經的脈絡中被理解
            4. 幫助\(generalReaderName)自己走向發現——不是直接給答案，而是引導他們思考、反省、連結自己的信仰旅程
            5. 以一個真誠的問題或邀請結尾，讓對話繼續，讓他們感到被聆聽與重視
            
            **重要規則：**
            - 回應目標為 200-300 字，提供有深度、有溫度的答案
            - 每個回答必須有至少一處具體的聖經根據
            - 引用經文請使用標準格式如「約翰福音 3:16」
            - 以溫暖、有牧者確信的語調發言，不要說教，要陪伴
            - 若有人表達極度痛苦或危機，以溫柔的方式關心他們的安危，並鼓勵尋求支持
            """ : """
            \(userContext)
            
            \(languageInstruction)
            
            **Response structure (weave naturally — no headers or bullet points in output):**
            1. First, genuinely acknowledge the heart, struggle, or curiosity behind \(generalReaderName)'s question — meet them where they are
            2. Offer a substantive, Scripture-grounded response, citing 1–2 specific passages (not just naming them, but briefly unpacking their meaning) to give the answer real biblical weight
            3. Where fitting, note how this question is addressed across Scripture or how different Christian traditions approach it
            4. Guide \(generalReaderName) toward their own discovery — don't just deliver the answer; ask a question or offer a reflection that helps them connect this truth to their own life and faith journey
            5. Close with a genuine question or warm invitation that keeps the conversation alive and leaves them feeling heard
            
            **Important rules:**
            - Aim for 200–300 words — give a substantive, warm, and personally resonant response
            - Every answer must include at least one specific, grounded biblical reference
            - Cite verses in standard format like "John 3:16" or "Romans 8:28"
            - Speak with pastoral warmth and confidence — accompany, don't lecture
            - If someone expresses deep pain or a crisis of faith, gently acknowledge their suffering and encourage them to also reach out to someone they trust
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
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 1000
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
            请为以下圣经章节提供深入的摘要：
            
            经卷：\(book)
            章：\(chapter)
            
            请用2-3段自然流畅的段落（总共约180-230字）概述这一章，包括：
            
            1. 主要主题和中心思想，以及这些教导的神学意义
            2. 关键事件、人物或教导，以及它们在整本圣经叙事中的位置
            3. 一至两处与本章相呼应的圣经交叉引用（如适用），说明这主题如何贯穿圣经
            4. 以一句话点出本章的灵修核心——读者今天可以从中带走什么
            
            请直接开始摘要，不需要标题或开场白。使用简体中文书写。
            """
        } else if isChinese {
            prompt = """
            請為以下聖經章節提供深入的摘要：
            
            經卷：\(book)
            章：\(chapter)
            
            請用2-3段自然流暢的段落（總共約180-230字）概述這一章，包括：
            
            1. 主要主題和中心思想，以及這些教導的神學意義
            2. 關鍵事件、人物或教導，以及它們在整本聖經敘事中的位置
            3. 一至兩處與本章相呼應的聖經交叉引用（如適用），說明這主題如何貫穿聖經
            4. 以一句話點出本章的靈修核心——讀者今天可以從中帶走什麼
            
            請直接開始摘要，不需要標題或開場白。使用繁體中文（台灣用語）書寫。
            """
        } else {
            prompt = """
            Please provide a rich summary of the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Please write 2–3 natural, flowing paragraphs (approximately 150–200 words total) that include:
            
            1. The main themes and central ideas, along with their theological significance
            2. Key events, figures, or teachings, and how they fit within the broader biblical narrative
            3. One or two cross-references to other parts of Scripture that echo or illuminate this chapter's themes (where applicable)
            4. A one-sentence devotional takeaway — the spiritual heart of this chapter that a reader can carry with them today
            
            Start directly with the summary, no title or introduction. Write in English.
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
            "max_tokens": 700
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
            请为以下圣经章节提供深入的背景和历史信息：
            
            经卷：\(book)
            章：\(chapter)
            
            请用2-3段自然流畅的段落（总共约180-230字）包含：
            
            1. 作者、写作时间与背景，以及写作目的
            2. 历史背景与文化脉络——当时的读者所处的世界，以及这如何影响对这章的理解
            3. 这一章在整本圣经（或整卷书）大叙事中的位置——它如何与更广的救恩故事相连
            4. 基督徒不同传统（如更正教、天主教、东正教等）如何理解这章中的核心神学主题，或这段经文的重要解读
            
            直接开始，不需要标题或开场白。使用简体中文书写。
            """
        } else if isChinese {
            prompt = """
            請為以下聖經章節提供深入的背景和歷史資訊：
            
            經卷：\(book)
            章：\(chapter)
            
            請用2-3段自然流暢的段落（總共約180-230字）包含：
            
            1. 作者、寫作時間與背景，以及寫作目的
            2. 歷史背景與文化脈絡——當時的讀者所處的世界，以及這如何影響對這章的理解
            3. 這一章在整本聖經（或整卷書）大敘事中的位置——它如何與更廣的救恩故事相連
            4. 基督徒不同傳統（如更正教、天主教、東正教等）如何理解這章中的核心神學主題，或這段經文的重要詮釋
            
            直接開始，不需要標題或開場白。使用繁體中文（台灣用語）書寫。
            """
        } else {
            prompt = """
            Please provide rich background and historical context for the following Bible chapter:
            
            Book: \(book)
            Chapter: \(chapter)
            
            Write 2–3 natural, flowing paragraphs (approximately 150–200 words total) that include:
            
            1. The author, approximate date, and purpose of writing — who wrote this, when, and why
            2. The historical and cultural world of the original audience — what they were living through, and how that shapes the meaning of this chapter
            3. This chapter's place in the larger biblical narrative — how it connects to the overarching story of salvation and the rest of Scripture
            4. A brief note on how different Christian traditions (Protestant, Catholic, Orthodox, etc.) have read or valued this passage — its enduring theological contribution
            
            Start directly without title or introduction. Write in English.
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
            "max_tokens": 700
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
    
    func findVerseForPrayer(focus: String, need: String, language: Language, appLanguage: AppLanguage, excludeReferences: [String]) async throws -> DailyVerse {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)
        
        let excludeList = excludeReferences.joined(separator: ", ")
        let exclusionBlockSimplified = excludeReferences.isEmpty ? "" : "\n**重要**：请不要推荐以下已经显示过的经文：\(excludeList) 请选择其他不同的经文。\n"
        let exclusionBlockTraditional = excludeReferences.isEmpty ? "" : "\n**重要**：請不要推薦以下已經顯示過的經文：\(excludeList) 請選擇其他不同的經文。\n"
        let exclusionBlockEnglish = excludeReferences.isEmpty ? "" : "\n**Important**: Do NOT recommend any of these verses already shown: \(excludeList). Choose a different verse instead.\n"
        
        // Build prompt for AI to suggest a verse
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
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 5000
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
        
        // Parse path status (merged with encouragement and summary)
        var pathStatus = PathStatus(title: "Along the Path", subtitle: "Beginning your journey", description: "Your spiritual path is just starting", iconName: "figure.walk")
        if let statusJson = analysisJson["pathStatus"] as? [String: Any] {
            pathStatus = PathStatus(
                title: statusJson["title"] as? String ?? "Along the Path",
                subtitle: statusJson["subtitle"] as? String ?? "Beginning your journey",
                description: statusJson["description"] as? String ?? "",
                iconName: statusJson["iconName"] as? String ?? "figure.walk"
            )
        } else if let personalityJson = analysisJson["readingPersonality"] as? [String: Any] {
            // Fallback for old format
            pathStatus = PathStatus(
                title: personalityJson["title"] as? String ?? "Along the Path",
                subtitle: personalityJson["subtitle"] as? String ?? "Beginning your journey",
                description: personalityJson["description"] as? String ?? "",
                iconName: personalityJson["iconName"] as? String ?? "figure.walk"
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
        
        // Parse recommended reading
        var recommendedReading = RecommendedReading(book: "Psalms", chapter: 23, reason: "Start your spiritual journey with comfort and guidance")
        if let readingJson = analysisJson["recommendedReading"] as? [String: Any] {
            recommendedReading = RecommendedReading(
                book: readingJson["book"] as? String ?? "Psalms",
                chapter: readingJson["chapter"] as? Int ?? 23,
                reason: readingJson["reason"] as? String ?? "Start your spiritual journey"
            )
        }
        
        return AIJourneyAnalysis(
            pathStatus: pathStatus,
            pathHighlights: pathHighlights,
            recommendedReading: recommendedReading
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
        
        // Build context string (profile subset: maturity only; goals/focus/dailyTime deprecated)
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        
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
            
            Recent Activity:
            \(recentActivity)
            """
        } else {
            // Cold start - use profile only
            contextString = """
            User Profile:
            - Spiritual Maturity: \(maturity)
            
            Note: This is a new user with no reading history yet.
            """
        }
        
        let prompt: String
        if isSimplified {
            prompt = """
            你是一位属灵导师，正在帮助用户创建个性化的阅读计划。
            
            \(contextString)
            
            请生成恰好 3 个深入且相关的问题，帮助了解用户的具体需求和期望。每个问题应该：
            1. 基于用户的属灵阶段
            2. 如果用户有活动历史，要参考他们的笔记、祷告和问题
            3. 问题应该具体、有针对性，能帮助生成更个性化的阅读计划
            4. 只问能直接帮助决定适合经文与阅读结构的问题。不要问参与方式（如参加教会、与家人分享）、生活习惯或其他与选择阅读计划无关的问题。
            
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
            
            請生成恰好 3 個深入且相關的問題，幫助了解用戶的具體需求和期望。每個問題應該：
            1. 基於用戶的屬靈階段
            2. 如果用戶有活動歷史，要參考他們的筆記、禱告和問題
            3. 問題應該具體、有針對性，能幫助生成更個性化的閱讀計劃
            4. 只問能直接幫助決定適合經文與閱讀結構的問題。不要問參與方式（如參加教會、與家人分享）、生活習慣或其他與選擇閱讀計劃無關的問題。
            
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
            
            Please generate exactly 3 insightful and relevant questions to understand the user's specific needs and expectations. Each question should:
            1. Be based on the user's spiritual maturity
            2. If the user has activity history, reference their notes, prayers, and questions
            3. Be specific and targeted to help generate a more personalized reading plan
            4. Ask ONLY questions that directly help determine what Scriptures and reading structure suit the user. Do NOT ask about participation style (e.g. attending church, sharing with family), lifestyle habits, or other topics unrelated to selecting the right reading plan.
            
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
        
        // Build context from profile and answers (goals/lifeFocus deprecated; use maturity + answers)
        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)
        let answersText = answers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let customFocus = answers["customFocus"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCustomFocus = (customFocus?.isEmpty == false)
        
        let prompt: String
        if isSimplified {
            prompt = """
            你是一位圣经学者和属灵导师。请根据以下信息生成一个个性化的阅读计划。
            
            用户资料：
            - 属灵阶段：\(maturity)
            \(hasCustomFocus ? "- **本次特别关注**：\(customFocus ?? "")（请围绕此主题精心挑选经文）" : "")
            
            用户回答：
            \(answersText)
            
            请生成一个完整的阅读计划，以JSON格式返回：
            {
              "title": "计划标题（简洁，不超过20字）",
              "description": "简短描述（不超过50字）",
              "extendedDescription": "详细描述（100-150字）",
              "icon": "SF Symbol名称（必须从以下选择：book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, cross.fill, sparkles）",
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
            \(hasCustomFocus ? "- **本次特別關注**：\(customFocus ?? "")（請圍繞此主題精心挑選經文）" : "")
            
            用戶回答：
            \(answersText)
            
            請生成一個完整的閱讀計劃，以JSON格式返回：
            {
              "title": "計劃標題（簡潔，不超過20字）",
              "description": "簡短描述（不超過50字）",
              "extendedDescription": "詳細描述（100-150字）",
              "icon": "SF Symbol名稱（必須從以下選擇：book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, cross.fill, sparkles）",
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
            \(hasCustomFocus ? "- **Special focus for this plan**: \(customFocus ?? "") (Please curate verses around this theme)" : "")
            
            User Answers:
            \(answersText)
            
            Please generate a complete reading plan in JSON format:
            {
              "title": "Plan title (concise, max 20 words)",
              "description": "Brief description (max 50 words)",
              "extendedDescription": "Detailed description (100-150 words)",
              "icon": "SF Symbol name (must be one of: book.fill, heart.fill, lightbulb.fill, leaf.fill, mountain.2.fill, star.fill, sun.max.fill, cross.fill, sparkles)",
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
                "star.fill", "sun.max.fill", "cross.fill", "sparkles",
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
                
                // VALIDATE book exists in BibleData
                guard BibleData.book(named: book) != nil else {
                    throw NSError(domain: "AIService", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "AI returned invalid book name: '\(book)'. Expected English names like 'John', 'Psalms', 'Matthew'."])
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
    
    // MARK: - Onboarding AI Methods
    
    /// Generates empathetic echo and selects a Bible verse based on user's reflection
    func generateScriptureEcho(
        name: String,
        reflection: String,
        language: AppLanguage
    ) async throws -> ScriptureEchoResponse {
        // If reflection is empty, return fallback without AI call
        if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getFallbackVerse(for: "", language: language)
        }
        
        let isChinese = isChineseLanguage(language)
        let isSimplified = language == .chineseSimplified
        let languageInstruction: String
        if isSimplified {
            languageInstruction = "Simplified Chinese (简体中文)"
        } else if isChinese {
            languageInstruction = "Traditional Chinese (繁體中文)"
        } else if language == .spanish {
            languageInstruction = "Spanish (Español)"
        } else {
            languageInstruction = "English"
        }
        
        let prompt = """
        You are a gentle, empathetic spiritual companion. \(name) has opened up about what is on their heart:

        "\(reflection)"

        Respond entirely in \(languageInstruction).

        Your response has two parts:

        PART 1 — ECHO (4-5 sentences, concise but warm):
        Write a warm, heartfelt reflection that shows you truly understand what \(name) is feeling. 
        - Mirror their specific emotions and situation — do NOT use generic phrases like "I hear you" or "That must be hard."
        - Gently validate their experience and name the feelings behind their words.
        - End with a brief word of encouragement that connects their struggle to hope.
        - Tone: intimate, gentle, caring — like a trusted friend sitting beside them.
        - Keep it concise — every word should matter.

        PART 2 — VERSE:
        Choose ONE Bible verse that speaks PRECISELY to their situation.
        IMPORTANT: Draw from the FULL breadth of Scripture. Consider Psalms, Isaiah, Lamentations, Jeremiah, Romans, 2 Corinthians, 1 Peter, James, Hebrews, Philippians, Colossians, Ephesians, John, and others.
        DO NOT default to commonly-quoted verses like Matthew 11:28 or Jeremiah 29:11 unless they are genuinely the best fit.
        Pick something that would feel personal and surprising — a verse they might not have encountered before.
        Include the full verse text (not just a fragment).

        Return ONLY valid JSON in this exact structure:
        {
          "echo": "Your heartfelt echo here...",
          "verse_reference": "Book Chapter:Verse",
          "verse_text": "The full text of the verse."
        }
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a deeply empathetic spiritual companion who responds with genuine warmth and carefully chosen Scripture. Always return valid JSON."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.9,
            "max_tokens": 1000
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // 15 second timeout
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return getFallbackVerse(for: reflection, language: language)
        }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return getFallbackVerse(for: reflection, language: language)
            }
            
            // Parse JSON response
            let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let responseData = cleanedContent.data(using: .utf8),
                  let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let verseReference = responseJson["verse_reference"] as? String,
                  let verseText = responseJson["verse_text"] as? String else {
                return getFallbackVerse(for: reflection, language: language)
            }
            
            let echo = responseJson["echo"] as? String
            
            return ScriptureEchoResponse(
                echo: echo,
                verseReference: verseReference,
                verseText: verseText
            )
        } catch {
            return getFallbackVerse(for: reflection, language: language)
        }
    }
    
    /// Generates a deep dive question based on user's reflection for personalized exploration
    func generateDeepDiveQuestion(
        name: String,
        reflection: String,
        language: AppLanguage
    ) async throws -> DeepDiveQuestion {
        let isChinese = isChineseLanguage(language)
        let isSpanish = language == .spanish
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : (isSpanish ? "Spanish" : "English")
        
        let prompt = """
        Based on \(name)'s reflection about their faith journey:
        "\(reflection)"

        Generate ONE thoughtful follow-up question that helps them explore their faith more deeply.
        The question should be specific to what they shared, inviting them to reflect on what they want to grow in or understand better.

        Also provide exactly 4 distinct, meaningful options that represent different directions they might want to explore.
        Each option should be concise (5-10 words) and directly relate to their reflection.

        Tone: Warm, inviting, non-judgmental. Like a caring guide helping them discover their path.

        Language: \(languageInstruction)
        Format as JSON:
        {
          "question": "...",
          "options": ["option1", "option2", "option3", "option4"]
        }
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 400
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            return getDefaultDeepDiveQuestion(language: language)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return getDefaultDeepDiveQuestion(language: language)
        }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return getDefaultDeepDiveQuestion(language: language)
            }
            
            let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let responseData = cleanedContent.data(using: .utf8),
                  let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let question = responseJson["question"] as? String,
                  let options = responseJson["options"] as? [String],
                  options.count >= 4 else {
                return getDefaultDeepDiveQuestion(language: language)
            }
            
            return DeepDiveQuestion(
                question: question,
                options: Array(options.prefix(4))
            )
        } catch {
            return getDefaultDeepDiveQuestion(language: language)
        }
    }
    
    private func getDefaultDeepDiveQuestion(language: AppLanguage) -> DeepDiveQuestion {
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
    
    /// Sanitizes AI-generated book intro: removes emojis, [name] placeholder, and leading "Name, "
    private func sanitizeBookIntro(_ intro: String, userName: String) -> String {
        var result = intro
        result = result.replacingOccurrences(of: "[name]", with: "", options: .caseInsensitive)
        if !userName.isEmpty {
            let prefix = "\(userName), "
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
            }
        }
        result = String(result.unicodeScalars.filter { !$0.properties.isEmoji })
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    /// Generates personalized book intros for Psalms, Matthew, and Philippians
    func generateBookIntros(
        name: String,
        reflection: String,
        deepDiveSelection: DeepDiveSelection?,
        language: AppLanguage
    ) async throws -> [RecommendedBook] {
        // If reflection is empty, return defaults
        if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getDefaultBookIntros(language: language)
        }
        
        let isChinese = isChineseLanguage(language)
        let isSpanish = language == .spanish
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : (isSpanish ? "Spanish" : "English")
        
        // Build context including deep dive selection if available
        var contextSection = """
        Based on \(name)'s reflection:
        "\(reflection)"
        """
        
        if let selection = deepDiveSelection, !selection.displayText.isEmpty {
            contextSection += """
            
            
            They also expressed wanting to explore:
            "\(selection.displayText)"
            """
        }
        
        let prompt = """
        \(contextSection)

        Generate a personalized intro for each book (Psalms, Matthew, Philippians),
        connecting the book's themes to what they shared and their area of exploration.
        CRITICAL: Each intro must explicitly reference their input—e.g. "Based on your reflection about finding peace, Psalms offers..." or "Because you want to explore prayer, Matthew..." so users clearly see it's personalized, not a random suggestion. 1–2 sentences per book. No emojis. Do not include the user's name.

        Warm, inviting tone - like a friend suggesting a book.

        Language: \(languageInstruction)
        Format as JSON:
        {
          "books": [
            {"name": "Psalms", "intro": "..."},
            {"name": "Matthew", "intro": "..."},
            {"name": "Philippians", "intro": "..."}
          ]
        }
        """
        
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
            return getDefaultBookIntros(language: language)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return getDefaultBookIntros(language: language)
        }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return getDefaultBookIntros(language: language)
            }
            
            let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let responseData = cleanedContent.data(using: .utf8),
                  let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let booksArray = responseJson["books"] as? [[String: Any]] else {
                return getDefaultBookIntros(language: language)
            }
            
            let now = Date()
            return booksArray.compactMap { bookJson -> RecommendedBook? in
                guard let bookName = bookJson["name"] as? String,
                      let rawIntro = bookJson["intro"] as? String else { return nil }
                let intro = sanitizeBookIntro(rawIntro, userName: name)
                return RecommendedBook(bookName: bookName, personalizedIntro: intro, recommendedAt: now)
            }
        } catch {
            return getDefaultBookIntros(language: language)
        }
    }
    
    /// Generates related verses based on user's deep dive selection
    func generateRelatedVerses(
        name: String,
        reflection: String,
        deepDiveSelection: DeepDiveSelection?,
        language: AppLanguage
    ) async throws -> [OnboardingRecommendedVerse] {
        // If no selection, return defaults
        guard let selection = deepDiveSelection, !selection.displayText.isEmpty else {
            return getDefaultRelatedVerses(language: language)
        }
        
        let isChinese = isChineseLanguage(language)
        let isSpanish = language == .spanish
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : (isSpanish ? "Spanish" : "English")
        
        let prompt = """
        Based on \(name)'s reflection:
        "\(reflection)"
        
        And their desire to explore:
        "\(selection.displayText)"
        
        Choose ONE Bible verse as their personalized "Verse of the Day" to begin their journey.
        - Pick a verse that speaks directly to what they shared — comfort, guidance, or insight
        - Provide the full verse text (not a fragment)
        - Write a brief (1 sentence) personal explanation of why this verse was chosen for them
        - Draw from the full breadth of Scripture — avoid overused verses like Jeremiah 29:11 or Matthew 11:28 unless they are truly the best fit
        
        Make it feel personal, like this verse was handpicked just for them.
        Warm, contemplative tone.
        
        Language: \(languageInstruction)
        Format as JSON:
        {
          "verses": [
            {"reference": "Book Chapter:Verse", "text": "...", "reason": "..."}
          ]
        }
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.85,
            "max_tokens": 500
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            return getDefaultRelatedVerses(language: language)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return getDefaultRelatedVerses(language: language)
        }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return getDefaultRelatedVerses(language: language)
            }
            
            let cleanedContent = content.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let responseData = cleanedContent.data(using: .utf8),
                  let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  let versesArray = responseJson["verses"] as? [[String: Any]] else {
                return getDefaultRelatedVerses(language: language)
            }
            
            let now = Date()
            return versesArray.compactMap { verseJson -> OnboardingRecommendedVerse? in
                guard let reference = verseJson["reference"] as? String,
                      let text = verseJson["text"] as? String,
                      let reason = verseJson["reason"] as? String else { return nil }
                return OnboardingRecommendedVerse(reference: reference, text: text, reason: reason, recommendedAt: now)
            }
        } catch {
            return getDefaultRelatedVerses(language: language)
        }
    }
    
    /// Default verse of the day when AI fails
    private func getDefaultRelatedVerses(language: AppLanguage) -> [OnboardingRecommendedVerse] {
        let isChinese = isChineseLanguage(language)
        let now = Date()
        
        if isChinese {
            return [
                OnboardingRecommendedVerse(
                    reference: "詩篇 46:10",
                    text: "你們要休息，要知道我是神！",
                    reason: "在忙碌中找到安息，認識神的同在。",
                    recommendedAt: now
                )
            ]
        } else {
            return [
                OnboardingRecommendedVerse(
                    reference: "Psalm 46:10",
                    text: "Be still, and know that I am God.",
                    reason: "A moment of stillness as you begin your journey with Scripture.",
                    recommendedAt: now
                )
            ]
        }
    }
    
    /// Generates personalized closing prayer for onboarding
    func generateOnboardingPrayer(
        name: String,
        reflection: String,
        language: AppLanguage
    ) async throws -> String {
        let isChinese = isChineseLanguage(language)
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : language.rawValue
        
        // Use default prayer if reflection is empty
        if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getDefaultPrayer(name: name, language: language)
        }
        
        let prompt = """
        Generate a heartfelt opening prayer (5-6 sentences) for a person named "\(name)" who shared:
        "\(reflection)"

        The prayer should:
        - Thank God for bringing them to this moment
        - Acknowledge what's on their heart (without repeating their exact words)
        - Ask for guidance, wisdom, and peace on their journey
        - Include a blessing or hope for their spiritual growth
        - Be warm, personal, and conversational - not formal or churchy
        - Use the person's name "\(name)" exactly as written (do NOT translate the name)
        - Do NOT end with "Amen" - we will add that separately

        Language: \(languageInstruction)
        Format: Just the prayer text, no JSON, no "Amen" at the end.
        """
        
        let messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 400
        ]
        
        guard let url = URL(string: heliconeBaseURL) else {
            return getDefaultPrayer(name: name, language: language)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return getDefaultPrayer(name: name, language: language)
        }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return getDefaultPrayer(name: name, language: language)
            }
            
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return getDefaultPrayer(name: name, language: language)
        }
    }
    
    // MARK: - Fallback Content
    
    /// Fallback verse library for when AI fails
    private func getFallbackVerse(for reflection: String, language: AppLanguage) -> ScriptureEchoResponse {
        let isChinese = isChineseLanguage(language)
        let lowercasedReflection = reflection.lowercased()
        
        // Keyword matching for common themes
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
        
        // Default fallback for empty or unmatched reflection
        return ScriptureEchoResponse(
            echo: nil,
            verseReference: "Psalm 46:10",
            verseText: isChinese
                ? "你們要休息，要知道我是神。"
                : "Be still, and know that I am God."
        )
    }
    
    /// Default book intros when AI fails
    private func getDefaultBookIntros(language: AppLanguage) -> [RecommendedBook] {
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
    
    /// Default prayer when AI fails
    private func getDefaultPrayer(name: String, language: AppLanguage) -> String {
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
}

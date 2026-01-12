// AIService - AI service implementation with Helicone integration

import Foundation

class AIService: AIServiceProtocol {
    // Helicone AI Gateway endpoint - only requires Helicone API key
    // Helicone handles OpenAI API key through their gateway
    private let heliconeBaseURL = "https://ai-gateway.helicone.ai/v1/chat/completions"
    private let heliconeAPIKey = "sk-helicone-mgqn4ly-q4tuuaq-qggr7va-ppikchq"
    private let openAIModel = "gpt-4o-mini"
    
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
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
        let responseLanguage = isChinese ? "繁體中文（台灣用語）" : "English"
        let languageInstruction = isChinese ? "請用繁體中文（台灣用語）提供簡潔且有幫助的回答。" : "Please provide concise and helpful responses in English."
        
        // Add system message for context
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            你是一位聖經學者和神學教師。你正在幫助讀者理解以下經文：
            
            經卷：\(book)
            章：\(chapter)
            節：\(verse)
            經文：「\(verseText)」
            
            \(languageInstruction)
            """ : """
            You are a Bible scholar and theology teacher. You are helping readers understand the following verse:
            
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
            let lengthConstraint = isChinese ? "請控制在 150-200 字以內，精簡扼要。" : "Please keep it concise, around 100-150 words."
            
            switch mode {
            case .insight:
                if isChinese {
                    initialPrompt = """
                    請深入解釋這節經文的歷史背景、文化脈絡和上下文。
                    
                    請包含：
                    1. 這節經文的歷史背景和當時的文化情境
                    2. 經文在整章或整卷書中的上下文位置和意義
                    3. 相關的經文引用（如果有的話）來幫助理解
                    4. 重要的神學概念或教義背景
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please provide insight into the historical background, cultural context, and surrounding context of this verse.
                    
                    Include:
                    1. The historical background and cultural situation of this verse
                    2. The verse's position and meaning within the chapter or book
                    3. Related verse references (if applicable) to aid understanding
                    4. Important theological concepts or doctrinal background
                    
                    Please write in English, starting with "This verse". \(lengthConstraint)
                    """
                }
            case .reflect:
                if isChinese {
                    initialPrompt = """
                    請幫助讀者將這節經文應用到現代生活中，進行靈修反思。
                    
                    請包含：
                    1. 這節經文對現代生活的啟發和應用
                    2. 具體的生活情境或例子來說明如何實踐
                    3. 個人靈修和成長的反思要點
                    4. 如何在日常生活中活出這節經文的教導
                    
                    請用繁體中文（台灣用語）書寫，使用"這節經文"開頭。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please help readers apply this verse to modern life and provide devotional reflection.
                    
                    Include:
                    1. How this verse inspires and applies to modern life
                    2. Specific life situations or examples of how to practice it
                    3. Points for personal devotion and growth
                    4. How to live out this verse's teaching in daily life
                    
                    Please write in English, starting with "This verse". \(lengthConstraint)
                    """
                }
            case .pray:
                if isChinese {
                    initialPrompt = """
                    請根據這節經文生成一篇禱告文。
                    
                    請包含：
                    1. 感謝神在這節經文中顯明的真理
                    2. 認罪和悔改（如果經文相關）
                    3. 祈求神幫助我們活出這節經文的教導
                    4. 為個人、家庭、教會或社會的需要代求（根據經文內容）
                    
                    請用繁體中文（台灣用語）書寫，以"親愛的天父"或"主啊"開頭。\(lengthConstraint)
                    """
                } else {
                    initialPrompt = """
                    Please compose a prayer based on this verse.
                    
                    Include:
                    1. Thanksgiving for the truth revealed in this verse
                    2. Confession and repentance (if relevant to the verse)
                    3. Request for God's help to live out this verse's teaching
                    4. Intercession for personal, family, church, or societal needs (based on verse content)
                    
                    Please write in English, starting with "Dear Heavenly Father" or "Lord". \(lengthConstraint)
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
        // Use more tokens for pray mode since prayers can be longer
        let maxTokens = mode == .pray ? 800 : 500
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
                    // #region agent log
                    let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
                    let logEntry1: [String: Any] = [
                        "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                        "location": "AIService.explainVerse",
                        "message": "Starting SSE stream parsing",
                        "data": ["hypothesisId": "B"],
                        "sessionId": "debug-session",
                        "runId": "performance-fix"
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry1),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                            fileHandle.closeFile()
                        } else {
                            try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                        }
                    }
                    // #endregion agent log
                    
                    // Accumulate bytes and decode incrementally
                    var byteBuffer = Data()
                    for try await byte in asyncBytes {
                        byteBuffer.append(byte)
                        
                        // Try to decode accumulated bytes as UTF-8 string
                        // If decoding fails, it means we have an incomplete UTF-8 sequence - keep accumulating
                        if let decodedString = String(data: byteBuffer, encoding: .utf8) {
                            // #region agent log
                            let logEntry2: [String: Any] = [
                                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                                "location": "AIService.explainVerse",
                                "message": "Decoded UTF-8 string successfully",
                                "data": [
                                    "decodedLength": decodedString.count,
                                    "byteBufferLength": byteBuffer.count,
                                    "hypothesisId": "B"
                                ],
                                "sessionId": "debug-session",
                                "runId": "performance-fix"
                            ]
                            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry2),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                                    fileHandle.seekToEndOfFile()
                                    fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                                    fileHandle.closeFile()
                                } else {
                                    try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                                }
                            }
                            // #endregion agent log
                            
                            // Process complete lines
                            var remainingString = decodedString
                            while let newlineIndex = remainingString.firstIndex(of: "\n") {
                                let line = String(remainingString[..<newlineIndex])
                                remainingString.removeSubrange(remainingString.startIndex...newlineIndex)
                                
                                // #region agent log
                                let logEntry3: [String: Any] = [
                                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                                    "location": "AIService.explainVerse",
                                    "message": "Processing SSE line",
                                    "data": [
                                        "lineLength": line.count,
                                        "hasDataPrefix": line.hasPrefix("data: "),
                                        "hypothesisId": "B"
                                    ],
                                    "sessionId": "debug-session",
                                    "runId": "performance-fix"
                                ]
                                if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry3),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                                        fileHandle.seekToEndOfFile()
                                        fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                                        fileHandle.closeFile()
                                    } else {
                                        try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                                    }
                                }
                                // #endregion agent log
                                
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
                                        // #region agent log
                                        let logEntry4: [String: Any] = [
                                            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                                            "location": "AIService.explainVerse",
                                            "message": "Yielding content chunk",
                                            "data": [
                                                "contentLength": content.count,
                                                "hypothesisId": "B"
                                            ],
                                            "sessionId": "debug-session",
                                            "runId": "performance-fix"
                                        ]
                                        if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry4),
                                           let jsonString = String(data: jsonData, encoding: .utf8) {
                                            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                                                fileHandle.seekToEndOfFile()
                                                fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                                                fileHandle.closeFile()
                                            } else {
                                                try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
                                            }
                                        }
                                        // #endregion agent log
                                        
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
        
        // Add system message for context
        let systemMessage: [String: Any] = [
            "role": "system",
            "content": isChinese ? """
            你是一位聖經學者和神學教師。你正在幫助讀者理解以下經文，並回答他們的問題：
            
            經卷：\(book)
            章：\(chapter)
            節：\(verse)
            經文：「\(verseText)」
            
            \(languageInstruction)
            請保持回答友善、有深度且符合聖經真理。
            """ : """
            You are a Bible scholar and theology teacher. You are helping readers understand the following verse and answering their questions:
            
            Book: \(book)
            Chapter: \(chapter)
            Verse: \(verse)
            Verse Text: "\(verseText)"
            
            \(languageInstruction)
            Please keep answers friendly, insightful, and biblically accurate.
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
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 800
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
        let isChinese = appLanguage == .chineseTraditional || (appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
        
        let prompt = isChinese ? """
        請針對以下經文生成 2 個簡短的相關問題，供讀者向 AI 提問以更深入了解經文。
        問題應簡潔明瞭（20字以內）。
        請直接列出這兩個問題，用換行分隔，不要有編號或其他文字。
        
        經文：\(book) \(chapter):\(verse) 「\(verseText)」
        """ : """
        Please generate 2 short, relevant questions about the following verse that a reader might ask an AI to understand it better.
        Questions should be concise (under 15 words).
        List the two questions directly, separated by a newline, without numbers or other text.
        
        Verse: \(book) \(chapter):\(verse) "\(verseText)"
        """
        
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
    
    func findRelatedVerses(book: String, chapter: Int, verse: Int) async throws -> [RelatedVerse] {
        // TODO: Implement related verses search
        // Reference: migration/api/find-related-verses/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func askQuestion(question: String, context: String?) async throws -> String {
        // TODO: Implement Q&A
        // Reference: migration/api/ask-question/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func summarizeChapter(book: String, chapter: Int, language: Language) async throws -> String {
        // TODO: Implement chapter summary
        // Reference: migration/api/summarize-chapter/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func searchBible(query: String, language: Language) async throws -> [SearchResult] {
        // TODO: Implement Bible search
        // Reference: migration/api/bible-search/route.ts
        throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

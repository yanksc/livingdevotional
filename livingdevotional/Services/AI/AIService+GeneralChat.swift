// AIService+GeneralChat - General spiritual chat

import Foundation

extension AIService {

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
            4. 提供完整、具體的屬靈洞見，幫助\(generalReaderName)在信仰旅程中有實際的成長與應用
            
            **重要規則：**
            - 回應目標為 600-900 字，提供有深度、有溫度的完整答案
            - 每個回答必須有至少一處具體的聖經根據
            - 引用經文請使用標準格式如「約翰福音 3:16」
            - 以溫暖、有牧者確信的語調發言，不要說教，要陪伴
            - 直接給出完整答案，不要以問題作結
            - 若有人表達極度痛苦或危機，以溫柔的方式關心他們的安危，並鼓勵尋求支持
            """ : """
            \(userContext)
            
            \(languageInstruction)
            
            **Response structure (weave naturally — no headers or bullet points in output):**
            1. First, genuinely acknowledge the heart, struggle, or curiosity behind \(generalReaderName)'s question — meet them where they are
            2. Offer a substantive, Scripture-grounded response, citing 1–2 specific passages (not just naming them, but briefly unpacking their meaning) to give the answer real biblical weight
            3. Where fitting, note how this question is addressed across Scripture or how different Christian traditions approach it
            4. Provide complete, concrete spiritual insight that gives \(generalReaderName) real, practical grounding for their faith journey
            
            **Important rules:**
            - Aim for 600–900 words — give a thorough, warm, and personally resonant response
            - Every answer must include at least one specific, grounded biblical reference
            - Cite verses in standard format like "John 3:16" or "Romans 8:28"
            - Speak with pastoral warmth and confidence — accompany, don't lecture
            - End with a complete, satisfying answer — do not close with a question
            - If someone expresses deep pain or a crisis of faith, gently acknowledge their suffering and encourage them to also reach out to someone they trust
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
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 3000
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "chatGeneral")
    }
}

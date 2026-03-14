// AIService+Summary - Chapter summary and context streaming

import Foundation

extension AIService {

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

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemContent],
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 700
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "summarizeChapterStream")
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

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemContent],
            ["role": "user", "content": prompt]
        ]

        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "stream": true,
            "stream_options": ["include_usage": false],
            "max_tokens": 700
        ]

        return try makeStreamingRequest(requestBody: requestBody, traceName: "getChapterContext")
    }
}

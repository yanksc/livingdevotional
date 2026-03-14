// AIService+Onboarding - AI methods for the onboarding flow

import Foundation

extension AIService {

    // MARK: - Onboarding AI Methods

    /// Generates empathetic echo and selects a Bible verse based on user's reflection.
    func generateScriptureEcho(
        name: String,
        reflection: String,
        language: AppLanguage
    ) async throws -> ScriptureEchoResponse {
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

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "getScriptureEcho", timeout: 15) else {
            return getFallbackVerse(for: reflection, language: language)
        }

        let cleanedContent = cleanJSONResponse(content)
        guard let responseData = cleanedContent.data(using: .utf8),
              let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let verseReference = responseJson["verse_reference"] as? String,
              let verseText = responseJson["verse_text"] as? String else {
            return getFallbackVerse(for: reflection, language: language)
        }

        return ScriptureEchoResponse(
            echo: responseJson["echo"] as? String,
            verseReference: verseReference,
            verseText: verseText
        )
    }

    /// Generates a deep dive question based on user's reflection for personalized exploration.
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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 400
        ]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateDeepDiveQuestion", timeout: 15) else {
            return getDefaultDeepDiveQuestion(language: language)
        }

        let cleanedContent = cleanJSONResponse(content)
        guard let responseData = cleanedContent.data(using: .utf8),
              let responseJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let question = responseJson["question"] as? String,
              let options = responseJson["options"] as? [String],
              options.count >= 4 else {
            return getDefaultDeepDiveQuestion(language: language)
        }

        return DeepDiveQuestion(question: question, options: Array(options.prefix(4)))
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

    /// Generates personalized book intros for Psalms, Matthew, and Philippians.
    func generateBookIntros(
        name: String,
        reflection: String,
        deepDiveSelection: DeepDiveSelection?,
        language: AppLanguage
    ) async throws -> [RecommendedBook] {
        if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getDefaultBookIntros(language: language)
        }

        let isChinese = isChineseLanguage(language)
        let isSpanish = language == .spanish
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : (isSpanish ? "Spanish" : "English")

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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateBookIntros", timeout: 15) else {
            return getDefaultBookIntros(language: language)
        }

        let cleanedContent = cleanJSONResponse(content)
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
    }

    /// Generates a personalized verse of the day based on the user's deep dive selection.
    func generateRelatedVerses(
        name: String,
        reflection: String,
        deepDiveSelection: DeepDiveSelection?,
        language: AppLanguage
    ) async throws -> [OnboardingRecommendedVerse] {
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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.85,
            "max_tokens": 500
        ]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateRelatedVerses", timeout: 20) else {
            return getDefaultRelatedVerses(language: language)
        }

        let cleanedContent = cleanJSONResponse(content)
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
    }

    /// Generates personalized closing prayer for onboarding.
    func generateOnboardingPrayer(
        name: String,
        reflection: String,
        language: AppLanguage
    ) async throws -> String {
        if reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return getDefaultPrayer(name: name, language: language)
        }

        let isChinese = isChineseLanguage(language)
        let languageInstruction = isChinese ? "Traditional Chinese (繁體中文)" : language.rawValue

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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 400
        ]

        guard let content = await makeAIRequestOptional(requestBody: requestBody, traceName: "generateOnboardingPrayer", timeout: 20) else {
            return getDefaultPrayer(name: name, language: language)
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

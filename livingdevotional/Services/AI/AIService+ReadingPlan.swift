// AIService+ReadingPlan - Personalized reading plan generation
// Types are defined at top level so they can be used in AIServiceProtocol without the AIService. prefix.

import Foundation

// MARK: - Reading Plan Types

struct UserHistoryContext {
    let recentNotes: [String]
    let recentPrayers: [String]
    let recentQuestions: [String]
    let readingHistory: [String]
    let savedVerseReferences: [String]
}

struct PlanQuestion {
    let question: String
    let contextCaption: String
    let options: [PlanQuestionOption]
    let allowsMultipleSelection: Bool
}

struct PlanQuestionOption: Codable {
    let id: String
    let text: String
}

// MARK: - Extension

extension AIService {

    func generatePersonalizedPlanQuestions(
        profile: UserProfile,
        history: UserHistoryContext?,
        appLanguage: AppLanguage
    ) async throws -> [PlanQuestion] {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

        let maturity = profile.spiritualMaturity.localizedDisplayName(for: appLanguage)

        var contextString = ""
        if let history = history {
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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": openAIModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "generatePersonalizedPlanQuestions")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8),
              let questionsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }

        return questionsArray.compactMap { questionJson -> PlanQuestion? in
            guard let question = questionJson["question"] as? String,
                  let caption = questionJson["contextCaption"] as? String,
                  let optionsArray = questionJson["options"] as? [[String: Any]] else { return nil }

            let allowsMultiple = questionJson["allowsMultipleSelection"] as? Bool ?? false
            let options = optionsArray.compactMap { optionJson -> PlanQuestionOption? in
                guard let id = optionJson["id"] as? String,
                      let text = optionJson["text"] as? String else { return nil }
                return PlanQuestionOption(id: id, text: text)
            }
            guard !options.isEmpty else { return nil }
            return PlanQuestion(question: question, contextCaption: caption, options: options, allowsMultipleSelection: allowsMultiple)
        }
    }

    func generateReadingPlan(
        answers: [String: String],
        profile: UserProfile,
        appLanguage: AppLanguage
    ) async throws -> ReadingPlan {
        let isChinese = isChineseLanguage(appLanguage)
        let isSimplified = isSimplifiedChinese(appLanguage)

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

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]
        let requestBody: [String: Any] = [
            "model": premiumModel,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 2000
        ]

        let content = try await makeAIRequest(requestBody: requestBody, traceName: "generateReadingPlan")
        let cleanedContent = cleanJSONResponse(content)

        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse AI response"])
        }

        do {
            guard let planJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
            }

            guard let title = planJson["title"] as? String,
                  let description = planJson["description"] as? String,
                  let rawIcon = planJson["icon"] as? String,
                  let categoryStr = planJson["category"] as? String,
                  let category = ReadingPlan.PlanCategory(rawValue: categoryStr),
                  let daysArray = planJson["days"] as? [[String: Any]] else {
                throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields in plan JSON"])
            }

            let validIcons = [
                "book.fill", "heart.fill", "lightbulb.fill", "leaf.fill", "mountain.2.fill",
                "star.fill", "sun.max.fill", "cross.fill", "sparkles",
                "hand.raised.fill", "person.fill", "figure.walk", "figure.mind.and.body",
                "water.waves", "moon.fill", "bolt.fill", "shield.fill", "crown.fill",
                "graduationcap.fill", "book.closed.fill", "text.book.closed.fill",
                "globe.americas.fill", "hands.clap.fill", "heart.text.square.fill"
            ]
            let icon = validIcons.contains(rawIcon) ? rawIcon : "book.fill"
            let imageName = "auto-assigned"
            let extendedDescription = planJson["extendedDescription"] as? String

            let days = try daysArray.map { dayJson -> ReadingPlanDay in
                guard let dayNumber = dayJson["dayNumber"] as? Int,
                      let book = dayJson["book"] as? String,
                      let chapter = dayJson["chapter"] as? Int else {
                    throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid day structure"])
                }

                guard BibleData.book(named: book) != nil else {
                    throw NSError(domain: "AIService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "AI returned invalid book name: '\(book)'. Expected English names like 'John', 'Psalms', 'Matthew'."])
                }

                return ReadingPlanDay(
                    dayNumber: dayNumber,
                    book: book,
                    chapter: chapter,
                    verseStart: dayJson["verseStart"] as? Int,
                    verseEnd: dayJson["verseEnd"] as? Int,
                    description: dayJson["description"] as? String,
                    chapterDescription: dayJson["chapterDescription"] as? String
                )
            }

            return ReadingPlan(
                id: "custom-\(UUID().uuidString)",
                title: title,
                description: description,
                extendedDescription: extendedDescription,
                icon: icon,
                imageName: imageName,
                days: days,
                category: category
            )
        } catch {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse reading plan: \(error.localizedDescription)"])
        }
    }
}

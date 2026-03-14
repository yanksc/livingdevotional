// AIService - AI service implementation with Helicone integration

import Foundation

class AIService: AIServiceProtocol {
    // Helicone AI Gateway endpoint - only requires Helicone API key
    // Helicone handles OpenAI API key through their gateway
    let heliconeBaseURL = AppConfig.heliconeBaseURL
    let heliconeAPIKey = AppConfig.heliconeAPIKey
    let fastModel = AppConfig.fastModel
    let openAIModel = AppConfig.openAIModel
    let premiumModel = AppConfig.premiumModel
    let langFuse = LangFuseService()

    // MARK: - Private Request Helpers

    /// Builds an authorized URLRequest for the Helicone endpoint.
    func buildRequest(requestBody: [String: Any], timeoutInterval: TimeInterval? = nil) throws -> URLRequest {
        guard let url = URL(string: heliconeBaseURL) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(heliconeAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval ?? 120
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"])
        }
        request.httpBody = jsonData
        return request
    }

    /// Executes a streaming AI request, accumulates the full response, and fires a LangFuse trace on completion.
    func makeStreamingRequest(
        requestBody: [String: Any],
        traceName: String
    ) throws -> AsyncThrowingStream<String, Error> {
        let request = try buildRequest(requestBody: requestBody)
        let model = requestBody["model"] as? String ?? openAIModel
        let messages = requestBody["messages"] as? [[String: Any]] ?? []
        let startTime = Date()

        return AsyncThrowingStream { continuation in
            Task {
                var accumulated = ""
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NSError(domain: "AIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        var errorData = Data()
                        do { for try await byte in asyncBytes { errorData.append(byte) } } catch {}
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
                        print("AIService Error: \(errorMessage)")
                        print("Status Code: \(httpResponse.statusCode)")
                        if let headers = httpResponse.allHeaderFields as? [String: Any] {
                            print("Response Headers: \(headers)")
                        }
                        continuation.finish(throwing: NSError(domain: "AIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
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
                                        langFuse.logGeneration(name: traceName, model: model, messages: messages, output: accumulated, startTime: startTime, endTime: Date())
                                        continuation.finish()
                                        return
                                    }
                                    if let jsonData = jsonString.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                       let choices = json["choices"] as? [[String: Any]],
                                       let firstChoice = choices.first,
                                       let delta = firstChoice["delta"] as? [String: Any],
                                       let content = delta["content"] as? String {
                                        accumulated += content
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
                    langFuse.logGeneration(name: traceName, model: model, messages: messages, output: accumulated, startTime: startTime, endTime: Date())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Executes a non-streaming AI request, fires a LangFuse trace, and returns the raw content string.
    func makeAIRequest(
        requestBody: [String: Any],
        traceName: String
    ) async throws -> String {
        let request = try buildRequest(requestBody: requestBody)
        let model = requestBody["model"] as? String ?? openAIModel
        let messages = requestBody["messages"] as? [[String: Any]] ?? []
        let startTime = Date()

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

        langFuse.logGeneration(name: traceName, model: model, messages: messages, output: content, startTime: startTime, endTime: Date())
        return content
    }

    /// Non-throwing variant of makeAIRequest. Returns nil on any failure — used when a fallback value is preferred over throwing.
    func makeAIRequestOptional(
        requestBody: [String: Any],
        traceName: String,
        timeout: TimeInterval? = nil
    ) async -> String? {
        guard let request = try? buildRequest(requestBody: requestBody, timeoutInterval: timeout) else {
            return nil
        }
        let model = requestBody["model"] as? String ?? openAIModel
        let messages = requestBody["messages"] as? [[String: Any]] ?? []
        let startTime = Date()

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }

        langFuse.logGeneration(name: traceName, model: model, messages: messages, output: content, startTime: startTime, endTime: Date())
        return content
    }

    /// Strips markdown code fences and trims whitespace from an AI JSON response.
    func cleanJSONResponse(_ content: String) -> String {
        content.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - User Profile Context

    func isChineseLanguage(_ appLanguage: AppLanguage) -> Bool {
        let languageCode = appLanguage.resolvedLanguageCode()
        return languageCode == "zh-Hans" || languageCode == "zh-Hant"
    }

    func isSimplifiedChinese(_ appLanguage: AppLanguage) -> Bool {
        return appLanguage.resolvedLanguageCode() == "zh-Hans"
    }

    func buildUserContext(appLanguage: AppLanguage) -> String {
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
    func buildUserContext(isChinese: Bool) -> String {
        let appLanguage: AppLanguage = isChinese ? .chineseTraditional : .english
        return buildUserContext(appLanguage: appLanguage)
    }
}

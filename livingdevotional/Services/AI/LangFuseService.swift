// LangFuseService - Fire-and-forget observability tracing via LangFuse REST API

import Foundation

final class LangFuseService {
    private let baseURL: String
    private let authHeader: String

    init(
        publicKey: String = AppConfig.langfusePublicKey,
        secretKey: String = AppConfig.langfuseSecretKey,
        baseURL: String = AppConfig.langfuseBaseURL
    ) {
        self.baseURL = baseURL
        let credentials = "\(publicKey):\(secretKey)"
        let encoded = Data(credentials.utf8).base64EncodedString()
        self.authHeader = "Basic \(encoded)"
    }

    /// Logs a completed AI generation to LangFuse. Fire-and-forget — never throws or blocks the caller.
    func logGeneration(
        name: String,
        model: String,
        messages: [[String: Any]],
        output: String,
        startTime: Date,
        endTime: Date
    ) {
        guard !AppConfig.langfusePublicKey.isEmpty, !AppConfig.langfuseSecretKey.isEmpty else { return }

        Task {
            let traceId = UUID().uuidString
            let generationId = UUID().uuidString
            let now = ISO8601DateFormatter.langfuse.string(from: Date())
            let start = ISO8601DateFormatter.langfuse.string(from: startTime)
            let end = ISO8601DateFormatter.langfuse.string(from: endTime)

            let inputForLog: Any = messages.map { msg -> [String: Any] in
                ["role": msg["role"] ?? "", "content": msg["content"] ?? ""]
            }

            let batch: [[String: Any]] = [
                [
                    "id": UUID().uuidString,
                    "type": "trace-create",
                    "timestamp": now,
                    "body": [
                        "id": traceId,
                        "name": name,
                        "timestamp": now
                    ]
                ],
                [
                    "id": UUID().uuidString,
                    "type": "generation-create",
                    "timestamp": now,
                    "body": [
                        "id": generationId,
                        "traceId": traceId,
                        "name": name,
                        "model": model,
                        "input": inputForLog,
                        "output": output,
                        "startTime": start,
                        "endTime": end
                    ]
                ]
            ]

            guard let url = URL(string: "\(baseURL)/api/public/ingestion"),
                  let body = try? JSONSerialization.data(withJSONObject: ["batch": batch]) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            _ = try? await URLSession.shared.data(for: request)
        }
    }
}

private extension ISO8601DateFormatter {
    static let langfuse: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

// AppConfig - Centralized configuration management
// API keys should be set via build settings or environment variables for production

import Foundation

enum AppConfig {
    // MARK: - API Configuration
    
    /// Helicone API Key for AI Gateway
    /// Set via build setting: HELICONE_API_KEY
    /// Or via environment variable: HELICONE_API_KEY
    static var heliconeAPIKey: String {
        // First, try to get from Info.plist (set via build settings)
        if let key = Bundle.main.object(forInfoDictionaryKey: "HELICONE_API_KEY") as? String,
           !key.isEmpty {
            return key
        }
        
        // Fallback to environment variable (for local development)
        if let key = ProcessInfo.processInfo.environment["HELICONE_API_KEY"],
           !key.isEmpty {
            return key
        }
        
        #if DEBUG
        fatalError("HELICONE_API_KEY not configured. Set it via Info.plist (build settings) or HELICONE_API_KEY environment variable.")
        #else
        // Graceful degradation in production - AI features will be unavailable
        print("⚠️ HELICONE_API_KEY not configured. AI features will be unavailable.")
        return ""
        #endif
    }
    
    /// Helicone AI Gateway base URL
    static let heliconeBaseURL = "https://ai-gateway.helicone.ai/v1/chat/completions"
    
    /// Fast model for latency-sensitive streaming features
    static let fastModel = "gpt-5.4/openai"
    
    /// Default model for most calls — balanced quality and speed
    static let openAIModel = "gpt-4.1-mini"
    
    /// Premium model for high-quality, user-facing moments (e.g. chat, journey analysis)
    static let premiumModel = "gpt-5.4/openai"

    // MARK: - Anonymous Install Identifier

    /// Stable, anonymous per-install identifier used for Helicone session tagging.
    /// Generated on first access and persisted in UserDefaults. Not tied to any
    /// personal data; resets when the user reinstalls the app.
    static var installID: String {
        let key = "AppConfig.installID"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}

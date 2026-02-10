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
    
    /// OpenAI model to use
    static let openAIModel = "gpt-4o-mini"
}

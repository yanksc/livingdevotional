// ServiceContainer - Dependency injection container

import Foundation
import SwiftUI

class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Services
    let bibleService: BibleService
    let settingsStore: SettingsStore
    let progressStore: ProgressStore
    
    // Future services (will be initialized when needed)
    var authService: AuthenticationServiceProtocol?
    var aiService: AIServiceProtocol?
    var userService: UserServiceProtocol?
    var dailyVerseService: DailyVerseServiceProtocol?
    var conversationService: ConversationServiceProtocol?
    var checkInService: CheckInServiceProtocol?
    
    private init() {
        // Initialize core services
        self.bibleService = BibleService.shared
        self.settingsStore = SettingsStore.shared
        self.progressStore = ProgressStore.shared
    }
    
    // MARK: - Service Registration
    
    func registerAuthService(_ service: AuthenticationServiceProtocol) {
        self.authService = service
    }
    
    func registerAIService(_ service: AIServiceProtocol) {
        self.aiService = service
    }
    
    func registerUserService(_ service: UserServiceProtocol) {
        self.userService = service
    }
    
    func registerDailyVerseService(_ service: DailyVerseServiceProtocol) {
        self.dailyVerseService = service
    }
    
    func registerConversationService(_ service: ConversationServiceProtocol) {
        self.conversationService = service
    }
    
    func registerCheckInService(_ service: CheckInServiceProtocol) {
        self.checkInService = service
    }
}

// MARK: - Environment Key

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}


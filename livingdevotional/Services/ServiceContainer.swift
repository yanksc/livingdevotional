// ServiceContainer - Dependency injection container

import Foundation
import SwiftUI

class ServiceContainer: ObservableObject {
    // Thread-safe singleton initialization
    private static let _shared: ServiceContainer = {
        let instance = ServiceContainer()
        return instance
    }()
    
    static var shared: ServiceContainer {
        return _shared
    }
    
    // Services
    let bibleService: BibleService
    let settingsStore: SettingsStore
    let progressStore: ProgressStore
    let checkInStore: CheckInStore
    let prayerLogStore: PrayerLogStore
    
    // Future services (will be initialized when needed)
    var authService: AuthenticationServiceProtocol?
    var aiService: AIServiceProtocol?
    var userService: UserServiceProtocol?
    var dailyVerseService: DailyVerseServiceProtocol?
    var conversationService: ConversationServiceProtocol?
    var checkInService: CheckInServiceProtocol?
    var journeyService: JourneyServiceProtocol?
    
    private init() {
        // Initialize core services
        self.bibleService = BibleService.shared
        self.settingsStore = SettingsStore.shared
        self.progressStore = ProgressStore.shared
        self.checkInStore = CheckInStore.shared
        self.prayerLogStore = PrayerLogStore.shared
        
        // Initialize DailyVerseService (without accessing ServiceContainer to avoid circular dependency)
        self.dailyVerseService = DailyVerseService.shared
        
        // Initialize JourneyService
        self.journeyService = JourneyService.shared
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


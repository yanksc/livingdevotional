// SettingsStore - Manages user preferences using UserDefaults

import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private let userDefaults = UserDefaults.standard
    private let primaryLanguageKey = "primaryLanguage"
    private let secondaryLanguageKey = "secondaryLanguage"
    private let appLanguageKey = "appLanguage"
    private let fontSizeKey = "fontSize"
    private let lineSpacingKey = "lineSpacing"
    private let showSecondaryLanguageKey = "showSecondaryLanguage"
    private let notificationsEnabledKey = "notificationsEnabled"
    private let morningTimeKey = "morningTime"
    private let eveningTimeKey = "eveningTime"
    private let streakProtectionEnabledKey = "streakProtectionEnabled"
    
    @Published var primaryLanguage: Language {
        didSet {
            savePrimaryLanguage()
            // If secondary language becomes same as primary, auto-select a different one
            if secondaryLanguage == primaryLanguage {
                // Find the first available language that's not primary and not .none
                let availableLanguages = Language.allCases.filter { $0 != .none && $0 != primaryLanguage }
                if let firstAvailable = availableLanguages.first {
                    secondaryLanguage = firstAvailable
                }
            }
        }
    }
    
    @Published var secondaryLanguage: Language {
        didSet {
            saveSecondaryLanguage()
        }
    }
    
    @Published var fontSize: Double {
        didSet {
            saveFontSize()
        }
    }
    
    @Published var lineSpacing: Double {
        didSet {
            saveLineSpacing()
        }
    }
    
    @Published var showSecondaryLanguage: Bool {
        didSet {
            saveShowSecondaryLanguage()
        }
    }
    
    @Published var appLanguage: AppLanguage {
        didSet {
            saveAppLanguage()
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            saveNotificationsEnabled()
        }
    }
    
    @Published var morningTime: Date {
        didSet {
            saveMorningTime()
        }
    }
    
    @Published var eveningTime: Date {
        didSet {
            saveEveningTime()
        }
    }
    
    @Published var streakProtectionEnabled: Bool {
        didSet {
            saveStreakProtectionEnabled()
        }
    }
    
    private init() {
        // Load saved preferences or use defaults
        if let primaryRaw = userDefaults.string(forKey: primaryLanguageKey),
           let primary = Language(rawValue: primaryRaw) {
            self.primaryLanguage = primary
        } else {
            self.primaryLanguage = .bsb // Default to BSB
        }
        
        if let secondaryRaw = userDefaults.string(forKey: secondaryLanguageKey),
           let secondary = Language(rawValue: secondaryRaw) {
            self.secondaryLanguage = secondary
        } else {
            self.secondaryLanguage = .cuv // Default to CUV
        }
        // Load fontSize or use default
        if userDefaults.object(forKey: fontSizeKey) != nil {
            self.fontSize = userDefaults.double(forKey: fontSizeKey)
        } else {
            self.fontSize = 17.0 // Default font size
        }
        
        // Load lineSpacing or use default (proper spacing for bilingual display)
        if userDefaults.object(forKey: lineSpacingKey) != nil {
            self.lineSpacing = userDefaults.double(forKey: lineSpacingKey)
        } else {
            self.lineSpacing = 4.0 // Default line spacing for proper bilingual display
        }
        
        // Load showSecondaryLanguage or use default (true by default)
        if userDefaults.object(forKey: showSecondaryLanguageKey) != nil {
            self.showSecondaryLanguage = userDefaults.bool(forKey: showSecondaryLanguageKey)
        } else {
            self.showSecondaryLanguage = true // Default to showing secondary language
        }
        
        // Load appLanguage or use default (.system)
        if let appLanguageRaw = userDefaults.string(forKey: appLanguageKey),
           let appLanguage = AppLanguage(rawValue: appLanguageRaw) {
            self.appLanguage = appLanguage
        } else {
            self.appLanguage = .system // Default to system language
        }
        
        // Load notification preferences or use defaults
        if userDefaults.object(forKey: notificationsEnabledKey) != nil {
            self.notificationsEnabled = userDefaults.bool(forKey: notificationsEnabledKey)
        } else {
            self.notificationsEnabled = true // Default to enabled
        }
        
        // Default morning time: 7:30 AM
        if let morningTimeData = userDefaults.object(forKey: morningTimeKey) as? Date {
            self.morningTime = morningTimeData
        } else {
            var components = DateComponents()
            components.hour = 7
            components.minute = 30
            self.morningTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Default evening time: 8:30 PM
        if let eveningTimeData = userDefaults.object(forKey: eveningTimeKey) as? Date {
            self.eveningTime = eveningTimeData
        } else {
            var components = DateComponents()
            components.hour = 20
            components.minute = 30
            self.eveningTime = Calendar.current.date(from: components) ?? Date()
        }
        
        // Load streak protection preference or use default
        if userDefaults.object(forKey: streakProtectionEnabledKey) != nil {
            self.streakProtectionEnabled = userDefaults.bool(forKey: streakProtectionEnabledKey)
        } else {
            self.streakProtectionEnabled = true // Default to enabled
        }
        
        // Ensure secondary language is different from primary language
        if self.secondaryLanguage == self.primaryLanguage {
            let availableLanguages = Language.allCases.filter { $0 != .none && $0 != self.primaryLanguage }
            if let firstAvailable = availableLanguages.first {
                self.secondaryLanguage = firstAvailable
            }
        }
    }
    
    private func savePrimaryLanguage() {
        userDefaults.set(primaryLanguage.rawValue, forKey: primaryLanguageKey)
    }
    
    private func saveSecondaryLanguage() {
        userDefaults.set(secondaryLanguage.rawValue, forKey: secondaryLanguageKey)
    }
    
    private func saveFontSize() {
        userDefaults.set(fontSize, forKey: fontSizeKey)
    }
    
    private func saveLineSpacing() {
        userDefaults.set(lineSpacing, forKey: lineSpacingKey)
    }
    
    private func saveShowSecondaryLanguage() {
        userDefaults.set(showSecondaryLanguage, forKey: showSecondaryLanguageKey)
    }
    
    private func saveAppLanguage() {
        userDefaults.set(appLanguage.rawValue, forKey: appLanguageKey)
    }
    
    private func saveNotificationsEnabled() {
        userDefaults.set(notificationsEnabled, forKey: notificationsEnabledKey)
    }
    
    private func saveMorningTime() {
        userDefaults.set(morningTime, forKey: morningTimeKey)
    }
    
    private func saveEveningTime() {
        userDefaults.set(eveningTime, forKey: eveningTimeKey)
    }
    
    private func saveStreakProtectionEnabled() {
        userDefaults.set(streakProtectionEnabled, forKey: streakProtectionEnabledKey)
    }
}


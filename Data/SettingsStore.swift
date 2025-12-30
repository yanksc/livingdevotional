// SettingsStore - Manages user preferences using UserDefaults

import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private let userDefaults = UserDefaults.standard
    private let primaryLanguageKey = "primaryLanguage"
    private let secondaryLanguageKey = "secondaryLanguage"
    
    @Published var primaryLanguage: Language {
        didSet {
            savePrimaryLanguage()
        }
    }
    
    @Published var secondaryLanguage: Language {
        didSet {
            saveSecondaryLanguage()
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
    }
    
    private func savePrimaryLanguage() {
        userDefaults.set(primaryLanguage.rawValue, forKey: primaryLanguageKey)
    }
    
    private func saveSecondaryLanguage() {
        userDefaults.set(secondaryLanguage.rawValue, forKey: secondaryLanguageKey)
    }
}


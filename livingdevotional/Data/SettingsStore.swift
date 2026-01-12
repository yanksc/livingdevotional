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
    private let isDarkModeKey = "isDarkMode"
    private let lineSpacingKey = "lineSpacing"
    private let showSecondaryLanguageKey = "showSecondaryLanguage"
    
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
    
    @Published var fontSize: Double {
        didSet {
            saveFontSize()
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            saveIsDarkMode()
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
        
        // Load isDarkMode or use default
        self.isDarkMode = userDefaults.bool(forKey: isDarkModeKey)
        
        // Load lineSpacing or use default (more condensed)
        if userDefaults.object(forKey: lineSpacingKey) != nil {
            self.lineSpacing = userDefaults.double(forKey: lineSpacingKey)
        } else {
            self.lineSpacing = 0.0 // Default line spacing (very condensed)
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
    
    private func saveIsDarkMode() {
        userDefaults.set(isDarkMode, forKey: isDarkModeKey)
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
}


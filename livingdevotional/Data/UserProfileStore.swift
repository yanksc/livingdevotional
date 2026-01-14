// UserProfileStore - Manages user spiritual profile persistence

import Foundation
import Combine

class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    
    @Published var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }
    
    private let fileManager = FileManager.default
    private let fileName = "user_profile.json"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {
        // Initialize with default profile first
        self.profile = UserProfile()
        
        // Then load saved profile if it exists
        if let loadedProfile = Self.loadProfileFromDisk() {
            self.profile = loadedProfile
        }
    }
    
    // MARK: - Onboarding Status
    
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveProfile()
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        profile = UserProfile()
        saveProfile()
    }
    
    // MARK: - Persistence
    
    private static func loadProfileFromDisk() -> UserProfile? {
        let fileManager = FileManager.default
        let fileName = "user_profile.json"
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let url = documentsDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("Error loading user profile: \(error)")
            return nil
        }
    }
    
    private func saveProfile() {
        guard let url = fileURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(profile)
            try data.write(to: url)
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
}

// OnboardingState - State management for 9-step onboarding flow

import Foundation
import SwiftUI
import Combine

/// Manages all state for the onboarding flow
class OnboardingState: ObservableObject {
    // MARK: - Step Navigation
    @Published var currentStep: Int = 1
    static let totalSteps = 9
    
    // MARK: - User Input (Steps 1-4)
    @Published var name: String = ""
    @Published var selectedLanguage: AppLanguage? = nil  // No pre-selection
    @Published var journeyStage: SpiritualMaturity? = nil  // No pre-selection
    @Published var reflection: String = ""
    
    // MARK: - AI-Generated Content (cached between steps)
    @Published var scriptureEcho: ScriptureEchoResponse?
    @Published var deepDiveQuestion: DeepDiveQuestion?
    @Published var deepDiveSelection: DeepDiveSelection?
    @Published var relatedVerses: [OnboardingRecommendedVerse]?  // For onboarding Step 7
    @Published var personalizedPrayer: String?
    
    // Track what reflection was used to generate content
    private var reflectionWhenEchoGenerated: String?
    private var deepDiveSelectionWhenVersesGenerated: String?
    
    // MARK: - Loading States
    @Published var isGeneratingEcho: Bool = false
    @Published var isGeneratingDeepDive: Bool = false
    @Published var isGeneratingVerses: Bool = false
    @Published var isGeneratingPrayer: Bool = false
    
    // MARK: - Error States
    @Published var echoError: Error?
    @Published var deepDiveError: Error?
    @Published var versesError: Error?
    @Published var prayerError: Error?
    
    // MARK: - User Actions
    @Published var didSaveVerse: Bool = false
    @Published var didPartner: Bool = false
    
    // MARK: - Services
    private let aiService = AIService()
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        switch currentStep {
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return selectedLanguage != nil // Must select a language
        case 3: return journeyStage != nil // Must select a journey stage
        case 4: return !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty // Reflection is required
        case 5: return scriptureEcho != nil && !isGeneratingEcho // Echo must be loaded
        case 6: return deepDiveQuestion != nil && deepDiveSelection != nil // Deep dive must be answered
        case 7: return relatedVerses != nil && !isGeneratingVerses // Related verses must be loaded
        case 8: return true // Partnership is skippable
        case 9: return personalizedPrayer != nil && !isGeneratingPrayer // Prayer must be loaded
        default: return true
        }
    }
    
    /// Resolved language - defaults to English if not yet selected
    var resolvedLanguage: AppLanguage {
        selectedLanguage ?? .english
    }
    
    var isChinese: Bool {
        guard let lang = selectedLanguage else { return false }
        return lang == .chineseTraditional || lang == .chineseSimplified
    }
    
    var isSpanish: Bool {
        selectedLanguage == .spanish
    }
    
    // MARK: - Navigation
    
    func goBack() {
        guard currentStep > 1 else { return }
        currentStep -= 1
    }
    
    func goNext() {
        guard currentStep < Self.totalSteps else { return }
        
        // Save progress incrementally
        saveProgress()
        
        // If moving from reflection to echo, check if we need to regenerate
        if currentStep == 4 {
            if reflectionWhenEchoGenerated != reflection.trimmingCharacters(in: .whitespacesAndNewlines) {
                // Reflection changed, invalidate cached content
                scriptureEcho = nil
                deepDiveQuestion = nil
                deepDiveSelection = nil
                relatedVerses = nil
                personalizedPrayer = nil
            }
        }
        
        // If moving from deep dive to verses, check if selection changed
        if currentStep == 6 {
            let currentSelection = deepDiveSelection?.displayText ?? ""
            if deepDiveSelectionWhenVersesGenerated != currentSelection {
                // Deep dive selection changed, invalidate related verses
                relatedVerses = nil
            }
        }
        
        currentStep += 1
        
        // Trigger AI generation when entering certain steps
        triggerAIGenerationIfNeeded()
    }
    
    private func triggerAIGenerationIfNeeded() {
        switch currentStep {
        case 5:
            // Generate Scripture Echo when entering Step 5
            if scriptureEcho == nil {
                generateScriptureEcho()
            }
        case 6:
            // Generate Deep Dive Question when entering Step 6
            if deepDiveQuestion == nil {
                generateDeepDiveQuestion()
            }
        case 7:
            // Generate Related Verses when entering Step 7
            if relatedVerses == nil {
                generateRelatedVerses()
            }
        case 9:
            // Generate Prayer when entering Step 9
            if personalizedPrayer == nil {
                generatePrayer()
            }
        default:
            break
        }
    }
    
    // MARK: - AI Generation
    
    func generateScriptureEcho() {
        guard !isGeneratingEcho else { return }
        
        isGeneratingEcho = true
        echoError = nil
        
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        reflectionWhenEchoGenerated = trimmedReflection
        
        Task {
            do {
                let response = try await aiService.generateScriptureEcho(
                    name: name,
                    reflection: trimmedReflection,
                    language: resolvedLanguage
                )
                await MainActor.run {
                    self.scriptureEcho = response
                    self.isGeneratingEcho = false
                }
            } catch {
                await MainActor.run {
                    self.echoError = error
                    self.isGeneratingEcho = false
                }
            }
        }
    }
    
    func generateDeepDiveQuestion() {
        guard !isGeneratingDeepDive else { return }
        
        isGeneratingDeepDive = true
        deepDiveError = nil
        
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let question = try await aiService.generateDeepDiveQuestion(
                    name: name,
                    reflection: trimmedReflection,
                    language: resolvedLanguage
                )
                await MainActor.run {
                    self.deepDiveQuestion = question
                    self.isGeneratingDeepDive = false
                }
            } catch {
                await MainActor.run {
                    self.deepDiveError = error
                    self.isGeneratingDeepDive = false
                }
            }
        }
    }
    
    func selectDeepDiveOption(_ option: String) {
        deepDiveSelection = DeepDiveSelection(selectedOption: option, customInput: nil)
    }
    
    func setDeepDiveCustomInput(_ input: String) {
        deepDiveSelection = DeepDiveSelection(selectedOption: nil, customInput: input)
    }
    
    func generateRelatedVerses() {
        guard !isGeneratingVerses else { return }
        
        isGeneratingVerses = true
        versesError = nil
        
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        deepDiveSelectionWhenVersesGenerated = deepDiveSelection?.displayText ?? ""
        
        Task {
            do {
                let verses = try await aiService.generateRelatedVerses(
                    name: name,
                    reflection: trimmedReflection,
                    deepDiveSelection: deepDiveSelection,
                    language: resolvedLanguage
                )
                await MainActor.run {
                    self.relatedVerses = verses
                    self.isGeneratingVerses = false
                }
            } catch {
                await MainActor.run {
                    self.versesError = error
                    self.isGeneratingVerses = false
                }
            }
        }
    }
    
    func generatePrayer() {
        guard !isGeneratingPrayer else { return }
        
        isGeneratingPrayer = true
        prayerError = nil
        
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let prayer = try await aiService.generateOnboardingPrayer(
                    name: name,
                    reflection: trimmedReflection,
                    language: resolvedLanguage
                )
                await MainActor.run {
                    self.personalizedPrayer = prayer
                    self.isGeneratingPrayer = false
                }
            } catch {
                await MainActor.run {
                    self.prayerError = error
                    self.isGeneratingPrayer = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    func saveVerse() {
        guard let echo = scriptureEcho else { return }
        
        let savedVerse = OnboardingSavedVerse(
            reference: echo.verseReference,
            text: echo.verseText,
            savedAt: Date(),
            source: .onboarding
        )
        
        UserProfileStore.shared.profile.savedOnboardingVerse = savedVerse
        didSaveVerse = true
    }
    
    // MARK: - Progress Saving
    
    private func saveProgress() {
        let profileStore = UserProfileStore.shared
        let settingsStore = SettingsStore.shared
        
        switch currentStep {
        case 1:
            // Save name
            profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
        case 2:
            // Apply smart defaults based on language
            if let lang = selectedLanguage {
                settingsStore.applySmartDefaults(for: lang, journeyStage: journeyStage ?? .growing)
            }
        case 3:
            // Save journey stage and apply explanation depth default
            if let stage = journeyStage {
                profileStore.profile.spiritualMaturity = stage
                profileStore.profile.explanationDepth = SettingsStore.defaultExplanationDepth(for: stage)
            }
        case 4:
            // Save reflection
            profileStore.profile.personalReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        case 5:
            // Verse can be saved via saveVerse() action if user chose to save
            break
        case 6:
            // Deep dive selection is saved in state, used for book generation
            break
        case 7:
            // Save related verses
            profileStore.profile.recommendedVerses = relatedVerses
        default:
            break
        }
    }
    
    // MARK: - View Lifecycle Helpers
    
    /// Called when ScriptureEchoView appears - triggers generation if needed
    func scriptureEchoViewDidAppear() {
        if scriptureEcho == nil && !isGeneratingEcho && echoError == nil {
            generateScriptureEcho()
        }
    }
    
    /// Called when DeepDiveQuestionView appears - triggers generation if needed
    func deepDiveQuestionViewDidAppear() {
        if deepDiveQuestion == nil && !isGeneratingDeepDive && deepDiveError == nil {
            generateDeepDiveQuestion()
        }
    }
    
    /// Called when RelatedVersesView appears - triggers generation if needed
    func relatedVersesViewDidAppear() {
        if relatedVerses == nil && !isGeneratingVerses && versesError == nil {
            generateRelatedVerses()
        }
    }
    
    /// Called when PrayerAmenView appears - triggers generation if needed
    func prayerViewDidAppear() {
        if personalizedPrayer == nil && !isGeneratingPrayer && prayerError == nil {
            generatePrayer()
        }
    }
    
    // MARK: - Completion
    
    func completeOnboarding() {
        let profileStore = UserProfileStore.shared
        let settingsStore = SettingsStore.shared
        
        // Final save of all data
        profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
        if let stage = journeyStage {
            profileStore.profile.spiritualMaturity = stage
            profileStore.profile.explanationDepth = SettingsStore.defaultExplanationDepth(for: stage)
        }
        profileStore.profile.personalReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        profileStore.profile.recommendedVerses = relatedVerses
        
        // Generate book recommendations in background for Bible view
        generateBookRecommendationsForBibleView()
        
        // Mark paywall as seen
        settingsStore.hasSeenOnboardingPaywall = true
        
        // Complete onboarding
        profileStore.completeOnboarding()
    }
    
    /// Generate book recommendations asynchronously for the Bible view
    private func generateBookRecommendationsForBibleView() {
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let books = try await aiService.generateBookIntros(
                    name: name,
                    reflection: trimmedReflection,
                    deepDiveSelection: deepDiveSelection,
                    language: resolvedLanguage
                )
                await MainActor.run {
                    UserProfileStore.shared.profile.recommendedBooks = books
                }
            } catch {
                // If AI fails, use defaults
                let isChinese = resolvedLanguage == .chineseTraditional || resolvedLanguage == .chineseSimplified
                let now = Date()
                let defaultBooks: [RecommendedBook]
                if isChinese {
                    defaultBooks = [
                        RecommendedBook(bookName: "Psalms", personalizedIntro: "心靈的詩歌，適合每一天", recommendedAt: now),
                        RecommendedBook(bookName: "Matthew", personalizedIntro: "認識耶穌的生平與教導", recommendedAt: now),
                        RecommendedBook(bookName: "Philippians", personalizedIntro: "在任何處境中找到喜樂", recommendedAt: now)
                    ]
                } else {
                    defaultBooks = [
                        RecommendedBook(bookName: "Psalms", personalizedIntro: "Songs for the soul, for every season", recommendedAt: now),
                        RecommendedBook(bookName: "Matthew", personalizedIntro: "Discover the life and teachings of Jesus", recommendedAt: now),
                        RecommendedBook(bookName: "Philippians", personalizedIntro: "Finding joy in every circumstance", recommendedAt: now)
                    ]
                }
                await MainActor.run {
                    UserProfileStore.shared.profile.recommendedBooks = defaultBooks
                }
            }
        }
    }
}

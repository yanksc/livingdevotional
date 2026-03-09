// OnboardingView - 13-step emotionally meaningful onboarding flow
// Main orchestrator - individual steps are in Views/Onboarding/
// Flow: Welcome → Name → Language → Journey → Reflection → ScriptureEcho →
//       RelationshipGoal → DeepDive → RelatedVerses → FeaturePreview → Notifications → Supporter → Prayer

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @StateObject private var state = OnboardingState()
    
    var body: some View {
        ZStack {
            Group {
                if state.currentStep == 1 {
                    Image("SplashBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipped()
                } else {
                    SereneGradientBackground()
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                // Hidden on: step 1 (welcome splash), step 12 (supporter), step 13 (prayer)
                if state.currentStep > 1 && state.currentStep < 12 {
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 20)
                }
                
                // Step content - all views have built-in navigation now
                stepContent
            }
        }
    }
    
    // MARK: - Progress Bar
    
    /// Progress spans steps 2-11 (the core journey), mapped to a 0...1 range
    private var progressBar: some View {
        let adjustedStep = Double(state.currentStep - 1) // steps 2-11 → values 1-10
        let adjustedTotal = 10.0 // 10 core steps (2 through 11)
        return ProgressView(value: adjustedStep, total: adjustedTotal)
            .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case 1:
            WelcomeSplashView(state: state)
        case 2:
            NameInputView(state: state)
        case 3:
            LanguageSelectionView(state: state)
        case 4:
            JourneySelectionView(state: state)
        case 5:
            ReflectionInputView(state: state)
        case 6:
            ScriptureEchoView(state: state)
                .onAppear { state.scriptureEchoViewDidAppear() }
        case 7:
            RelationshipGoalView(state: state)
        case 8:
            DeepDiveQuestionView(state: state)
                .onAppear { state.deepDiveQuestionViewDidAppear() }
        case 9:
            RelatedVersesView(state: state)
                .onAppear { state.relatedVersesViewDidAppear() }
        case 10:
            FeaturePreviewView(state: state)
        case 11:
            NotificationSetupView(state: state)
        case 12:
            SupporterInvitationView(state: state)
        case 13:
            PrayerAmenView(state: state) {
                // Onboarding complete - handled by state.completeOnboarding()
            }
            .onAppear { state.prayerViewDidAppear() }
        default:
            EmptyView()
        }
    }
    
}

// MARK: - Preview

#Preview {
    OnboardingView()
}

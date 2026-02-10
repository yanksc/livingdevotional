// OnboardingView - 9-step emotionally meaningful onboarding flow
// Main orchestrator - individual steps are in Views/Onboarding/

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @StateObject private var state = OnboardingState()
    
    var body: some View {
        ZStack {
            SereneGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator (hidden on paywall and final step)
                if state.currentStep < 8 {
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 20)
                }
                
                // Step content - all views have built-in navigation now
                stepContent
            }
            
            // Step 8: Partnership Invitation Overlay
            if state.currentStep == 8 {
                PartnershipInvitationView(state: state)
                    .zIndex(100)
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        ProgressView(value: Double(state.currentStep), total: Double(OnboardingState.totalSteps))
            .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case 1:
            NameInputView(state: state)
        case 2:
            LanguageSelectionView(state: state)
        case 3:
            JourneySelectionView(state: state)
        case 4:
            ReflectionInputView(state: state)
        case 5:
            ScriptureEchoView(state: state)
                .onAppear { state.scriptureEchoViewDidAppear() }
        case 6:
            DeepDiveQuestionView(state: state)
                .onAppear { state.deepDiveQuestionViewDidAppear() }
        case 7:
            RelatedVersesView(state: state)
                .onAppear { state.relatedVersesViewDidAppear() }
        case 8:
            EmptyView() // Handled by overlay
        case 9:
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

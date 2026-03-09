// JourneySelectionView - Step 4: Spiritual journey selection

import SwiftUI

struct JourneySelectionView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var visibleOptions: Set<Int> = []
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Prompt with typewriter effect
            TypewriterText(
                text: promptText,
                fontSize: OnboardingDesign.promptFontSize,
                isChinese: state.isChinese
            ) {
                // After prompt completes, start showing options
                animateOptionsIn()
            }
            
            // Journey stage options - always rendered, opacity-based visibility
            VStack(spacing: OnboardingDesign.buttonSpacing) {
                ForEach(Array(SpiritualMaturity.allCases.enumerated()), id: \.element.id) { index, stage in
                    OnboardingSelectionButton(
                        title: state.isChinese ? stage.displayNameChinese : stage.displayName,
                        isSelected: state.journeyStage == stage
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.journeyStage = stage
                        }
                        // Auto-advance after selection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            state.goNext()
                        }
                    }
                    .opacity(visibleOptions.contains(index) ? 1 : 0)
                }
            }
            .padding(.horizontal, OnboardingDesign.horizontalPadding)
            
            Spacer()
            
            // Bottom navigation - back button only (auto-advances on selection)
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Content
    
    private var promptText: String {
        state.isChinese ? "你與聖經的關係如何？" : "Where are you in your walk with Scripture?"
    }
    
    // MARK: - Animation
    
    private func animateOptionsIn() {
        // Stagger journey options fade-in
        for i in 0..<SpiritualMaturity.allCases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * OnboardingDesign.optionStaggerDelay) {
                withAnimation(.easeOut(duration: 0.8)) {
                    _ = visibleOptions.insert(i)
                }
            }
        }
    }
}

// RelationshipGoalView - Step 7: What are you looking for in your relationship with God & the Bible?

import SwiftUI

struct RelationshipGoalView: View {
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
            
            // Relationship desire options - always rendered, opacity-based visibility
            VStack(spacing: OnboardingDesign.buttonSpacing) {
                ForEach(Array(RelationshipDesire.allCases.enumerated()), id: \.element.id) { index, desire in
                    OnboardingSelectionButton(
                        title: desire.localizedDisplayName(for: state.resolvedLanguage),
                        isSelected: state.relationshipDesire == desire
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.relationshipDesire = desire
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
        if state.isChinese {
            return "在與神和聖經的關係中，\n你最渴望的是什麼？"
        } else if state.isSpanish {
            return "¿Qué buscas en tu relación con Dios y la Biblia?"
        } else {
            return "What are you looking for in your relationship with God and the Bible?"
        }
    }
    
    // MARK: - Animation
    
    private func animateOptionsIn() {
        for i in 0..<RelationshipDesire.allCases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * OnboardingDesign.optionStaggerDelay) {
                withAnimation(.easeOut(duration: 0.8)) {
                    _ = visibleOptions.insert(i)
                }
            }
        }
    }
}

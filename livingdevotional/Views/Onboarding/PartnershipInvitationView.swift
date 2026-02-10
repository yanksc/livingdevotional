// PartnershipInvitationView - Step 9: Soft paywall with feature highlights
// Redesigned as a prompt window cover with glassmorphism effect

import SwiftUI

struct PartnershipInvitationView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Dimmed background overlay to focus attention on the modal
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .transition(.opacity)
            
            // Main Modal Card
            if showContent {
                VStack(spacing: 0) {
                    // Header Image / Icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                    
                    // Title
                    Text(state.isChinese ? "開啟完整靈修體驗" : "Unlock Full Experience")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text(state.isChinese ? "支持我們持續開發，享受更多專屬功能" : "Support our mission and access premium features designed for your spiritual growth")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                        .lineSpacing(4)
                    
                    // Feature List
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "hands.sparkles.fill",
                            title: state.isChinese ? "個人化禱告" : "Personalized Prayer",
                            description: state.isChinese ? "為您的靈命狀態量身定做的禱告詞" : "Daily prayers crafted for your specific journey"
                        )
                        
                        FeatureRow(
                            icon: "chart.xyaxis.line",
                            title: state.isChinese ? "靈程分析" : "Path Analysis",
                            description: state.isChinese ? "深入分析您的靈修活動與成長軌跡" : "Deep insights into your spiritual activity history"
                        )
                        
                        FeatureRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: state.isChinese ? "情境問答" : "Contextual Answers",
                            description: state.isChinese ? "基於上下文的聖經解答與指引" : "Biblical answers tailored to your context"
                        )
                        
                        FeatureRow(
                            icon: "book.fill",
                            title: state.isChinese ? "專屬讀經計畫" : "Tailored Reading Plans",
                            description: state.isChinese ? "AI 生成的客製化讀經進度" : "Curated plans generated just for you"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: openPartnership) {
                            Text(state.isChinese ? "成為夥伴" : "Become a Partner")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.buttonGradient)
                                .cornerRadius(12)
                                .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: skipPartnership) {
                            Text(state.isChinese ? "之後再說" : "Maybe Later")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    // Back button at bottom
                    HStack {
                        OnboardingBackButton(state: state)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(
                    ZStack {
                        // Glassmorphism background
                        Rectangle()
                            .fill(.ultraThinMaterial)
                        
                        // Subtle white tint for better readability
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                    }
                )
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
                // Limit width for iPad
                .frame(maxWidth: 400)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Helper Views
    
    private struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 24, height: 24)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func openPartnership() {
        state.didPartner = true
        SettingsStore.shared.hasSeenOnboardingPaywall = true
        withAnimation {
            state.goNext()
        }
    }
    
    private func skipPartnership() {
        SettingsStore.shared.hasSeenOnboardingPaywall = true
        withAnimation {
            state.goNext()
        }
    }
}

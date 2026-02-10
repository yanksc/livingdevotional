// JourneyAIViews.swift
// AI-related views for the Journey feature: loading, error, and insights button

import SwiftUI

// MARK: - Spiritual Loading View

struct AILoadingView: View {
    @State private var progress: Double = 0.0
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let loadingMessage = "Reflecting on your journey..."
    let loadingMessageChinese = "回顧您的信仰歷程..."
    
    var body: some View {
        VStack(spacing: 24) {
            // Circular Progress Ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(AppTheme.accentColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppTheme.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
            }
            
            // Single loading message
            Text(settingsStore.appLanguage == .chineseTraditional ? loadingMessageChinese : loadingMessage)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .onAppear {
            // Animate progress over 12 seconds
            withAnimation(.linear(duration: 12.0)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Insight Error View

struct AIErrorView: View {
    let error: String
    let onRetry: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "無法載入屬靈分析" : "Unable to load spiritual insights")
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
            
            Button(action: onRetry) {
                Text(settingsStore.appLanguage == .chineseTraditional ? "重試" : "Retry")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
    }
}

// MARK: - Get Spiritual Insights Button

struct GetAIInsightsButton: View {
    let onTap: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background Image
                SereneBackgroundImage(
                    filename: backgroundManager.journeyBackground,
                    targetSize: CGSize(width: UIScreen.main.bounds.width, height: 350)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0.2)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        // Title
                        Text(settingsStore.appLanguage == .chineseTraditional ? "獲取屬靈洞見" : "Receive Spiritual Insight")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Description
                        Text(settingsStore.appLanguage == .chineseTraditional ? "回顧您的閱讀歷程，獲得個人化的屬靈鼓勵" : "Reflect on your journey and get personalized spiritual encouragement")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Arrow indicator
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 50)
            }
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

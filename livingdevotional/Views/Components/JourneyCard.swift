// JourneyCard.swift
// Component for Journey feature on Home Screen

import SwiftUI

struct JourneyCard: View {
    @StateObject private var viewModel = JourneyViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    @Binding var showJourney: Bool
    
    var body: some View {
        Button {
            showJourney = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header with sparkle icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    Text(settingsStore.appLanguage == .chineseTraditional ? "我的旅程" : "My Journey")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Spacer()
                    
                    // Insight Badge
                    Text("INSIGHT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accentColor, AppTheme.primaryBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.secondaryText)
                        .font(.caption)
                }
                
                // Content based on spiritual analysis or fallback
                if let analysis = viewModel.aiAnalysis {
                    // Show path status as teaser
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.accentColor.opacity(0.2), AppTheme.primaryPurple.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: analysis.pathStatus.iconName)
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(analysis.pathStatus.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text(settingsStore.appLanguage == .chineseTraditional ? "點擊查看您的專屬分析" : "Tap to see your personalized insights")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.sectionBackground.opacity(0.5))
                    .cornerRadius(10)
                    
                } else if viewModel.isLoadingAI {
                    // Loading analysis
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text(settingsStore.appLanguage == .chineseTraditional ? "正在回顧您的信仰歷程..." : "Reflecting on your journey...")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.sectionBackground.opacity(0.5))
                    .cornerRadius(10)
                    
                } else if let insight = viewModel.dailyInsight {
                    // Fallback to basic insight
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: insightIcon(for: insight.type))
                                .font(.caption)
                                .foregroundColor(AppTheme.accentColor)
                            
                            Text(insight.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        Text(insight.content)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.sectionBackground.opacity(0.5))
                    .cornerRadius(10)
                    
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        
                } else {
                    // Empty state with CTA
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                            .foregroundColor(AppTheme.accentColor.opacity(0.6))
                        
                        Text(settingsStore.appLanguage == .chineseTraditional ? "探索您的個人化屬靈分析" : "Discover spiritual insights about your journey")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.sectionBackground.opacity(0.5))
                    .cornerRadius(10)
                }
                
                Spacer(minLength: 8)
                
                // Stats row at the bottom
                if let stats = viewModel.stats, (stats.totalChaptersRead > 0 || stats.totalVersesSaved > 0 || stats.currentStreak > 0) {
                    HStack(spacing: 0) {
                        StatPreview(
                            icon: "book.fill",
                            value: "\(stats.totalChaptersRead)",
                            label: settingsStore.appLanguage == .chineseTraditional ? "章" : "chapters"
                        )
                        
                        Spacer()
                        
                        StatPreview(
                            icon: "bookmark.fill",
                            value: "\(stats.totalVersesSaved)",
                            label: settingsStore.appLanguage == .chineseTraditional ? "保存" : "saved"
                        )
                        
                        if stats.currentStreak > 0 {
                            Spacer()
                            
                            StatPreview(
                                icon: "flame.fill",
                                value: "\(stats.currentStreak)",
                                label: settingsStore.appLanguage == .chineseTraditional ? "連續" : "streak"
                            )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
            }
            .padding(14)
            .background(
                ZStack {
                    // Serene background image
                    Image(backgroundManager.journeyBackground)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                    // Light overlay for text readability
                    Color.white.opacity(0.85)
                    
                    // Subtle decorative gradient
                    LinearGradient(
                        colors: [AppTheme.accentColor.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipped()
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                await viewModel.loadData()
                await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
            }
        }
    }
    
    private func insightIcon(for type: JourneyInsight.InsightType) -> String {
        switch type {
        case .stat: return "chart.bar.fill"
        case .encouragement: return "heart.fill"
        case .pattern: return "lightbulb.fill"
        }
    }
}

// MARK: - Stat Preview

struct StatPreview: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(AppTheme.accentColor.opacity(0.7))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

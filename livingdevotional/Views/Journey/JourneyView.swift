// JourneyView.swift
// Main view for the Journey feature showing AI insights, stats and timeline

import SwiftUI

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showTimeline = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // AI Analysis Section
                        if viewModel.isLoadingAI {
                            AILoadingView()
                        } else if let analysis = viewModel.aiAnalysis {
                            // Hero Encouragement
                            EncouragementHeroView(encouragement: analysis.encouragement)
                            
                            // Reading Personality Card
                            PersonalityCardView(personality: analysis.readingPersonality)
                            
                            // Stats Row
                            if let stats = viewModel.stats {
                                JourneyStatsView(stats: stats)
                            }
                            
                            // Journey Summary
                            if !analysis.journeySummary.isEmpty {
                                JourneySummaryView(summary: analysis.journeySummary)
                            }
                            
                            // Recommended Verse
                            if let verse = analysis.recommendedVerse {
                                RecommendedVerseView(verse: verse)
                            }
                            
                            // Fun Facts
                            if !analysis.funFacts.isEmpty {
                                FunFactsView(facts: analysis.funFacts)
                            }
                            
                            // Next Step CTA
                            if !analysis.nextStep.isEmpty {
                                NextStepView(nextStep: analysis.nextStep)
                            }
                            
                        } else if let error = viewModel.aiErrorMessage {
                            // Error state with retry
                            AIErrorView(error: error) {
                                Task {
                                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                            
                            // Show basic stats as fallback
                            if let stats = viewModel.stats {
                                JourneyStatsView(stats: stats)
                            }
                        } else {
                            // Initial loading state
                            if let stats = viewModel.stats {
                                JourneyStatsView(stats: stats)
                            }
                        }
                        
                        // Timeline Section (Collapsible)
                        TimelineSectionView(
                            milestones: viewModel.milestones,
                            isExpanded: $showTimeline,
                            isLoading: viewModel.isLoading
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "我的旅程" : "My Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshAIAnalysis(appLanguage: settingsStore.appLanguage)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .disabled(viewModel.isLoadingAI)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsStore.appLanguage == .chineseTraditional ? "完成" : "Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadData()
                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                }
            }
        }
    }
}

// MARK: - AI Loading View

struct AILoadingView: View {
    @State private var animationPhase = 0
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let loadingMessages = [
        "Analyzing your journey...",
        "Looking at your reading patterns...",
        "Preparing personalized insights...",
        "Almost there..."
    ]
    
    let loadingMessagesChinese = [
        "分析您的信仰歷程...",
        "觀察您的閱讀模式...",
        "準備個人化的洞見...",
        "即將完成..."
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            Text(settingsStore.appLanguage == .chineseTraditional ? loadingMessagesChinese[animationPhase % loadingMessagesChinese.count] : loadingMessages[animationPhase % loadingMessages.count])
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .animation(.easeInOut, value: animationPhase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                animationPhase += 1
            }
        }
    }
}

// MARK: - Encouragement Hero View

struct EncouragementHeroView: View {
    let encouragement: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.accentColor)
            
            Text(encouragement)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                AppTheme.cardGradient
                
                // Decorative elements
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: -80, y: -60)
                
                Circle()
                    .fill(AppTheme.primaryPurple.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: 100, y: 50)
            }
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Personality Card View

struct PersonalityCardView: View {
    let personality: ReadingPersonality
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentColor, AppTheme.primaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: personality.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(personality.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Text(personality.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Journey Summary View

struct JourneySummaryView: View {
    let summary: String
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "歷程摘要" : "Journey Summary")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.sectionBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Recommended Verse View

struct RecommendedVerseView: View {
    let verse: RecommendedVerse
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text(settingsStore.appLanguage == .chineseTraditional ? "為你推薦" : "Recommended for You")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.secondaryText)
                    .textCase(.uppercase)
                Spacer()
            }
            
            Text("\"\(verse.text)\"")
                .font(.body)
                .italic()
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(4)
            
            HStack {
                Text(verse.reference)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accentColor)
                
                Spacer()
                
                Text(verse.reason)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(16)
        .background(
            ZStack {
                AppTheme.cardGradient
                
                // Quote decoration
                Image(systemName: "quote.opening")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.accentColor.opacity(0.05))
                    .offset(x: -60, y: -20)
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Fun Facts View

struct FunFactsView: View {
    let facts: [FunFact]
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "有趣發現" : "Fun Facts")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
            
            VStack(spacing: 10) {
                ForEach(facts) { fact in
                    HStack(alignment: .top, spacing: 12) {
                        Text(fact.emoji)
                            .font(.title3)
                        
                        Text(fact.fact)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryText)
                            .lineSpacing(2)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Next Step View

struct NextStepView: View {
    let nextStep: String
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsStore.appLanguage == .chineseTraditional ? "下一步" : "Next Step")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.secondaryText)
                    .textCase(.uppercase)
                
                Text(nextStep)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.accentColor.opacity(0.1), AppTheme.primaryPurple.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Timeline Section View

struct TimelineSectionView: View {
    let milestones: [JourneyMilestone]
    @Binding var isExpanded: Bool
    let isLoading: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppTheme.accentColor)
                    Text(settingsStore.appLanguage == .chineseTraditional ? "活動時間軸" : "Activity Timeline")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Spacer()
                    
                    Text("\(milestones.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.sectionBackground)
                        .cornerRadius(8)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            // Content
            if isExpanded {
                if isLoading && milestones.isEmpty {
                    ProgressView()
                        .padding()
                } else if milestones.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                        Text(settingsStore.appLanguage == .chineseTraditional ? "開始您的旅程！" : "Start your journey!")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.vertical, 20)
                } else {
                    JourneyTimelineView(milestones: Array(milestones.prefix(10)))
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - AI Error View

struct AIErrorView: View {
    let error: String
    let onRetry: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text(settingsStore.appLanguage == .chineseTraditional ? "無法載入 AI 分析" : "Unable to load AI analysis")
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

// MARK: - Stats View

struct JourneyStatsView: View {
    let stats: JourneyStats
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "章節" : "Chapters",
                value: "\(stats.totalChaptersRead)",
                icon: "book.fill"
            )
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "保存" : "Saved",
                value: "\(stats.totalVersesSaved)",
                icon: "bookmark.fill"
            )
            StatBox(
                title: settingsStore.appLanguage == .chineseTraditional ? "連續" : "Streak",
                value: "\(stats.currentStreak)",
                icon: "flame.fill"
            )
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

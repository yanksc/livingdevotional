// JourneyView.swift
// Main view for the Journey feature showing spiritual insights, stats and timeline

import SwiftUI

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showDetails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Spiritual Analysis Section
                        if viewModel.isLoadingAI {
                            AILoadingView()
                        } else if let analysis = viewModel.aiAnalysis {
                            // Hero Encouragement
                            EncouragementHeroView(encouragement: analysis.encouragement)
                            
                            // Path Status Card
                            PathStatusCardView(pathStatus: analysis.pathStatus)
                            
                            // Journey Summary
                            if !analysis.journeySummary.isEmpty {
                                JourneySummaryView(summary: analysis.journeySummary)
                            }
                            
                            // Recommended Verse
                            if let verse = analysis.recommendedVerse {
                                RecommendedVerseView(verse: verse)
                            }
                            
                            // Path Highlights
                            if !analysis.pathHighlights.isEmpty {
                                PathHighlightsView(highlights: analysis.pathHighlights)
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
                        } else {
                            // No cache - show button to get spiritual insights
                            GetAIInsightsButton {
                                Task {
                                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        }
                        
                        // Stats Row - Below the summary section, expandable
                        if let stats = viewModel.stats {
                            JourneyStatsView(stats: stats, showDetails: $showDetails)
                        }
                        
                        // Detailed sections - Only shown when expanded
                        if showDetails {
                            // Recent History Section - Horizontal Scrollable Widgets
                            RecentHistoryWidgetView(
                                historyItems: progressStore.getRecentHistory(limit: 5),
                                settingsStore: settingsStore,
                                router: router
                            )
                            
                            // My Notes Section - Horizontal Scrollable Widgets
                            MyNotesWidgetView(
                                savedVerses: Array(noteStore.savedVerses.prefix(5)),
                                settingsStore: settingsStore,
                                router: router
                            )
                            
                            // Timeline Section - Small Timeline Widget
                            TimelineWidgetView(
                                milestones: viewModel.milestones,
                                isLoading: viewModel.isLoading
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "了解你的屬靈之路" : "Discover Your Spiritual Path")
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
            }
            .onAppear {
                Task {
                    await viewModel.loadData()
                    // Only auto-load spiritual analysis if cached
                    if viewModel.hasCachedAnalysis {
                        await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                    }
                }
            }
        }
    }
}

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

// MARK: - Encouragement Hero View (Short 1-sentence encouragement with light serene background)

struct EncouragementHeroView: View {
    let encouragement: String
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    // Use a consistent background based on encouragement text hash
    private var backgroundFilename: String {
        let hash = abs(encouragement.hashValue)
        let index = hash % backgroundManager.count
        return backgroundManager.background(at: index)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(encouragement)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Serene background image - lighter overlay for short text
                SereneBackgroundImage(
                    filename: backgroundFilename,
                    targetSize: CGSize(width: UIScreen.main.bounds.width, height: 120)
                )
                .aspectRatio(contentMode: .fill)
                
                // Very light gradient overlay - just enough for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipped()
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Path Status Card View (Redesigned with dark serene background, centered text, no icon)

struct PathStatusCardView: View {
    let pathStatus: PathStatus
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    // Randomly select a dark serene background (1-5) - persisted across renders
    @State private var backgroundImageName: String = {
        let randomIndex = Int.random(in: 1...5)
        return "dark_serene_\(randomIndex)"
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Centered title - creative status based on user's journey
            Text(pathStatus.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
            
            // Expanded description - ~60 words of in-context analysis
            Text(pathStatus.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Dark serene background image
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                
                // Subtle overlay for text readability
                Color.black.opacity(0.35)
            }
        )
        .clipped()
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
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
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    // Use a consistent background based on verse reference hash
    private var backgroundFilename: String {
        let hash = abs(verse.reference.hashValue)
        let index = hash % backgroundManager.count
        return backgroundManager.background(at: index)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(settingsStore.appLanguage == .chineseTraditional ? "為你推薦" : "Recommended for You")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .textCase(.uppercase)
                Spacer()
            }
            
            Text("\"\(verse.text)\"")
                .font(.body)
                .italic()
                .foregroundColor(.white)
                .lineSpacing(4)
            
            HStack {
                Text(verse.reference)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text(verse.reason)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Serene background image
                SereneBackgroundImage(
                    filename: backgroundFilename,
                    targetSize: CGSize(width: UIScreen.main.bounds.width, height: 180)
                )
                .aspectRatio(contentMode: .fill)
                
                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.65),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipped()
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Path Highlights View (Collapsible)

struct PathHighlightsView: View {
    let highlights: [PathHighlight]
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - tappable to expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "路徑亮點" : "Path Highlights")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.cardGradient)
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(highlights) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Text(highlight.emoji)
                                .font(.title3)
                            
                            Text(highlight.fact)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(2)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.sectionBackground.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
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

// MARK: - Timeline Widget View

struct TimelineWidgetView: View {
    let milestones: [JourneyMilestone]
    let isLoading: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "活動時間軸" : "Activity Timeline")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if !milestones.isEmpty {
                    Text("\(milestones.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.sectionBackground)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            // Small Timeline Preview
            if isLoading && milestones.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Show compact timeline preview (first 3-4 items)
                VStack(spacing: 8) {
                    ForEach(Array(milestones.prefix(4))) { milestone in
                        TimelineItemRow(milestone: milestone)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Timeline Item Row

struct TimelineItemRow: View {
    let milestone: JourneyMilestone
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: milestone.iconName)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text(formatDate(milestone.date))
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let isChinese = settingsStore.appLanguage == .chineseTraditional
        
        if calendar.isDateInToday(date) {
            return isChinese ? "今天" : "Today"
        } else if calendar.isDateInYesterday(date) {
            return isChinese ? "昨天" : "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.string(from: date)
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

// MARK: - Stats View

struct JourneyStatsView: View {
    let stats: JourneyStats
    @Binding var showDetails: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showDetails.toggle()
            }
        }) {
            VStack(spacing: 12) {
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
                
                // Chevron indicator
                HStack {
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .animation(.easeInOut(duration: 0.2), value: showDetails)
                    Spacer()
                }
            }
            .padding(16)
            .background(AppTheme.cardGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Recent History Widget View

struct RecentHistoryWidgetView: View {
    let historyItems: [ReadingHistoryItem]
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "最近閱讀" : "Recent History")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Horizontal Scrollable Cards
            if historyItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "開始閱讀聖經！" : "Start reading!")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(historyItems) { item in
                            RecentHistoryCard(
                                item: item,
                                settingsStore: settingsStore,
                                router: router
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Recent History Card

struct RecentHistoryCard: View {
    let item: ReadingHistoryItem
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToChapter()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Book and chapter info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedBookChapter)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                    
                    Text(formatTime(item.timestamp))
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 140)
            .background(AppTheme.sectionBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var localizedBookChapter: String {
        let localizedBook = BibleData.localizedBookName(item.book, language: settingsStore.primaryLanguage)
        let chapterPrefix = BibleData.localizedChapterText(language: settingsStore.primaryLanguage)
        if chapterPrefix == "第" {
            return "\(localizedBook) \(chapterPrefix)\(item.chapter)章"
        } else {
            return "\(localizedBook) \(chapterPrefix) \(item.chapter)"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let isChinese = settingsStore.appLanguage == .chineseTraditional
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return isChinese ? "今天 \(formatter.string(from: date))" : "Today \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return isChinese ? "昨天" : "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.locale = settingsStore.appLanguage.resolvedLocale()
            return formatter.string(from: date)
        }
    }
    
    private func navigateToChapter() {
        if let book = BibleData.book(named: item.book) {
            router.navigateToReading(book: book, chapter: item.chapter, verse: nil)
        }
    }
}

// MARK: - My Notes Widget View

struct MyNotesWidgetView: View {
    let savedVerses: [SavedVerse]
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(AppTheme.accentColor)
                Text(settingsStore.appLanguage == .chineseTraditional ? "我的筆記" : "My Notes")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Horizontal Scrollable Cards
            if savedVerses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.title2)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                    Text(settingsStore.appLanguage == .chineseTraditional ? "保存經文以在此查看！" : "Save verses to see them here!")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedVerses, id: \.id) { verse in
                            NoteCard(
                                savedVerse: verse,
                                settingsStore: settingsStore,
                                router: router
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let savedVerse: SavedVerse
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var router: AppRouter
    
    var body: some View {
        Button(action: {
            navigateToVerse()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Verse info
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedVerseReference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(2)
                    
                    if !savedVerse.content.isEmpty {
                        Text(savedVerse.content)
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                    } else {
                        Text(formatDate(savedVerse.timestamp))
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    // Labels indicator
                    if !savedVerse.labels.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 8))
                                .foregroundColor(AppTheme.accentColor)
                            Text("\(savedVerse.labels.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentColor.opacity(0.15))
                        .cornerRadius(4)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 140)
            .background(AppTheme.sectionBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var localizedVerseReference: String {
        let localizedBook = BibleData.localizedBookName(savedVerse.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = settingsStore.appLanguage.resolvedLocale()
        return formatter.string(from: date)
    }
    
    private func navigateToVerse() {
        if let book = BibleData.book(named: savedVerse.book) {
            router.navigateToReading(book: book, chapter: savedVerse.chapter, verse: savedVerse.verse)
        }
    }
}

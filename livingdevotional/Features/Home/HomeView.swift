// HomeView - Main home screen

import SwiftUI

struct HomeView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var bibleViewModel: BibleViewModel
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var checkInStore = CheckInStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var readingPlanStore = ReadingPlanStore.shared
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section with task progress
                    welcomeSection
                    
                    // Daily Check-in Calendar
                    CheckInCard(checkInStore: checkInStore)
                    
                    // Verse of the day
                    verseOfTheDaySection
                    
                    // Daily Tasks Card
                    DailyTasksCard(checkInStore: checkInStore)
                    
                    // Today's Progress Counters (hidden when all tasks completed)
                    if !allTasksCompleted {
                        todayProgressSection
                    }
                }
                .padding()
                .padding(.bottom, 100) // Extra padding for tab bar
            }
        }
        .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "今日" : "Today")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            viewModel.loadHomeData()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns true when all 3 daily tasks are completed (Open App is always done)
    private var allTasksCompleted: Bool {
        checkInStore.hasReadToday && checkInStore.hasPrayedToday
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Living Path")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.accentColor)
            Text(settingsStore.appLanguage.localizedString("WelcomeSubtitle"))
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            
            // Task completion progress indicator (starts at 1 since "Open App" is always completed)
            let tasksCompleted = 1 + (checkInStore.hasReadToday ? 1 : 0) + (checkInStore.hasPrayedToday ? 1 : 0)
            HStack(spacing: 8) {
                Text(settingsStore.appLanguage == .chineseTraditional ? "今日進度" : "Today")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                Text("\(tasksCompleted)/3")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var todayProgressSection: some View {
        let chaptersRead = progressStore.getTodayReadingCount()
        let planDaysCompleted = readingPlanStore.getTodayPlanDaysCompleted()
        let totalProgress = chaptersRead + planDaysCompleted
        
        return VStack(spacing: 16) {
            // Section Header
            HStack {
                Text(settingsStore.appLanguage.localizedString("TodayProgress"))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
            }
            
            // Progress Counters
            HStack(spacing: 16) {
                // Chapters Read Counter
                progressCounter(
                    value: chaptersRead,
                    label: settingsStore.appLanguage.localizedString("ChaptersRead"),
                    icon: "book.fill",
                    color: AppTheme.accentColor
                )
                
                // Plan Days Completed Counter
                progressCounter(
                    value: planDaysCompleted,
                    label: settingsStore.appLanguage.localizedString("PlanDays"),
                    icon: "calendar.badge.checkmark",
                    color: Color.green
                )
            }
            
            // Encouragement Message
            if totalProgress > 0 {
                HStack {
                    Image(systemName: encouragementIcon(for: totalProgress))
                        .foregroundColor(encouragementColor(for: totalProgress))
                    Text(encouragementMessage(for: totalProgress))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(encouragementColor(for: totalProgress).opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func progressCounter(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryText)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
    
    private func encouragementMessage(for progress: Int) -> String {
        switch progress {
        case 1...2:
            return settingsStore.appLanguage.localizedString("GreatStart")
        case 3...4:
            return settingsStore.appLanguage.localizedString("AmazingProgress")
        case 5...:
            return settingsStore.appLanguage.localizedString("OnFire")
        default:
            return settingsStore.appLanguage.localizedString("StartReading")
        }
    }
    
    private func encouragementIcon(for progress: Int) -> String {
        switch progress {
        case 1...2:
            return "leaf.fill"
        case 3...4:
            return "sun.max.fill"
        case 5...:
            return "heart.fill"
        default:
            return "book.fill"
        }
    }
    
    private func encouragementColor(for progress: Int) -> Color {
        switch progress {
        case 1...2:
            return .green
        case 3...4:
            return .teal
        case 5...:
            return AppTheme.accentColor
        default:
            return AppTheme.accentColor
        }
    }
    
    private var verseOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(settingsStore.appLanguage.localizedString("VerseOfTheDay"))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if let verse = viewModel.verseOfTheDay {
                    ShareLink(item: formatVerseForShare(verse)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            
            if let verse = viewModel.verseOfTheDay {
                NavigationLink(destination: VerseDetailView(verse: verse)) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        if let reason = verse.reason {
                            Text(reason.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.accentColor)
                        }
                        
                        // Verse text
                        VStack(alignment: .leading, spacing: 12) {
                            Text(verse.text(for: settingsStore.primaryLanguage))
                                .font(.system(size: 18, weight: .medium, design: .serif))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                            
                            if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                                Text(verse.text(for: settingsStore.secondaryLanguage))
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        Divider()
                            .overlay(AppTheme.accentColor.opacity(0.2))
                        
                        // Reference and CTA
                        HStack {
                            Text(localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accentColor)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(settingsStore.appLanguage == .chineseTraditional ? "查看詳情" : "View Details")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(
                        ZStack {
                            AppTheme.cardGradient
                            
                            // Subtle background decoration
                            GeometryReader { proxy in
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 80))
                                    .foregroundColor(AppTheme.accentColor.opacity(0.05))
                                    .position(x: 40, y: 40)
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(16)
            } else {
                Text(settingsStore.appLanguage.localizedString("UnableToLoadVerse"))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func localizedReference(book: String, chapter: Int, verse: Int) -> String {
        // Use primaryLanguage for book/chapter references
        let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(chapter):\(verse)"
    }
    
    private func formatVerseForShare(_ verse: DailyVerse) -> String {
        let text = verse.text(for: settingsStore.primaryLanguage)
        let reference = localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
        return "\"\(text)\"\n- \(reference)\n\nShared from Living Path"
    }
    
}


#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppRouter())
            .environmentObject(BibleViewModel())
    }
}

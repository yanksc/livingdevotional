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
    
    @State private var showVerseFullScreen = false
    
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
        GeometryReader { geometry in
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
                    Button(action: {
                        showVerseFullScreen = true
                    }) {
                        ZStack(alignment: .topLeading) {
                            // Serene background image
                            Image("VerseOfTheDayBackground")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: geometry.size.height * 0.85)
                                .clipped()
                            
                            // Overlay gradient for readability
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.15),
                                    Color.black.opacity(0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Content
                            VStack(alignment: .leading, spacing: 16) {
                                // Reason badge
                                if let reason = verse.reason {
                                    HStack(spacing: 6) {
                                        Image(systemName: reasonIcon(for: verse.source))
                                            .font(.caption)
                                        Text(reason.uppercased())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                // Verse preview (truncated)
                                Text(verse.text(for: settingsStore.primaryLanguage))
                                    .font(.system(size: 20, weight: .medium, design: .serif))
                                    .foregroundColor(.white)
                                    .lineSpacing(6)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.leading)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                
                                // Reference and tap hint
                                HStack {
                                    Text(localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Text(settingsStore.appLanguage == .chineseTraditional ? "點擊閱讀" : "Tap to Read")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.25))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(20)
                        }
                        .frame(height: geometry.size.height * 0.85)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .fullScreenCover(isPresented: $showVerseFullScreen) {
                        VerseFullScreenView(verse: verse, settingsStore: settingsStore)
                    }
                    
                } else if viewModel.isLoading {
                    ZStack {
                        Image("VerseOfTheDayBackground")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: geometry.size.height * 0.85)
                            .clipped()
                            .blur(radius: 3)
                        
                        Color.black.opacity(0.3)
                        
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                    .frame(height: geometry.size.height * 0.85)
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
        .frame(height: UIScreen.main.bounds.height * 0.45)
    }
    
    // Helper to get icon based on source
    private func reasonIcon(for source: String?) -> String {
        guard let source = source?.lowercased() else { return "sparkles" }
        if source.contains("prayer") { return "hands.sparkles.fill" }
        if source.contains("conversation") || source.contains("question") { return "bubble.left.and.bubble.right.fill" }
        if source.contains("notes") || source.contains("saved") { return "bookmark.fill" }
        if source.contains("reading") || source.contains("plan") { return "book.fill" }
        return "sparkles"
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


// MARK: - Scale Button Style for interactive press feedback

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Full Screen Verse View with Slow Animation

struct VerseFullScreenView: View {
    let verse: DailyVerse
    let settingsStore: SettingsStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    
    @State private var showReason = false
    @State private var showVerse = false
    @State private var showSecondary = false
    @State private var showReference = false
    @State private var showButtons = false
    @State private var showChat = false
    
    var body: some View {
        ZStack {
            // Full screen background
            Image("VerseOfTheDayBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                
                Spacer()
                
                // Centered verse content
                VStack(spacing: 32) {
                    // Reason
                    if let reason = verse.reason {
                        HStack(spacing: 8) {
                            Image(systemName: reasonIcon(for: verse.source))
                                .font(.subheadline)
                            Text(reason)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                        .opacity(showReason ? 1 : 0)
                        .offset(y: showReason ? 0 : 20)
                    }
                    
                    // Main verse text
                    Text(verse.text(for: settingsStore.primaryLanguage))
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        .opacity(showVerse ? 1 : 0)
                        .offset(y: showVerse ? 0 : 30)
                    
                    // Secondary language
                    if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                        Text(verse.text(for: settingsStore.secondaryLanguage))
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .padding(.horizontal, 24)
                            .opacity(showSecondary ? 1 : 0)
                            .offset(y: showSecondary ? 0 : 20)
                    }
                    
                    // Reference
                    Text(verse.reference)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .opacity(showReference ? 1 : 0)
                        .scaleEffect(showReference ? 1 : 0.8)
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: { showChat = true }) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text(settingsStore.appLanguage == .chineseTraditional ? "深入探索" : "Ask Deeper")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(AppTheme.accentColor)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: { navigateToChapter() }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text(settingsStore.appLanguage == .chineseTraditional ? "閱讀章節" : "Read Chapter")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showChat) {
            ChatViewWrapper(verse: verse, services: services)
        }
    }
    
    private func startAnimations() {
        // Staggered animations for a slow reveal
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            showReason = true
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.8)) {
            showVerse = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.6)) {
            showSecondary = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(2.2)) {
            showReference = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(2.8)) {
            showButtons = true
        }
    }
    
    private func navigateToChapter() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let book = BibleData.book(named: verse.book) {
                router.navigateToReading(book: book, chapter: verse.chapter, verse: verse.verseNumber)
            }
        }
    }
    
    private func reasonIcon(for source: String?) -> String {
        guard let source = source?.lowercased() else { return "sparkles" }
        if source.contains("prayer") { return "hands.sparkles.fill" }
        if source.contains("conversation") || source.contains("question") { return "bubble.left.and.bubble.right.fill" }
        if source.contains("notes") || source.contains("saved") { return "bookmark.fill" }
        if source.contains("reading") || source.contains("plan") { return "book.fill" }
        return "sparkles"
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppRouter())
            .environmentObject(BibleViewModel())
    }
}

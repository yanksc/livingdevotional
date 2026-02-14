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
    @State private var showRecordsSheet = false
    
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
                    
                    // Continue Reading Plan (if active)
                    if let activePlan = getActivePlan() {
                        continuePlanCard(plan: activePlan.plan, progress: activePlan.progress)
                    }
                    
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    // Records button
                    Button(action: { showRecordsSheet = true }) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    // Profile avatar
                    ProfileAvatarButton { router.showSettings = true }
                }
            }
        }
        .sheet(isPresented: $showRecordsSheet) {
            MyRecordsSheet()
                .environmentObject(router)
        }
        .onAppear {
            viewModel.loadHomeData()
        }
        .onChange(of: router.showVerseOfTheDayFullScreen) { _, newValue in
            // Handle deep link from widget to show verse full screen
            if newValue && viewModel.verseOfTheDay != nil {
                showVerseFullScreen = true
                router.showVerseOfTheDayFullScreen = false
            }
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
                        ZStack(alignment: .bottomTrailing) {
                            // Background image - use static default fallback to ensure consistency with immersive view
                            SereneBackgroundImage(
                                filename: verse.backgroundImage ?? "photo-1506744038136-46273834b3fb.avif",
                                targetSize: CGSize(width: geometry.size.width, height: geometry.size.height * 0.85)
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
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
                            
                            // Center Content - verse and reference only
                            VStack(spacing: 12) {
                                // Verse preview (centered)
                                Text(verse.text(for: settingsStore.primaryLanguage))
                                    .font(.system(size: 20, weight: .medium, design: .serif))
                                    .foregroundColor(.white)
                                    .lineSpacing(6)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal, 20)
                                
                                // Reference
                                Text(localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(20)
                            
                            // Tap to Read - bottom right corner, smaller
                            HStack(spacing: 4) {
                                Text(settingsStore.appLanguage == .chineseTraditional ? "點擊閱讀" : "Tap to Read")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 8))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .padding(12)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                        .clipped()
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .fullScreenCover(isPresented: $showVerseFullScreen) {
                        VerseFullScreenView(verse: verse, settingsStore: settingsStore)
                    }
                    
                } else if viewModel.isLoading {
                    ZStack {
                        SereneBackgroundImage(
                            filename: "photo-1506744038136-46273834b3fb.avif",
                            targetSize: CGSize(width: geometry.size.width, height: geometry.size.height * 0.85)
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                        .clipped()
                        .blur(radius: 3)
                        
                        Color.black.opacity(0.3)
                        
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                    .clipped()
                    .cornerRadius(16)
                } else {
                    VStack(spacing: 12) {
                        Text(settingsStore.appLanguage.localizedString("UnableToLoadVerse"))
                            .foregroundColor(AppTheme.secondaryText)
                        
                        Button(action: {
                            viewModel.retryLoadVerse()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "重試" : "Retry")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.accentColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
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
        VerseShareFormatter.format(verse, language: settingsStore.primaryLanguage, bookNameLanguage: settingsStore.primaryLanguage)
    }
    
    // MARK: - Continue Reading Plan
    
    private func getActivePlan() -> (plan: ReadingPlan, progress: ReadingPlanProgress)? {
        let activePlans = readingPlanStore.getActivePlans()
        // Get the most recently started plan
        return activePlans.sorted(by: { ($0.progress.startedAt ?? Date.distantPast) > ($1.progress.startedAt ?? Date.distantPast) }).first
    }
    
    private func continuePlanCard(plan: ReadingPlan, progress: ReadingPlanProgress) -> some View {
        Button(action: {
            if let todayReading = readingPlanStore.getTodayReading(for: plan.id),
               let book = BibleData.book(named: todayReading.book) {
                router.navigateToReading(
                    book: book,
                    chapter: todayReading.chapter,
                    verse: todayReading.verseStart
                )
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: plan.icon)
                        .font(.title2)
                        .foregroundColor(AppTheme.accentColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "繼續閱讀計劃" : 
                         settingsStore.appLanguage == .chineseSimplified ? "继续阅读计划" : 
                         "Continue Reading Plan")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(plan.title)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                    
                    // Progress
                    HStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.secondaryText.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.accentColor)
                                    .frame(
                                        width: max(0, geometry.size.width * CGFloat(readingPlanStore.getProgressPercentage(for: plan.id) / 100)),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(progress.completedDays.count)/\(plan.duration)")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding()
            .background(AppTheme.cardGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    @State private var showVerse = false
    @State private var showReference = false
    @State private var showButtons = false
    @State private var showChat = false
    @State private var showRationale = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Background image
                SereneBackgroundImage(
                    filename: verse.backgroundImage ?? "photo-1506744038136-46273834b3fb.avif",
                    targetSize: geometry.size
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                
                // Layer 1b: Gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Layer 2: Centered Content (verse, reference, rationale)
                VStack(spacing: 24) {
                    // Main verse text (centered)
                    Text(verse.text(for: settingsStore.primaryLanguage))
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: geometry.size.width - 48)
                        .opacity(showVerse ? 1 : 0)
                        .offset(y: showVerse ? 0 : 30)
                    
                    // Reference - localized to primary language
                    Text(localizedReference(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                        .opacity(showReference ? 1 : 0)
                        .scaleEffect(showReference ? 1 : 0.8)
                    
                    // "Why we recommend" - uses ZStack so expansion doesn't shift verse
                    if verse.source != nil || verse.rationale != nil {
                        ZStack(alignment: .top) {
                            // Button (always visible, defines the layout position)
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showRationale.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text(settingsStore.appLanguage.localizedString("WhyWeRecommend"))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Image(systemName: showRationale ? "chevron.up" : "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            // Expanded content as overlay, offset below button
                            if showRationale {
                                VStack(alignment: .center, spacing: 6) {
                                    if let source = verse.source {
                                        Text(source)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.9))
                                            .multilineTextAlignment(.center)
                                    }
                                    if let rationale = verse.rationale {
                                        Text(rationale)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.85))
                                            .multilineTextAlignment(.center)
                                            .lineSpacing(4)
                                    }
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(12)
                                .frame(maxWidth: geometry.size.width - 64)
                                .offset(y: 44) // Position below the button
                                .transition(.opacity)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                
                // Layer 3: Controls (pinned to top and bottom)
                VStack {
                    // Top: Close Button - ensure it's below status bar/notch
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.9))
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    // Use max of safe area + padding OR a minimum of 60pt for notched devices
                    .padding(.top, max(geometry.safeAreaInsets.top + 16, 60))
                    .padding(.trailing, 20)
                    
                    Spacer()
                    
                    // Bottom: Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            if !UsageLimitStore.shared.canUseAIQuestion() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                                return
                            }
                            showChat = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.caption)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "深入探索" : "Ask Deeper")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.25))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { navigateToChapter() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.caption)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "閱讀章節" : "Read Chapter")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.25))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom + 16, 40))
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 30)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showChat) {
            ChatViewWrapper(verse: verse, services: services)
        }
    }
    
    private func startAnimations() {
        // Staggered animations for a slow reveal
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            showVerse = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            showReference = true
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.8)) {
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
    
    private func localizedReference(book: String, chapter: Int, verse: Int) -> String {
        let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(chapter):\(verse)"
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppRouter())
            .environmentObject(BibleViewModel())
    }
}

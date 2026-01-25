import SwiftUI

struct ExploreView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var planStore = ReadingPlanStore.shared
    @ObservedObject private var askCategoryStore = AskCategoryStore.shared
    
    // State for sheets
    @State private var showPrayerFlow = false
    @State private var showVerseSearch = false
    @State private var selectedPlan: ReadingPlan?
    @State private var selectedCategory: AskCategory?
    
    // State for scroll tracking
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Track scroll offset
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        // Large title that shrinks when scrolling
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Explore")
                                .font(.system(size: scaledTitleSize, weight: .semibold, design: .serif))
                                .foregroundColor(AppTheme.accentColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .opacity(largeTitleOpacity)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 0)
                        .padding(.bottom, 16)
                        .background(AppTheme.backgroundGradient)
                        
                        // Content sections
                        VStack(spacing: 24) {
                            // Common Questions Section (at top)
                            commonQuestionsSection
                            
                            // Reading Plans Section
                            readingPlansSection
                            
                            // Quick Actions Section (moved to bottom)
                            quickActionsSection
                        }
                        .padding()
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeOut(duration: 0.25)) {
                        scrollOffset = value
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Small title that appears when scrolled
                    Text("Explore")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(AppTheme.accentColor)
                        .opacity(smallTitleOpacity)
                }
            }
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // Sheet modifiers
            .fullScreenCover(isPresented: $showPrayerFlow) {
                PrayerFlowView()
            }
            .sheet(isPresented: $showVerseSearch) {
                VerseSearchView(settingsStore: settingsStore)
                    .environmentObject(router)
            }
            .fullScreenCover(item: $selectedPlan) { plan in
                ReadingPlanDetailSheet(plan: plan)
                    .environmentObject(router)
            }
            .navigationDestination(item: $selectedCategory) { category in
                AskCategoryDetailView(category: category)
                    .environmentObject(router)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage.localizedString("QuickActions"))
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickActionButtonWithImage(
                        title: settingsStore.appLanguage.localizedString("Pray"),
                        icon: "hands.sparkles.fill",
                        backgroundImage: "PrayButtonBackground",
                        fallbackColor: AppTheme.accentColor
                    ) {
                        showPrayerFlow = true
                    }
                    
                    quickActionButtonWithImage(
                        title: settingsStore.appLanguage.localizedString("FindVerse"),
                        icon: "magnifyingglass",
                        backgroundImage: "SearchButtonBackground",
                        fallbackColor: AppTheme.primaryPurple
                    ) {
                        showVerseSearch = true
                    }
                }
            }
        }
    }
    
    // Computed property for scaled font size based on scroll offset
    private var scaledTitleSize: CGFloat {
        let minSize: CGFloat = 20
        let maxSize: CGFloat = 34
        let threshold: CGFloat = 80
        // Smooth easing function for better animation
        let rawProgress = max(0, min(1, (threshold + scrollOffset) / threshold))
        // Apply ease-out curve for smoother animation
        let easedProgress = 1 - pow(1 - rawProgress, 3)
        return minSize + (maxSize - minSize) * easedProgress
    }
    
    // Opacity for large title (fades out as you scroll)
    private var largeTitleOpacity: Double {
        let threshold: CGFloat = 80
        let fadeStart: CGFloat = -40
        if scrollOffset > fadeStart {
            return 1.0
        } else if scrollOffset < -threshold {
            return 0.0
        } else {
            let progress = (scrollOffset - fadeStart) / (fadeStart - threshold)
            return Double(max(0, min(1, 1 + progress)))
        }
    }
    
    // Opacity for small title in navigation bar (fades in as you scroll)
    private var smallTitleOpacity: Double {
        let threshold: CGFloat = 80
        let fadeStart: CGFloat = -40
        if scrollOffset > fadeStart {
            return 0.0
        } else if scrollOffset < -threshold {
            return 1.0
        } else {
            let progress = (scrollOffset - fadeStart) / (fadeStart - threshold)
            return Double(max(0, min(1, -progress)))
        }
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(height: 28)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private func quickActionButtonWithImage(title: String, icon: String, backgroundImage: String, fallbackColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(height: 28)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Serene image background
                    Image(backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                    // Subtle dark overlay for text readability
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .cornerRadius(16)
            .clipped()
            .shadow(color: fallbackColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private var commonQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "常見問題" : 
                 settingsStore.appLanguage == .chineseSimplified ? "常见问题" : 
                 "Common Questions")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(askCategoryStore.categories) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            AskCategoryCard(category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var readingPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage.localizedString("ReadingPlans"))
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(planStore.plans) { plan in
                        Button(action: {
                            selectedPlan = plan
                        }) {
                            ReadingPlanCard(
                                plan: plan,
                                progress: planStore.getProgress(for: plan.id)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(AppRouter())
}

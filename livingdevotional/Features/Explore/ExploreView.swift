import SwiftUI

struct ExploreView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var planStore = ReadingPlanStore.shared
    @ObservedObject private var askCategoryStore = AskCategoryStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    // State for sheets
    @State private var showPrayerFlow = false
    @State private var showVerseSearch = false
    @State private var showAskAnyQuestion = false
    @State private var selectedPlan: ReadingPlan?
    @State private var selectedCategory: AskCategory?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Common Questions Section (at top)
                        commonQuestionsSection
                        
                        // Reading Plans Section
                        readingPlansSection
                        
                        // Quick Actions Section (moved to bottom)
                        quickActionsSection
                    }
                    .padding()
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .onAppear {
                // Preload images for all visible cards to eliminate loading delay
                backgroundManager.preloadExploreViewImages(
                    categoryCount: askCategoryStore.categories.count,
                    planIds: planStore.plans.map { $0.id }
                )
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "探索" : 
                           settingsStore.appLanguage == .chineseSimplified ? "探索" : "Explore")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showAskAnyQuestion) {
                if let aiService = services.aiService {
                    ChatView(
                        viewModel: ChatViewModel(
                            aiService: aiService,
                            book: nil,
                            chapter: nil,
                            verse: nil,
                            verseText: nil,
                            appLanguage: settingsStore.appLanguage,
                            initialQuestion: nil
                        ),
                        settingsStore: settingsStore,
                        onClose: {
                            showAskAnyQuestion = false
                        }
                    )
                    .environmentObject(router)
                    .presentationDetents([.fraction(0.8), .large])
                    .presentationDragIndicator(.visible)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.secondaryText)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "服務暫時無法使用" : 
                             settingsStore.appLanguage == .chineseSimplified ? "服务暂时无法使用" :
                             "Service is currently unavailable")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.backgroundGradient.ignoresSafeArea())
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsStore.appLanguage.localizedString("QuickActions"))
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    quickActionCard(
                        title: settingsStore.appLanguage.localizedString("Pray"),
                        icon: "hands.sparkles.fill",
                        backgroundImage: "PrayButtonBackground",
                        fallbackColor: AppTheme.accentColor
                    ) {
                        showPrayerFlow = true
                    }
                    
                    quickActionCard(
                        title: settingsStore.appLanguage.localizedString("FindVerse"),
                        icon: "magnifyingglass",
                        backgroundImage: "SearchButtonBackground",
                        fallbackColor: AppTheme.primaryPurple
                    ) {
                        showVerseSearch = true
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func quickActionCard(title: String, icon: String, backgroundImage: String, fallbackColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                // Background image
                Image(backgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 180)
                    .clipped()
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Centered title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(width: 160, height: 180)
            .contentShape(Rectangle())
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
                    // "Ask Any Question" tile as the first item
                    Button(action: {
                        showAskAnyQuestion = true
                    }) {
                        AskAnyQuestionCard(backgroundImage: backgroundManager.background(at: 0))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Category tiles with random non-repeating backgrounds
                    ForEach(Array(askCategoryStore.categories.enumerated()), id: \.element.id) { index, category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            AskCategoryCard(
                                category: category,
                                backgroundImage: backgroundManager.background(at: index + 1) // +1 because index 0 is used by "Ask Any Question"
                            )
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
                    // Create Personalized Plan tile
                    createPersonalizedPlanTile
                    
                    // Sorted plans: Recently active/created first
                    let sortedPlans = planStore.plans.sorted { plan1, plan2 in
                        let p1 = planStore.getProgress(for: plan1.id)
                        let p2 = planStore.getProgress(for: plan2.id)
                        let date1 = p1?.lastReadAt ?? p1?.startedAt ?? Date.distantPast
                        let date2 = p2?.lastReadAt ?? p2?.startedAt ?? Date.distantPast
                        return date1 > date2
                    }
                    
                    ForEach(sortedPlans) { plan in
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
    
    @State private var showPersonalizedPlanCreation = false
    
    private var createPersonalizedPlanTile: some View {
        Button(action: {
            showPersonalizedPlanCreation = true
        }) {
            ZStack(alignment: .center) {
                // Background image from bg_serene folder - use index after all category cards
                SereneBackgroundImage(filename: backgroundManager.background(at: askCategoryStore.categories.count + 1))
                    .frame(width: 160, height: 180)
                    .clipped()
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content centered
                VStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // Title
                    Text(settingsStore.appLanguage == .chineseTraditional ? "創建你的讀經計劃" : 
                         settingsStore.appLanguage == .chineseSimplified ? "创建你的读经计划" : 
                         "Create Your Reading Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(16)
            }
            .frame(width: 160, height: 180)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showPersonalizedPlanCreation) {
            PersonalizedPlanConfigView()
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(AppRouter())
}

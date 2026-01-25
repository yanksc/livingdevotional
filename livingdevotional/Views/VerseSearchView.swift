// VerseSearchView - Search view for finding verses

import SwiftUI

struct VerseSearchView: View {
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.services) var services
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    
    @State private var searchText = ""
    @State private var searchResponse: VerseSearchResponse?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchProgress: Double = 0
    @State private var progressTimer: Timer?
    @State private var allResults: [RelatedVerse] = []
    @State private var lastSearchQuery = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.secondaryText)
                            TextField(
                                settingsStore.appLanguage == .chineseTraditional ? "搜尋經文..." : "Search verses...",
                                text: $searchText
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                        }
                        .padding(12)
                        .background(AppTheme.cardGradient)
                        .cornerRadius(12)
                        
                        Button(action: {
                            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                performSearch()
                            }
                        }) {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "搜尋" : "Search")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [AppTheme.accentColor, AppTheme.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                    
                    // Content
                    if isLoading {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            // Animated search icon
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.accentColor)
                                .symbolEffect(.pulse)
                            
                            Text(settingsStore.appLanguage == .chineseTraditional ? "搜尋中..." : "Searching...")
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            // Progress bar
                            VStack(spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background track
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(AppTheme.secondaryText.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        // Progress fill
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.accentColor, AppTheme.accentColor.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * searchProgress, height: 8)
                                            .animation(.easeInOut(duration: 0.1), value: searchProgress)
                                    }
                                }
                                .frame(height: 8)
                                
                                Text(settingsStore.appLanguage == .chineseTraditional ? "正在為您尋找相關經文" : "Finding relevant verses for you")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "搜尋失敗" : "Search failed")
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(settingsStore.appLanguage.localizedString("Retry")) {
                                performSearch()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accentColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchResponse == nil {
                        // Empty state with template buttons
                        ScrollView {
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(settingsStore.appLanguage == .chineseTraditional ? "搜尋經文" : "Search Verses")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(settingsStore.appLanguage == .chineseTraditional ? "輸入關鍵字或經文參考" : "Enter keywords or verse reference")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40)
                                
                                // Template buttons
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(settingsStore.appLanguage == .chineseTraditional ? "試試搜尋" : "Try searching for")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(templateQueries, id: \.self) { query in
                                            Button(action: {
                                                searchText = query
                                                performSearch()
                                            }) {
                                                Text(query)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.primaryText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(AppTheme.cardGradient)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(AppTheme.accentColor.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    } else {
                        // Results
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // Interpretation
                                if let interpretation = searchResponse?.interpretation, !interpretation.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(settingsStore.appLanguage == .chineseTraditional ? "理解" : "Interpretation")
                                            .font(.headline)
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(interpretation)
                                            .font(.body)
                                            .foregroundColor(AppTheme.secondaryText)
                                            .lineSpacing(4)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.cardGradient)
                                    .cornerRadius(12)
                                }
                                
                                // Results list
                                ForEach(allResults) { verse in
                                    VerseResultRow(
                                        verse: verse,
                                        settingsStore: settingsStore,
                                        onTap: {
                                            navigateToVerse(verse)
                                        }
                                    )
                                }
                                
                                // Find More button
                                if isLoadingMore {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding(.vertical, 8)
                                        Text(settingsStore.appLanguage == .chineseTraditional ? "尋找更多..." : "Finding more...")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.secondaryText)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                } else {
                                    Button(action: {
                                        findMoreVerses()
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text(settingsStore.appLanguage == .chineseTraditional ? "尋找更多經文" : "Find More Verses")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [AppTheme.accentColor.opacity(0.8), AppTheme.accentColor.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "搜尋經文" : "Find Verse")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        guard let aiService = services.aiService else {
            errorMessage = settingsStore.appLanguage == .chineseTraditional ? "搜尋服務暫時無法使用" : "Search service temporarily unavailable"
            return
        }
        
        isLoading = true
        errorMessage = nil
        searchResponse = nil
        allResults = []
        searchProgress = 0
        lastSearchQuery = searchText
        
        // Start progress timer - animates over ~5 seconds
        startProgressTimer()
        
        Task {
            do {
                let response = try await aiService.searchVerses(
                    query: searchText,
                    appLanguage: settingsStore.appLanguage
                )
                await MainActor.run {
                    stopProgressTimer()
                    self.searchProgress = 1.0
                    self.searchResponse = response
                    self.allResults = response.results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    stopProgressTimer()
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func findMoreVerses() {
        guard let aiService = services.aiService else { return }
        
        isLoadingMore = true
        
        // Get existing references to exclude
        let existingReferences = allResults.map { $0.reference }
        
        Task {
            do {
                let response = try await aiService.searchMoreVerses(
                    query: lastSearchQuery,
                    excludeReferences: existingReferences,
                    appLanguage: settingsStore.appLanguage
                )
                await MainActor.run {
                    self.allResults.append(contentsOf: response.results)
                    self.isLoadingMore = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    private func startProgressTimer() {
        // Progress goes from 0 to ~0.9 over 5 seconds (leaves room for completion)
        // Updates every 100ms
        let totalDuration: Double = 5.0
        let updateInterval: Double = 0.1
        let incrementPerTick = 0.9 / (totalDuration / updateInterval)
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.searchProgress < 0.9 {
                    self.searchProgress += incrementPerTick
                } else {
                    // Slow down near the end to simulate waiting
                    self.searchProgress += 0.005
                    if self.searchProgress > 0.95 {
                        self.searchProgress = 0.95
                    }
                }
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func navigateToVerse(_ verse: RelatedVerse) {
        dismiss()
        
        // Parse book name and navigate
        if let bookObj = BibleData.book(named: verse.book) {
            router.navigateToReading(book: bookObj, chapter: verse.chapter, verse: verse.verse)
        }
    }
    
    private var templateQueries: [String] {
        if settingsStore.appLanguage == .chineseTraditional {
            return [
                "神如此愛世人",
                "主是我的牧者",
                "如何面對恐懼",
                "尋求心靈平安",
                "增強信心",
                "學習寬恕他人",
                "困難時的盼望",
                "愛的真諦",
                "如何禱告",
                "感恩的態度"
            ]
        } else {
            return [
                "God so loved the world",
                "The Lord is my shepherd",
                "Overcoming fear",
                "Finding inner peace",
                "Strengthening faith",
                "Learning to forgive",
                "Hope in difficult times",
                "What is true love",
                "How to pray",
                "Being thankful"
            ]
        }
    }
}

#Preview {
    VerseSearchView(settingsStore: SettingsStore.shared)
        .environmentObject(AppRouter())
}

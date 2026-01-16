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
    @State private var errorMessage: String?
    
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
                        
                        Button(settingsStore.appLanguage.localizedString("Done")) {
                            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                performSearch()
                            } else {
                                dismiss()
                            }
                        }
                        .foregroundColor(AppTheme.accentColor)
                    }
                    .padding()
                    
                    // Content
                    if isLoading {
                        ProgressView()
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
                                    Text(settingsStore.appLanguage == .chineseTraditional ? "熱門搜尋" : "Popular Searches")
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
                                if let results = searchResponse?.results {
                                    ForEach(results) { verse in
                                        VerseResultRow(
                                            verse: verse,
                                            settingsStore: settingsStore,
                                            onTap: {
                                                navigateToVerse(verse)
                                            }
                                        )
                                    }
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
            errorMessage = settingsStore.appLanguage == .chineseTraditional ? "AI服務不可用" : "AI service unavailable"
            return
        }
        
        isLoading = true
        errorMessage = nil
        searchResponse = nil
        
        Task {
            do {
                let response = try await aiService.searchVerses(
                    query: searchText,
                    appLanguage: settingsStore.appLanguage
                )
                await MainActor.run {
                    self.searchResponse = response
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
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
                "約翰福音 3:16",
                "詩篇 23",
                "愛",
                "希望",
                "平安",
                "信心",
                "馬太福音 5",
                "羅馬書 8:28",
                "箴言",
                "哥林多前書 13"
            ]
        } else {
            return [
                "John 3:16",
                "Psalm 23",
                "Love",
                "Hope",
                "Peace",
                "Faith",
                "Matthew 5",
                "Romans 8:28",
                "Proverbs",
                "1 Corinthians 13"
            ]
        }
    }
}

#Preview {
    VerseSearchView(settingsStore: SettingsStore.shared)
        .environmentObject(AppRouter())
}

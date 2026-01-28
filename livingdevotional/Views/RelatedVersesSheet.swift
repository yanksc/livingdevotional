// RelatedVersesSheet - Sheet view for displaying related verses

import SwiftUI

struct RelatedVerseOption: Identifiable {
    let id: String
    let book: String
    let chapter: Int
    let verseNumber: Int
    let verseText: String
    let reference: String
    let relevance: String
}

struct RelatedVersesSheet: View {
    let book: String
    let chapter: Int
    let verse: Int
    let verseText: String
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.services) var services
    var onDismiss: (() -> Void)?
    @EnvironmentObject var router: AppRouter
    
    @State private var verseOptions: [RelatedVerseOption] = []
    @State private var displayedVerses: [RelatedVerseOption] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var appearedOptions: Set<String> = []
    @State private var hasLoadedMore = false
    
    var body: some View {
        ZStack {
            SereneGradientBackground()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                        Text(settingsStore.appLanguage == .chineseTraditional ? "相關經文" : "Related Verses")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.secondaryText.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original verse at the top - always shown immediately
                        VStack(alignment: .leading, spacing: 12) {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "原經文" : "Original Verse")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.secondaryText)
                                .textCase(.uppercase)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)) \(chapter):\(verse)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.accentColor)
                                
                                Text(verseText)
                                    .font(.body)
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Loading or error state for related verses
                        if isLoading && displayedVerses.isEmpty {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "正在尋找相關經文..." : "Finding related verses...")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let error = errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.orange)
                                Text(settingsStore.appLanguage == .chineseTraditional ? "載入失敗" : "Failed to load")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryText)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                Button(settingsStore.appLanguage.localizedString("Retry")) {
                                    loadRelatedVerses()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accentColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if !isLoading && verseOptions.isEmpty && !displayedVerses.isEmpty {
                            // This case shouldn't happen, but handle it
                            EmptyView()
                        } else {
                            // Verse options - lazy loaded as they come in
                            VStack(spacing: 12) {
                                ForEach(Array(displayedVerses.enumerated()), id: \.element.id) { index, option in
                                    RelatedVerseOptionCard(
                                        option: option,
                                        onSelect: {
                                            navigateToVerse(option)
                                        }
                                    )
                                    .opacity(appearedOptions.contains(option.id) ? 1.0 : 0.0)
                                    .offset(x: appearedOptions.contains(option.id) ? 0 : 30)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                                            withAnimation(.easeOut(duration: 0.4)) {
                                                let _ = appearedOptions.insert(option.id)
                                            }
                                        }
                                    }
                                }
                                
                                // Show loading indicator while more verses are being loaded
                                if isLoading && !displayedVerses.isEmpty {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text(settingsStore.appLanguage == .chineseTraditional ? "載入中..." : "Loading...")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Find more button at the bottom
                            if !hasLoadedMore && verseOptions.count > displayedVerses.count && !isLoading {
                                Button(action: {
                                    loadMoreVerses()
                                }) {
                                    HStack {
                                        if isLoadingMore {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(settingsStore.appLanguage == .chineseTraditional ? "尋找更多" : "Find More")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                                .disabled(isLoadingMore)
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                            } else if !isLoading {
                                Spacer()
                                    .frame(height: 40)
                            }
                        }
                    }
                }
            }
        }
        .task {
            loadRelatedVerses()
        }
    }
    
    private func loadRelatedVerses() {
        guard let aiService = services.aiService else {
            errorMessage = settingsStore.appLanguage == .chineseTraditional ? "服務不可用" : "Service unavailable"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await aiService.findRelatedVerses(
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    text: verseText,
                    appLanguage: settingsStore.appLanguage
                )
                
                // De-duplicate by reference and limit to top 6 (3 initial + 3 more)
                var seenReferences = Set<String>()
                let uniqueResults = results.prefix(6).filter { verse in
                    let ref = "\(verse.book) \(verse.chapter):\(verse.verse)"
                    if seenReferences.contains(ref) {
                        return false
                    }
                    seenReferences.insert(ref)
                    return true
                }
                
                // Capture language settings for background tasks
                let primaryLanguage = settingsStore.primaryLanguage
                
                // Load actual verse text from BibleService using primary language in parallel
                // Lazy load: show verses as they come in, not wait for all
                await MainActor.run {
                    // Initially show first 3 verses immediately (from AI response)
                    let initialCount = min(3, uniqueResults.count)
                    var initialOptions: [RelatedVerseOption] = []
                    
                    for (index, relatedVerse) in uniqueResults.prefix(initialCount).enumerated() {
                        let bookName = BibleData.localizedBookName(relatedVerse.book, language: primaryLanguage)
                        let reference = "\(bookName) \(relatedVerse.chapter):\(relatedVerse.verse)"
                        
                        let option = RelatedVerseOption(
                            id: relatedVerse.id,
                            book: relatedVerse.book,
                            chapter: relatedVerse.chapter,
                            verseNumber: relatedVerse.verse,
                            verseText: relatedVerse.text, // Use AI text initially
                            reference: reference,
                            relevance: relatedVerse.relevance
                        )
                        initialOptions.append(option)
                    }
                    
                    // Show initial verses immediately
                    self.displayedVerses = initialOptions
                }
                
                // Now load actual verse text in background and update as they come in
                let loadedOptions = await withTaskGroup(of: RelatedVerseOption?.self) { group in
                    for relatedVerse in uniqueResults {
                        group.addTask {
                            do {
                                let verses = try await services.bibleService.loadVerses(
                                    book: relatedVerse.book,
                                    chapter: relatedVerse.chapter,
                                    translation: primaryLanguage
                                )
                                
                                if let verse = verses.first(where: { $0.verseNumber == relatedVerse.verse }) {
                                    let verseText = verse.text(for: primaryLanguage)
                                    let bookName = BibleData.localizedBookName(relatedVerse.book, language: primaryLanguage)
                                    let reference = "\(bookName) \(relatedVerse.chapter):\(relatedVerse.verse)"
                                    
                                    return RelatedVerseOption(
                                        id: relatedVerse.id,
                                        book: relatedVerse.book,
                                        chapter: relatedVerse.chapter,
                                        verseNumber: relatedVerse.verse,
                                        verseText: verseText,
                                        reference: reference,
                                        relevance: relatedVerse.relevance
                                    )
                                }
                            } catch {
                                // If loading fails, use the text from RelatedVerse
                                // This might happen if the book/chapter doesn't exist in local DB yet
                            }
                            
                            // Fallback: use text from AI response
                            let bookName = BibleData.localizedBookName(relatedVerse.book, language: primaryLanguage)
                            let reference = "\(bookName) \(relatedVerse.chapter):\(relatedVerse.verse)"
                            
                            return RelatedVerseOption(
                                id: relatedVerse.id,
                                book: relatedVerse.book,
                                chapter: relatedVerse.chapter,
                                verseNumber: relatedVerse.verse,
                                verseText: relatedVerse.text,
                                reference: reference,
                                relevance: relatedVerse.relevance
                            )
                        }
                    }
                    
                    var results: [RelatedVerseOption] = []
                    for await result in group {
                        if let result = result {
                            results.append(result)
                            
                            // Update displayed verses as they load (lazy loading)
                            await MainActor.run {
                                if let index = self.displayedVerses.firstIndex(where: { $0.id == result.id }) {
                                    // Create a new array to ensure SwiftUI detects the change
                                    var updatedVerses = self.displayedVerses
                                    updatedVerses[index] = result
                                    self.displayedVerses = updatedVerses
                                }
                            }
                        }
                    }
                    
                    // Sort results to match original order from AI (relevance)
                    return results.sorted { option1, option2 in
                        let index1 = uniqueResults.firstIndex(where: { $0.id == option1.id }) ?? Int.max
                        let index2 = uniqueResults.firstIndex(where: { $0.id == option2.id }) ?? Int.max
                        return index1 < index2
                    }
                }
                
                await MainActor.run {
                    self.verseOptions = loadedOptions
                    // Update displayed verses with full data if not already updated
                    if self.displayedVerses.count < 3 {
                        self.displayedVerses = Array(loadedOptions.prefix(3))
                    }
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
    
    private func loadMoreVerses() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        // Load next 3 verses
        let currentCount = displayedVerses.count
        let nextVerses = Array(verseOptions.dropFirst(currentCount).prefix(3))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                displayedVerses.append(contentsOf: nextVerses)
                hasLoadedMore = true
                isLoadingMore = false
            }
        }
    }
    
    private func navigateToVerse(_ option: RelatedVerseOption) {
        onDismiss?()
        
        // Navigate to the verse
        if let bookObj = BibleData.book(named: option.book) {
            router.navigateToReading(book: bookObj, chapter: option.chapter, verse: option.verseNumber)
        }
    }
}

struct RelatedVerseOptionCard: View {
    let option: RelatedVerseOption
    var onSelect: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    // Reference
                    Text(option.reference)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor)
                    
                    // Verse text preview
                    Text(option.verseText)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Relevance (if available)
                    if !option.relevance.isEmpty {
                        Text(option.relevance)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Transfer icon
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 32, height: 32)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RelatedVersesSheet(
        book: "John",
        chapter: 3,
        verse: 16,
        verseText: "For God so loved the world...",
        settingsStore: SettingsStore.shared,
        onDismiss: nil
    )
    .environmentObject(AppRouter())
}

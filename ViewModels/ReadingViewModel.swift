// ReadingViewModel - Manages verse loading and display

import Foundation
import Combine

class ReadingViewModel: ObservableObject {
    @Published var verses: [BibleVerse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let bibleService = BibleService.shared
    private let settingsStore = SettingsStore.shared
    private let progressStore = ProgressStore.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe settings changes to reload verses
        settingsStore.$primaryLanguage
            .combineLatest(settingsStore.$secondaryLanguage)
            .sink { [weak self] _, _ in
                // Reload if we have a current chapter
                if let book = self?.currentBook, let chapter = self?.currentChapter {
                    Task {
                        await self?.loadVerses(book: book, chapter: chapter)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    var currentBook: String?
    var currentChapter: Int?
    
    @MainActor
    func loadVerses(book: String, chapter: Int) async {
        // Always reload to ensure we have the latest data
        currentBook = book
        currentChapter = chapter
        isLoading = true
        errorMessage = nil
        
        do {
            let primary = settingsStore.primaryLanguage
            let secondary = settingsStore.secondaryLanguage
            
            let loadedVerses = try await bibleService.loadVersesDualLanguage(
                book: book,
                chapter: chapter,
                primary: primary,
                secondary: secondary
            )
            
            verses = loadedVerses.sorted { $0.verseNumber < $1.verseNumber }
            
            // Save progress
            progressStore.saveProgress(book: book, chapter: chapter)
        } catch {
            errorMessage = error.localizedDescription
            verses = []
            print("Error loading verses: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func refreshVerses() {
        guard let book = currentBook, let chapter = currentChapter else { return }
        Task {
            await loadVerses(book: book, chapter: chapter)
        }
    }
}


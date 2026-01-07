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
    private var loadingTask: Task<Void, Never>?
    
    @MainActor
    func loadVerses(book: String, chapter: Int) async {
        // Cancel any existing load task to prevent race conditions
        loadingTask?.cancel()
        
        // Always reload to ensure we have the latest data
        currentBook = book
        currentChapter = chapter
        isLoading = true
        errorMessage = nil
        
        // Store the task so we can cancel it if needed
        loadingTask = Task { @MainActor in
            do {
                let primary = settingsStore.primaryLanguage
                let secondary = settingsStore.secondaryLanguage
                
                let loadedVerses = try await bibleService.loadVersesDualLanguage(
                    book: book,
                    chapter: chapter,
                    primary: primary,
                    secondary: secondary
                )
                
                // Only update if task wasn't cancelled
                if !Task.isCancelled {
                    verses = loadedVerses.sorted { $0.verseNumber < $1.verseNumber }
                    
                    // Save progress
                    progressStore.saveProgress(book: book, chapter: chapter)
                }
            } catch {
                // Only set error if task wasn't cancelled
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    verses = []
                    print("Error loading verses: \(error.localizedDescription)")
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
            loadingTask = nil
        }
        
        await loadingTask?.value
    }
    
    func refreshVerses() {
        guard let book = currentBook, let chapter = currentChapter else { return }
        Task {
            await loadVerses(book: book, chapter: chapter)
        }
    }
}

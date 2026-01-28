// HomeViewModel - ViewModel for HomeView

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var verseOfTheDay: DailyVerse?
    @Published var recentReading: ReadingProgress?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let services: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    init(services: ServiceContainer = .shared) {
        self.services = services
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: NSNotification.Name("RefreshVerseOfTheDay"))
            .sink { [weak self] _ in
                self?.loadHomeData()
            }
            .store(in: &cancellables)
    }
    
    func loadHomeData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadVerseOfTheDay()
            await loadRecentReading()
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func loadVerseOfTheDay() async {
        guard let dailyVerseService = services.dailyVerseService else {
            return
        }
        
        do {
            let verse = try await dailyVerseService.getVerseOfTheDay(date: nil)
            await MainActor.run {
                self.verseOfTheDay = verse
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func loadRecentReading() async {
        guard let userService = services.userService else {
            // Fallback to local progress store
            let progress = services.progressStore
            if let book = progress.currentBook,
               let chapter = progress.currentChapter {
                await MainActor.run {
                    // Create a simple ReadingProgress from local data
                    self.recentReading = ReadingProgress(
                        id: "local",
                        userId: "local",
                        book: book,
                        chapter: chapter,
                        lastVerse: 1, // Default to 1 as we don't track exact verse yet
                        lastReadAt: Date()
                    )
                }
            }
            return
        }
        
        do {
            let progress = try await userService.getUserProgress()
            await MainActor.run {
                self.recentReading = progress
            }
        } catch {
            // Silently fail - not critical for home screen
        }
    }
}


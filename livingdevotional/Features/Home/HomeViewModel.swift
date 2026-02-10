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
    
    /// Retry loading verse of the day with force refresh to clear any corrupted cache
    func retryLoadVerse() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Force refresh to clear any cached corrupted data
            let dailyVerseService: DailyVerseServiceProtocol = services.dailyVerseService ?? DailyVerseService.shared
            
            do {
                let verse = try await dailyVerseService.forceRefreshVerseOfTheDay()
                await MainActor.run {
                    self.verseOfTheDay = verse
                    self.errorMessage = nil
                    self.isLoading = false
                }
            } catch {
                print("[HomeViewModel] Retry failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.verseOfTheDay = nil
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadVerseOfTheDay() async {
        // Fallback to DailyVerseService.shared if not registered in ServiceContainer
        let dailyVerseService: DailyVerseServiceProtocol = services.dailyVerseService ?? DailyVerseService.shared
        
        do {
            let verse = try await dailyVerseService.getVerseOfTheDay(date: nil)
            await MainActor.run {
                self.verseOfTheDay = verse
                self.errorMessage = nil
            }
        } catch {
            // Log error for debugging on physical devices
            print("[HomeViewModel] Failed to load verse of the day: \(error.localizedDescription)")
            await MainActor.run {
                self.verseOfTheDay = nil
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


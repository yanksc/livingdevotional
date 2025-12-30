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
            if progress.currentBook != nil,
               progress.currentChapter != nil {
                await MainActor.run {
                    // Create a simple ReadingProgress from local data
                    // This is a placeholder until UserService is implemented
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


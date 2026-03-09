// JourneyViewModel - Manages state for Journey feature
//

import Foundation
import Combine

class JourneyViewModel: ObservableObject {
    @Published var stats: JourneyStats?
    @Published var dailyInsight: JourneyInsight?
    @Published var milestones: [JourneyMilestone] = []
    @Published var aiAnalysis: AIJourneyAnalysis?
    @Published var isLoading = false
    @Published var isLoadingAI = false
    @Published var errorMessage: String?
    @Published var aiErrorMessage: String?
    
    private let services: ServiceContainer
    
    init(services: ServiceContainer = .shared) {
        self.services = services
    }
    
    @MainActor
    func loadData() async {
        guard let journeyService = services.journeyService else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all data in parallel
            async let statsTask = journeyService.getJourneyStats()
            async let insightTask = journeyService.getDailyInsight()
            async let milestonesTask = journeyService.getMilestones(limit: 20)
            
            let (fetchedStats, fetchedInsight, fetchedMilestones) = try await (statsTask, insightTask, milestonesTask)
            
            self.stats = fetchedStats
            self.dailyInsight = fetchedInsight
            self.milestones = fetchedMilestones
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    @MainActor
    func loadPersistedAnalysisIfNeeded(appLanguage: AppLanguage) {
        guard let journeyService = services.journeyService,
              let persisted = journeyService.getPersistedAnalysisIfValid(appLanguage: appLanguage) else { return }
        aiAnalysis = persisted
    }
    
    @MainActor
    func loadAIAnalysis(appLanguage: AppLanguage) async {
        guard let journeyService = services.journeyService else { return }
        
        // Only show loading if we don't have analysis to display (avoids flicker when refreshing in background)
        if aiAnalysis == nil {
            isLoadingAI = true
        }
        aiErrorMessage = nil
        
        do {
            let analysis = try await journeyService.getAIJourneyAnalysis(appLanguage: appLanguage)
            self.aiAnalysis = analysis
            self.isLoadingAI = false
        } catch {
            self.aiErrorMessage = error.localizedDescription
            self.isLoadingAI = false
        }
    }
    
    @MainActor
    func refreshAIAnalysis(appLanguage: AppLanguage) async {
        guard let journeyService = services.journeyService as? JourneyService else { return }
        
        // Check usage limit first
        guard UsageLimitStore.shared.canRefreshJourneyAnalysis() else {
            aiErrorMessage = appLanguage.localizedString("JourneyRefreshLimitReached")
            return
        }
        
        isLoadingAI = true
        aiErrorMessage = nil
        
        do {
            let analysis = try await journeyService.refreshAIAnalysis(appLanguage: appLanguage)
            self.aiAnalysis = analysis
            UsageLimitStore.shared.recordJourneyRefreshUsed()
            self.isLoadingAI = false
        } catch {
            self.aiErrorMessage = error.localizedDescription
            self.isLoadingAI = false
        }
    }
}

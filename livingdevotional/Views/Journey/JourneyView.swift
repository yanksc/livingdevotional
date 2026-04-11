// JourneyView.swift
// Main view for the Journey feature showing spiritual insights, stats and timeline
//
// Subviews are organized in separate files:
// - JourneyAIViews.swift: AILoadingView, AIErrorView, GetAIInsightsButton
// - JourneyContentViews.swift: EncouragementHeroView, PathStatusCardView, JourneySummaryView,
//   RecommendedVerseView, PathHighlightsView, NextStepView
// - JourneyStatsView.swift: JourneyStatsView, StatBox
// - MyRecordsSheet.swift: MyRecordsSheet, RecordCard (opened from nav bar)

import SwiftUI

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showRecordsSheet = false
    @State private var showAnalysisFullScreen = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Spiritual Analysis Section
                        if viewModel.isLoadingAI {
                            AILoadingView()
                        } else if let analysis = viewModel.aiAnalysis {
                            // Path Status Card (merged with encouragement and summary)
                            PathStatusCardView(pathStatus: analysis.pathStatus) {
                                showAnalysisFullScreen = true
                            }
                            
                            // Path Highlights
                            if !analysis.pathHighlights.isEmpty {
                                PathHighlightsView(highlights: analysis.pathHighlights)
                            }
                            
                            // Recommended Reading (replaced Next Step)
                            RecommendedReadingView(reading: analysis.recommendedReading)
                            
                        } else if let error = viewModel.aiErrorMessage {
                            // Error state with retry
                            AIErrorView(error: error) {
                                Task {
                                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        }
                        
                        // Stats Row - Display only
                        if let stats = viewModel.stats {
                            JourneyStatsView(stats: stats)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .principal) {
                        Text("Living Path")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if !UsageLimitStore.shared.canRefreshJourneyAnalysis() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("JourneyRefreshLimitReached"))
                            } else {
                                Task {
                                    await viewModel.refreshAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoadingAI)
                    }
                    .sharedBackgroundVisibility(.hidden)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button { showRecordsSheet = true } label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            .buttonStyle(.plain)
                            ProfileAvatarButton { router.showSettings = true }
                        }
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .principal) {
                        Text("Living Path")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.accentColor)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if !UsageLimitStore.shared.canRefreshJourneyAnalysis() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("JourneyRefreshLimitReached"))
                            } else {
                                Task {
                                    await viewModel.refreshAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoadingAI)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button { showRecordsSheet = true } label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            .buttonStyle(.plain)
                            ProfileAvatarButton { router.showSettings = true }
                        }
                    }
                }
            }
            .sheet(isPresented: $showRecordsSheet) {
                MyRecordsSheet()
                    .environmentObject(router)
            }
            .fullScreenCover(isPresented: $showAnalysisFullScreen) {
                if let analysis = viewModel.aiAnalysis {
                    AnalysisFullScreenView(pathStatus: analysis.pathStatus)
                }
            }
            .onAppear {
                viewModel.loadPersistedAnalysisIfNeeded(appLanguage: settingsStore.appLanguage)
                Task {
                    await viewModel.loadData()
                    // Always load AI analysis - service handles cache and persisted store
                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                }
            }
        }
    }
}

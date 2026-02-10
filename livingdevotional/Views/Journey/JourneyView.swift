// JourneyView.swift
// Main view for the Journey feature showing spiritual insights, stats and timeline
//
// Subviews are organized in separate files:
// - JourneyAIViews.swift: AILoadingView, AIErrorView, GetAIInsightsButton
// - JourneyContentViews.swift: EncouragementHeroView, PathStatusCardView, JourneySummaryView,
//   RecommendedVerseView, PathHighlightsView, NextStepView
// - JourneyStatsView.swift: JourneyStatsView, StatBox
// - JourneyWidgetViews.swift: TimelineWidgetView, TimelineItemRow, RecentHistoryWidgetView,
//   RecentHistoryCard, MyNotesWidgetView, NoteCard

import SwiftUI

struct JourneyView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showDetails = false
    
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
                            // Hero Encouragement
                            EncouragementHeroView(encouragement: analysis.encouragement)
                            
                            // Path Status Card
                            PathStatusCardView(pathStatus: analysis.pathStatus)
                            
                            // Journey Summary
                            if !analysis.journeySummary.isEmpty {
                                JourneySummaryView(summary: analysis.journeySummary)
                            }
                            
                            // Recommended Verse
                            if let verse = analysis.recommendedVerse {
                                RecommendedVerseView(verse: verse)
                            }
                            
                            // Path Highlights
                            if !analysis.pathHighlights.isEmpty {
                                PathHighlightsView(highlights: analysis.pathHighlights)
                            }
                            
                            // Next Step CTA
                            if !analysis.nextStep.isEmpty {
                                NextStepView(nextStep: analysis.nextStep)
                            }
                            
                        } else if let error = viewModel.aiErrorMessage {
                            // Error state with retry
                            AIErrorView(error: error) {
                                Task {
                                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        } else {
                            // No cache - show button to get spiritual insights
                            GetAIInsightsButton {
                                Task {
                                    await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                                }
                            }
                        }
                        
                        // Stats Row - Below the summary section, expandable
                        if let stats = viewModel.stats {
                            JourneyStatsView(stats: stats, showDetails: $showDetails)
                        }
                        
                        // Detailed sections - Only shown when expanded
                        if showDetails {
                            // Recent History Section - Horizontal Scrollable Widgets
                            RecentHistoryWidgetView(
                                historyItems: progressStore.getRecentHistory(limit: 5),
                                settingsStore: settingsStore,
                                router: router
                            )
                            
                            // My Notes Section - Horizontal Scrollable Widgets
                            MyNotesWidgetView(
                                savedVerses: Array(noteStore.savedVerses.prefix(5)),
                                settingsStore: settingsStore,
                                router: router
                            )
                            
                            // Timeline Section - Small Timeline Widget
                            TimelineWidgetView(
                                milestones: viewModel.milestones,
                                isLoading: viewModel.isLoading
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "了解你的屬靈之路" : "Discover Your Spiritual Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            await viewModel.refreshAIAnalysis(appLanguage: settingsStore.appLanguage)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .disabled(viewModel.isLoadingAI)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadData()
                    // Only auto-load spiritual analysis if cached
                    if viewModel.hasCachedAnalysis {
                        await viewModel.loadAIAnalysis(appLanguage: settingsStore.appLanguage)
                    }
                }
            }
        }
    }
}

// PrayerFlowView.swift
// Anytime Prayer Feature - Allows users to generate personalized prayers
//
// Subviews and logic are organized in separate files:
// - PrayerFlow/PrayerFlowModels.swift: VerseOption, PrayerFocus, EmotionalNeed, PrayerQuestionType
// - PrayerFlow/PrayerFlowViewModel.swift: Business logic, AI calls, verse loading
// - PrayerFlow/PrayerFlowQuestionViews.swift: HeartFocusQuestionView, ChooseVerseQuestionView,
//   EmotionalNeedQuestionView, VerseOptionCard, ProgressIndicator
// - PrayerFlow/PrayerResultView.swift: PrayerResultView, PrayerTypewriterText, AmenButton

import SwiftUI

// MARK: - Prayer Flow View

struct PrayerFlowView: View {
    @StateObject private var viewModel: PrayerFlowViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    init(initialVerse: BibleVerse? = nil) {
        _viewModel = StateObject(wrappedValue: PrayerFlowViewModel(initialVerse: initialVerse))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with cross-fade transition support
                ZStack {
                    // Base background (always visible)
                    SerenePrayerBackground()
                        .opacity(1.0 - viewModel.backgroundTransitionProgress)
                        .overlay(
                            Color.black.opacity(viewModel.backgroundTransitionProgress * 0.5)
                        )
                    
                    // New prayer background (fading in during transition)
                    if viewModel.backgroundTransitionProgress > 0 {
                        SerenePrayerBackground(
                            overlayOpacity: 0.45,
                            edgeBoundaryWidth: 28,
                            edgeBoundaryOpacity: 0.35,
                            showVignette: true
                        )
                        .opacity(viewModel.backgroundTransitionProgress)
                    }
                }
                
                if viewModel.isLoadingVerse || viewModel.isLoadingPrayer {
                    PrayerGenerationWaitingView(
                        verse: viewModel.selectedVerse,
                        focus: viewModel.selectedFocus,
                        emotionalNeed: viewModel.emotionalNeed,
                        prayerIntent: viewModel.selectedIntent
                    )
                } else if let verse = viewModel.selectedVerse, !viewModel.generatedPrayer.isEmpty {
                    // Show verse and prayer result
                    PrayerResultView(
                        verse: verse,
                        prayer: viewModel.generatedPrayer,
                        onDismiss: { dismiss() }
                    )
                    .opacity(viewModel.backgroundTransitionProgress)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .padding()
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Button(settingsStore.appLanguage == .chineseTraditional ? "重試" : "Retry") {
                            viewModel.errorMessage = nil
                            if viewModel.selectedVerse == nil {
                                viewModel.generatePersonalizedVerse()
                            } else {
                                Task {
                                    await viewModel.generatePrayer(for: viewModel.selectedVerse!)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                } else {
                    // Show questions with page-flip transition
                    ZStack {
                        ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                            if index == viewModel.currentQuestionIndex {
                                ScrollView {
                                    VStack(spacing: 24) {
                                        // Progress indicator
                                        ProgressIndicator(
                                            current: viewModel.currentQuestionIndex + 1,
                                            total: viewModel.questions.count
                                        )
                                        .padding(.top)
                                        
                                        // Question content
                                        Group {
                                            switch question {
                                            case .prayerIntent:
                                                PrayerIntentQuestionView(
                                                    selectedIntent: $viewModel.selectedIntent,
                                                    onNext: viewModel.handleAnswer,
                                                    onSkip: viewModel.handleSkip
                                                )
                                            case .heartFocus:
                                                HeartFocusQuestionView(
                                                    selectedFocus: $viewModel.selectedFocus,
                                                    customTopicText: $viewModel.customTopicText,
                                                    onNext: viewModel.handleAnswer,
                                                    onSkip: viewModel.handleSkip
                                                )
                                            case .chooseVerse:
                                                ChooseVerseQuestionView(
                                                    verseOptions: viewModel.verseOptions,
                                                    isLoading: viewModel.isLoadingOptions,
                                                    selectedOption: $viewModel.selectedVerseOption,
                                                    onNext: viewModel.handleAnswer,
                                                    onSkip: viewModel.handleSkip,
                                                    onLoadOptions: viewModel.loadVerseOptions
                                                )
                                            case .emotionalNeed:
                                                EmotionalNeedQuestionView(
                                                    selectedNeed: $viewModel.emotionalNeed,
                                                    onNext: viewModel.handleAnswer,
                                                    onSkip: viewModel.handleSkip
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                }
                
                // Custom back button overlay (only show when NOT showing prayer result)
                if !(viewModel.selectedVerse != nil && !viewModel.generatedPrayer.isEmpty) {
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 20)
                            .padding(.top, 8)
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(true)
                    .zIndex(1000)
                }
            }
            .navigationBarHidden(true)
            .colorScheme(.dark)
            .onAppear {
                // Preload a random background image for immediate display
                let randomBg = SereneBackgroundManager.shared.randomBackground()
                let targetSize = CGSize(
                    width: UIScreen.main.bounds.width * UIScreen.main.scale,
                    height: UIScreen.main.bounds.height * UIScreen.main.scale
                )
                Task {
                    _ = await SereneImageCache.shared.loadImageAsync(
                        filename: randomBg,
                        targetSize: targetSize
                    )
                }
                
                viewModel.setup(services: services)
            }
            .onChange(of: viewModel.limitReached) { _, reached in
                if reached {
                    router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("PrayerLimitReached"))
                    viewModel.limitReached = false
                }
            }
        }
    }
}

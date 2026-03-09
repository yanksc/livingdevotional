// PrayerFlowQuestionViews.swift
// Question views for the Prayer Flow feature

import SwiftUI

// MARK: - Prayer Intro View (phased: background emerges, then main line + verse in rounded rect)

struct PrayerIntroView: View {
    @Binding var introLine1Visible: Bool
    @Binding var introLine2Visible: Bool
    var onContinue: () -> Void
    var onAppear: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var hasAdvanced = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            
            // Line 1 + Line 2 grouped, vertically centered
            VStack(spacing: 24) {
                // Line 1: "Every prayer brings you closer to Him" (smaller font)
                introLine(
                    settingsStore.appLanguage.localizedString("PrayerIntroLine2"),
                    font: .title2,
                    isLarge: true,
                    isVisible: introLine1Visible
                )
                .padding(.horizontal, 24)
                
                // Line 2: Psalm 145:18 quote in rounded rectangle
                introVerseLine(
                    settingsStore.appLanguage.localizedString("PrayerIntroLine3"),
                    isVisible: introLine2Visible
                )
                .padding(.horizontal, 32)
            }
            
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture {
            advanceIfNeeded()
        }
        .onAppear {
            onAppear()
        }
    }
    
    @ViewBuilder
    private func introLine(_ text: String, font: Font, isLarge: Bool, isVisible: Bool) -> some View {
        ZStack(alignment: .center) {
            Text(text)
                .font(font)
                .fontWeight(isLarge ? .semibold : .medium)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .hidden()
            Text(text)
                .font(font)
                .fontWeight(isLarge ? .semibold : .medium)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .opacity(isVisible ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private func introVerseLine(_ text: String, isVisible: Bool) -> some View {
        ZStack(alignment: .center) {
            Text(text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .hidden()
            Text(text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .opacity(isVisible ? 1 : 0)
        }
    }
    
    private func advanceIfNeeded() {
        guard !hasAdvanced else { return }
        hasAdvanced = true
        onContinue()
    }
}

// MARK: - Prayer First Screen View (all-in-one: heart + topic + intent)

struct PrayerFirstScreenView: View {
    @Binding var selectedTopics: Set<PrayerTopic>
    @Binding var customTopicText: String
    @Binding var selectedIntent: PrayerIntent?
    var onIntentSelected: (PrayerIntent) -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var textBoxMinHeight: CGFloat {
        UIScreen.main.bounds.height * 0.3
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. Prompt (no "today" - user may pray many times a day)
            Text(settingsStore.appLanguage.localizedString("PrayerFirstPrompt"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // 2. Optional text box - ~30% of screen height, aligned to top with reasonable margin
            TextField(
                settingsStore.appLanguage.localizedString("PrayerFirstPlaceholder"),
                text: $customTopicText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .foregroundColor(.white.opacity(0.95))
            .accentColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(minHeight: textBoxMinHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AnyShapeStyle(.ultraThinMaterial.opacity(0.3)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .lineLimit(5...12)
            
            // 3. Bridge sentence before 3x3 grid
            Text(settingsStore.appLanguage.localizedString("PrayerFirstOrChoose"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.85))
            
            // 4. 3x3 topic grid (multi-select)
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(PrayerTopic.allCases, id: \.self) { topic in
                    topicChip(topic)
                }
            }
            
            Spacer(minLength: 16)
            
            // 5. Two buttons at bottom - semi-transparent color fill
            HStack(spacing: 12) {
                ForEach(PrayerIntent.allCases, id: \.self) { intent in
                    Button {
                        selectedIntent = intent
                        onIntentSelected(intent)
                    } label: {
                        Text(intent.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.95))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(intentButtonBackground(isSelected: selectedIntent == intent))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func topicChip(_ topic: PrayerTopic) -> some View {
        let isSelected = selectedTopics.contains(topic)
        return Button {
            if isSelected {
                selectedTopics.remove(topic)
            } else {
                selectedTopics.insert(topic)
            }
        } label: {
            Text(topic.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.95))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AnyShapeStyle(.ultraThinMaterial.opacity(isSelected ? 0.4 : 0.2)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func intentButtonBackground(isSelected: Bool) -> some View {
        let sageFill = Color(red: 0.45, green: 0.55, blue: 0.5).opacity(isSelected ? 0.38 : 0.2)
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AnyShapeStyle(.ultraThinMaterial.opacity(isSelected ? 0.3 : 0.12)))
            RoundedRectangle(cornerRadius: 16)
                .fill(sageFill)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(isSelected ? 0.35 : 0.2), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

// MARK: - Prayer Intent Question View (legacy - kept for reference)

struct PrayerIntentQuestionView: View {
    @Binding var selectedIntent: PrayerIntent?
    var onNext: () -> Void
    var onSkip: (() -> Void)? = nil
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<PrayerIntent> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            intentCards
            skipButtonIfNeeded
        }
    }
    
    @ViewBuilder
    private var intentCards: some View {
        VStack(spacing: 16) {
            ForEach(Array(PrayerIntent.allCases.enumerated()), id: \.element) { index, intent in
                intentCard(intent: intent, index: index)
            }
        }
    }
    
    private func intentCard(intent: PrayerIntent, index: Int) -> some View {
        let isSelected = selectedIntent == intent
        return Button {
            selectedIntent = intent
            onNext()
        } label: {
            Text(intent.displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.95))
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(intentCardBackground(isSelected: isSelected))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .opacity(appearedOptions.contains(intent) ? 1.0 : 0.0)
        .offset(x: appearedOptions.contains(intent) ? 0 : 30)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeOut(duration: 0.4)) {
                    let _ = appearedOptions.insert(intent)
                }
            }
        }
    }
    
    @ViewBuilder
    private func intentCardBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
        } else {
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private var skipButtonIfNeeded: some View {
        if let onSkip = onSkip {
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Heart Focus Question View

struct HeartFocusQuestionView: View {
    @Binding var selectedFocus: PrayerFocus?
    @Binding var customTopicText: String
    var onNext: () -> Void
    var onSkip: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<PrayerFocus> = []
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "今天您心中有什麼？" : "What's on your heart today?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            VStack(spacing: 12) {
                ForEach(Array(PrayerFocus.allCases.enumerated()), id: \.element) { index, focus in
                    Button {
                        selectedFocus = focus
                        if focus != .custom {
                            onNext()
                        } else {
                            isTextFieldFocused = true
                        }
                    }                     label: {
                        HStack {
                            Text(focus.displayName)
                                .foregroundColor(.white.opacity(0.95))
                            Spacer()
                            if selectedFocus == focus {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding()
                        .background(
                            Group {
                                if selectedFocus == focus {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial.opacity(0.4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                }
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .opacity(appearedOptions.contains(focus) ? 1.0 : 0.0)
                    .offset(x: appearedOptions.contains(focus) ? 0 : 30)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                let _ = appearedOptions.insert(focus)
                            }
                        }
                    }
                }
                
                // Custom topic text field (shown when custom is selected)
                if selectedFocus == .custom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(settingsStore.appLanguage == .chineseTraditional ? "請輸入您的禱告主題" : "Enter your prayer topic")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField(
                            settingsStore.appLanguage == .chineseTraditional ? "例如：工作、家庭、健康..." : "e.g., work, family, health...",
                            text: $customTopicText,
                            axis: .vertical
                        )
                        .focused($isTextFieldFocused)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white.opacity(0.95))
                        .accentColor(.white.opacity(0.9))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isTextFieldFocused ? Color.white.opacity(0.5) : Color.white.opacity(0.2), lineWidth: isTextFieldFocused ? 2 : 1)
                                )
                        )
                        .lineLimit(3...5)
                        
                        Button {
                            if !customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onNext()
                            }
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "繼續" : "Continue")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.95))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Group {
                                        if customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial.opacity(0.2))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial.opacity(0.5))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(customTopicText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 4)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            
            // Skip button
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Choose Verse Question View

struct ChooseVerseQuestionView: View {
    let verseOptions: [VerseOption]
    let isLoading: Bool
    let selectedVerse: DailyVerse?
    @Binding var selectedOption: VerseOption?
    var onFindVerse: () -> Void
    var onSelectOption: (VerseOption) -> Void
    var onLoadOptions: () -> Void
    var onConfirmVerse: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var isExpanded: Bool
    @State private var appearedOptions: Set<String> = []
    
    init(verseOptions: [VerseOption], isLoading: Bool, selectedVerse: DailyVerse?, selectedOption: Binding<VerseOption?>, onFindVerse: @escaping () -> Void, onSelectOption: @escaping (VerseOption) -> Void, onLoadOptions: @escaping () -> Void, onConfirmVerse: @escaping () -> Void) {
        self.verseOptions = verseOptions
        self.isLoading = isLoading
        self.selectedVerse = selectedVerse
        self._selectedOption = selectedOption
        self.onFindVerse = onFindVerse
        self.onSelectOption = onSelectOption
        self.onLoadOptions = onLoadOptions
        self.onConfirmVerse = onConfirmVerse
        self._isExpanded = State(initialValue: selectedVerse != nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage.localizedString("ChooseVerseTitle"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Main verse card: loading, or AI-generated verse, or Find verse CTA
            if isLoading {
                verseLoadingCard
            } else if let verse = selectedVerse {
                verseFoundCard(verse)
            } else {
                findVerseButton
            }
            
            // Secondary: Expandable "Other related verses"
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    if verseOptions.isEmpty && !isLoading {
                        Button(settingsStore.appLanguage.localizedString("LoadVerseOptions")) {
                            onLoadOptions()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white.opacity(0.2))
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(verseOptions.enumerated()), id: \.element.id) { index, option in
                                VerseOptionCard(
                                    option: option,
                                    isSelected: selectedOption?.id == option.id,
                                    onSelect: {
                                        selectedOption = option
                                        onSelectOption(option)
                                    }
                                )
                                .opacity(appearedOptions.contains(option.id) ? 1.0 : 0.0)
                                .offset(x: appearedOptions.contains(option.id) ? 0 : 30)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            let _ = appearedOptions.insert(option.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                },
                label: {
                    Text(settingsStore.appLanguage.localizedString("OtherRelatedVerses"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
            )
            .tint(.white.opacity(0.9))
        }
        .onChange(of: selectedVerse?.reference ?? "") { _, newRef in
            if !newRef.isEmpty {
                withAnimation(.easeOut(duration: 0.3)) {
                    isExpanded = true
                }
            }
        }
    }
    
    private var verseLoadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white.opacity(0.9))
                .scaleEffect(1.2)
            Text(settingsStore.appLanguage.localizedString("FindingVerse"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func verseFoundCard(_ verse: DailyVerse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settingsStore.appLanguage.localizedString("VerseForYourPrayer"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.85))
            
            Text(verse.text(for: settingsStore.primaryLanguage))
                .font(.body)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(BibleData.localizedBookName(verse.book, language: settingsStore.primaryLanguage) + " \(verse.chapter):\(verse.verseNumber)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                
                Spacer()
                
                Button {
                    onFindVerse()
                } label: {
                    Text(settingsStore.appLanguage.localizedString("FindDifferentVerse"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onConfirmVerse()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var findVerseButton: some View {
        Button {
            onFindVerse()
        } label: {
            HStack {
                Text(settingsStore.appLanguage.localizedString("FindVerseForMe"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Verse Option Card

struct VerseOptionCard: View {
    let option: VerseOption
    let isSelected: Bool
    var onSelect: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Source label
                Text(option.sourceDescription)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.85))
                
                // Verse text preview
                Text(option.verseText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Reference
                if option.source != .newSearch {
                    Text("\(BibleData.localizedBookName(option.book, language: settingsStore.primaryLanguage)) \(option.chapter):\(option.verseNumber)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }
                
                if isSelected {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Emotional Need Question View

struct EmotionalNeedQuestionView: View {
    @Binding var selectedNeed: EmotionalNeed?
    var onNext: () -> Void
    var onSkip: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<EmotionalNeed> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "您現在最需要什麼？" : "What would help you most right now?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            VStack(spacing: 12) {
                ForEach(Array(EmotionalNeed.allCases.enumerated()), id: \.element) { index, need in
                    Button {
                        selectedNeed = need
                        onNext()
                    }                     label: {
                        HStack {
                            Text(need.displayName)
                                .foregroundColor(.white.opacity(0.95))
                            Spacer()
                            if selectedNeed == need {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding()
                        .background(
                            Group {
                                if selectedNeed == need {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial.opacity(0.4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                }
                            }
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .opacity(appearedOptions.contains(need) ? 1.0 : 0.0)
                    .offset(x: appearedOptions.contains(need) ? 0 : 30)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                let _ = appearedOptions.insert(need)
                            }
                        }
                    }
                }
            }
            
            // Skip button
            Button {
                onSkip()
            } label: {
                Text(settingsStore.appLanguage == .chineseTraditional ? "跳過" : "Skip")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

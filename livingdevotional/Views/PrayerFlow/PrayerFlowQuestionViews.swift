// PrayerFlowQuestionViews.swift
// Question views for the Prayer Flow feature

import SwiftUI

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
    @Binding var selectedOption: VerseOption?
    var onNext: () -> Void
    var onSkip: () -> Void
    var onLoadOptions: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var appearedOptions: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "選擇一節經文來禱告" : "Choose a verse to pray with")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            if isLoading {
                ProgressView()
                    .tint(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if verseOptions.isEmpty {
                Button(settingsStore.appLanguage == .chineseTraditional ? "載入經文選項" : "Load Verse Options") {
                    onLoadOptions()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(verseOptions.enumerated()), id: \.element.id) { index, option in
                            VerseOptionCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id,
                                onSelect: {
                                    selectedOption = option
                                    onNext()
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

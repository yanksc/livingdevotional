// SavedNotesListView - Displays saved verses with filtering by labels

import SwiftUI

// MARK: - SavedNotesTab Enum

enum SavedNotesTab: String, CaseIterable {
    case all = "All"
    case highlights = "Highlights"
    case notes = "Notes"
    
    func localizedTitle(_ language: String) -> String {
        switch self {
        case .all:
            return language == "zh-Hant" ? "全部" : "All"
        case .highlights:
            return language == "zh-Hant" ? "高亮" : "Highlights"
        case .notes:
            return language == "zh-Hant" ? "筆記" : "Notes"
        }
    }
}

struct SavedNotesListView: View {
    @ObservedObject var noteStore: NoteStore
    @ObservedObject var settingsStore: SettingsStore
    @EnvironmentObject var router: AppRouter
    @State private var selectedLabel: String?
    @State private var selectedTab: SavedNotesTab = .all
    @State private var navigationPath = NavigationPath()
    
    var filteredVerses: [SavedVerse] {
        let byLabel = noteStore.getVersesFilteredByLabel(selectedLabel)
        
        switch selectedTab {
        case .all:
            return byLabel
        case .highlights:
            return byLabel.filter { $0.color != nil }
        case .notes:
            return byLabel.filter { !$0.content.trimmingCharacters(in: .whitespaces).isEmpty }
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab picker
                tabPicker
                
                // Filter bar
                if !noteStore.getAllLabels().isEmpty {
                    filterBar
                }
                
                // Notes list
                if filteredVerses.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
        }
        .navigationTitle(settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant" ? "我的筆記" : "My Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - View Components
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(SavedNotesTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.localizedTitle(settingsStore.appLanguage.resolvedLanguageCode()))
                            .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular, design: .serif))
                            .foregroundColor(selectedTab == tab ? AppTheme.accentColor : AppTheme.secondaryText)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.accentColor : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(AppTheme.cardGradient)
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All filter
                FilterChip(
                    label: "All",
                    isSelected: selectedLabel == nil
                ) {
                    selectedLabel = nil
                }
                
                // Label filters
                ForEach(noteStore.getAllLabels(), id: \.self) { label in
                    FilterChip(
                        label: label,
                        isSelected: selectedLabel == label
                    ) {
                        selectedLabel = selectedLabel == label ? nil : label
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(AppTheme.cardGradient)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab == .highlights ? "highlighter" : "bookmark")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateTitle: String {
        let isChinese = settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant"
        
        if selectedLabel != nil {
            return isChinese ? "沒有此標籤的經文" : "No verses with this label"
        }
        
        switch selectedTab {
        case .all:
            return isChinese ? "沒有保存的經文" : "No saved verses"
        case .highlights:
            return isChinese ? "沒有高亮的經文" : "No highlighted verses"
        case .notes:
            return isChinese ? "沒有筆記" : "No notes"
        }
    }
    
    private var emptyStateMessage: String {
        let isChinese = settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant"
        
        switch selectedTab {
        case .all:
            return isChinese ? "閱讀時保存經文即可在此查看" : "Save verses while reading to see them here"
        case .highlights:
            return isChinese ? "長按經文以高亮顯示" : "Long press verses to highlight them"
        case .notes:
            return isChinese ? "保存帶有筆記的經文即可在此查看" : "Save verses with notes to see them here"
        }
    }
    
    private var notesList: some View {
        List {
            ForEach(filteredVerses, id: \.id) { savedVerse in
                SavedNoteRow(
                    savedVerse: savedVerse,
                    settingsStore: settingsStore,
                    router: router
                )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Saved Note Row

struct SavedNoteRow: View {
    let savedVerse: SavedVerse
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var noteStore = NoteStore.shared
    @ObservedObject var router: AppRouter
    @State private var showDeleteConfirmation = false
    @State private var verseText: String? = nil
    @State private var isLoadingVerse = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button(action: {
            navigateToVerse()
        }) {
        VStack(alignment: .leading, spacing: 12) {
                // Verse reference (localized based on primary language)
            HStack {
                    Text(localizedVerseReference)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(AppTheme.accentColor)
                
                Spacer()
                    
                    HStack(spacing: 8) {
                        // Navigate indicator
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.accentColor.opacity(0.6))
                
                // Delete button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Verse text snippet (if available)
            if isLoadingVerse {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant" ? "載入中..." : "Loading...")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            } else if let verseText = verseText {
                Text(verseText)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(3)
            }
            
            // Note content
            if !savedVerse.content.isEmpty {
                Text(savedVerse.content)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .italic()
                    .padding(.top, 4)
            }
            
            // Labels
            if !savedVerse.labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(savedVerse.labels, id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accentColor.opacity(0.2))
                                .foregroundColor(AppTheme.accentColor)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Timestamp
            Text(formatDate(savedVerse.timestamp))
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding()
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                noteStore.deleteVerse(
                    book: savedVerse.book,
                    chapter: savedVerse.chapter,
                    verse: savedVerse.verse
                )
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
        .onAppear {
            loadVerseText()
        }
    }
    
    private func loadVerseText() {
        guard verseText == nil && !isLoadingVerse else { return }
        
        isLoadingVerse = true
        
        Task {
            do {
                let verses = try await BibleService.shared.loadVerses(
                    book: savedVerse.book,
                    chapter: savedVerse.chapter,
                    translation: settingsStore.primaryLanguage
                )
                
                if let verse = verses.first(where: { $0.verseNumber == savedVerse.verse }) {
                    await MainActor.run {
                        verseText = verse.text(for: settingsStore.primaryLanguage)
                        isLoadingVerse = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingVerse = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingVerse = false
                }
            }
        }
    }
    
    private var localizedVerseReference: String {
        // Get localized book name based on primary language
        let localizedBook = BibleData.localizedBookName(savedVerse.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func navigateToVerse() {
        // Convert book string to BibleBook object
        if let book = BibleData.book(named: savedVerse.book) {
            router.navigateToReading(book: book, chapter: savedVerse.chapter, verse: savedVerse.verse)
            dismiss()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .serif))
                .foregroundColor(isSelected ? .white : AppTheme.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AppTheme.accentColor : Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.accentColor, lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationStack {
        SavedNotesListView(
            noteStore: NoteStore.shared,
            settingsStore: SettingsStore.shared
        )
    }
}


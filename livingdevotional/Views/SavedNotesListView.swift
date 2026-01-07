// SavedNotesListView - Displays saved verses with filtering by labels

import SwiftUI

struct SavedNotesListView: View {
    @ObservedObject var noteStore: NoteStore
    @ObservedObject var settingsStore: SettingsStore
    @EnvironmentObject var router: AppRouter
    @State private var selectedLabel: String?
    @State private var navigationPath = NavigationPath()
    
    var filteredVerses: [SavedVerse] {
        noteStore.getVersesFilteredByLabel(selectedLabel)
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
        .navigationTitle("Saved Notes")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - View Components
    
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
            Image(systemName: "bookmark")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.secondaryText)
            
            Text(selectedLabel == nil ? "No saved verses" : "No verses with this label")
                .font(.headline)
                .foregroundColor(AppTheme.secondaryText)
            
            Text("Save verses while reading to see them here")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
    
    var body: some View {
        Button(action: {
            navigateToVerse()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Verse reference (localized based on primary language)
                HStack {
                    Text(localizedVerseReference)
                        .font(.headline)
                        .foregroundColor(AppTheme.accentColor)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Navigate indicator
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
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
                
                // Verse text (if available)
                if let verseText = getVerseText() {
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
    }
    
    private func getVerseText() -> String? {
        // Try to get verse text from BibleService
        // For now, return nil - could be enhanced to load actual verse text
        return nil
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
            router.navigateToReading(book: book, chapter: savedVerse.chapter)
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
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
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


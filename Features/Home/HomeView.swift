// HomeView - Main home screen
// Placeholder for future home page implementation

import SwiftUI

struct HomeView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var noteStore = NoteStore.shared
    @State private var showSavedNotes = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Verse of the day
                    verseOfTheDaySection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Saved notes preview
                    savedNotesPreviewSection
                }
                .padding()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSavedNotes) {
            NavigationStack {
                SavedNotesListView(
                    noteStore: noteStore,
                    settingsStore: SettingsStore.shared
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Text("Start your daily devotional journey")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var verseOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verse of the Day")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            // TODO: Load verse of the day
            Text("Coming soon...")
                .foregroundColor(AppTheme.secondaryText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: 12) {
                quickActionButton(title: "My Notes", icon: "bookmark.fill") {
                    showSavedNotes = true
                }
            }
        }
    }
    
    private var savedNotesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Notes")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showSavedNotes = true
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.accentColor)
            }
            
            if noteStore.savedVerses.isEmpty {
                Text("No saved verses yet")
                    .foregroundColor(AppTheme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(noteStore.savedVerses.prefix(3)), id: \.id) { savedVerse in
                        SavedNotePreviewRow(savedVerse: savedVerse)
                    }
                    
                    if noteStore.savedVerses.count > 3 {
                        Button(action: {
                            showSavedNotes = true
                        }) {
                            Text("View \(noteStore.savedVerses.count - 3) more...")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
    
    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGradient)
            .cornerRadius(12)
        }
    }
}

// MARK: - Saved Note Preview Row

struct SavedNotePreviewRow: View {
    let savedVerse: SavedVerse
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bookmark.fill")
                .font(.caption)
                .foregroundColor(AppTheme.accentColor)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(savedVerse.verseReference)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryText)
                
                if !savedVerse.content.isEmpty {
                    Text(savedVerse.content)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}


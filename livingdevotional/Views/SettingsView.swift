// SettingsView - Language preferences and app settings

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showSavedNotes = false
    @State private var showChatHistory = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            Form {
                Section(header: 
                    Text("App Language")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker("App Language", selection: $settingsStore.appLanguage) {
                        ForEach(AppLanguage.allCases) { appLanguage in
                            Text(appLanguage.displayName).tag(appLanguage)
                        }
                    }
                    .tint(AppTheme.accentColor)
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text("Bible Translation")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker("Primary Translation", selection: $settingsStore.primaryLanguage) {
                        ForEach(Language.allCases.filter { $0 != .none }) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Picker("Secondary Translation", selection: $settingsStore.secondaryLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text("Saved Notes")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Button(action: {
                        showSavedNotes = true
                    }) {
                        HStack {
                            Text("My Saved Verses")
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            if !noteStore.savedVerses.isEmpty {
                                Text("\(noteStore.savedVerses.count)")
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Button(action: {
                        showChatHistory = true
                    }) {
                        HStack {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "AI 問答記錄" : "AI Q&A History")
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text("About")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    HStack {
                        Text("Version")
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSavedNotes) {
            NavigationStack {
                SavedNotesListView(
                    noteStore: noteStore,
                    settingsStore: settingsStore
                )
                .environmentObject(router)
            }
        }
        .sheet(isPresented: $showChatHistory) {
            NavigationStack {
                ChatHistoryView()
                    .environmentObject(router)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}


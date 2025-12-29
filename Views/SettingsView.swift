// SettingsView - Language preferences and app settings

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore = SettingsStore.shared
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            Form {
                Section(header: 
                    Text("Language Settings")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker("Primary Language", selection: $settingsStore.primaryLanguage) {
                        ForEach(Language.allCases.filter { $0 != .none }) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Picker("Secondary Language", selection: $settingsStore.secondaryLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
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
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}


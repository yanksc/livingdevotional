// ReadingSettingsView.swift
// Settings sheet for font size, line spacing, and translation preferences

import SwiftUI

struct ReadingSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(settingsStore.appLanguage.localizedString("BibleTranslation"))) {
                    Picker(settingsStore.appLanguage.localizedString("PrimaryTranslation"), selection: $settingsStore.primaryLanguage) {
                        ForEach(Language.allCases.filter { $0 != .none }) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Picker(settingsStore.appLanguage.localizedString("SecondaryTranslation"), selection: $settingsStore.secondaryLanguage) {
                        ForEach(Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    
                    Toggle(settingsStore.appLanguage.localizedString("ShowSecondLanguage"), isOn: $settingsStore.showSecondaryLanguage)
                        .tint(AppTheme.accentColor)
                }
                
                Section(header: Text(settingsStore.appLanguage.localizedString("FontSize"))) {
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Slider(value: $settingsStore.fontSize, in: 12...24, step: 1)
                        Image(systemName: "textformat.size.larger")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("\(Int(settingsStore.fontSize))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
                Section(header: Text(settingsStore.appLanguage.localizedString("LineSpacing"))) {
                    HStack {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Slider(value: $settingsStore.lineSpacing, in: 0...16, step: 2)
                        Image(systemName: "arrow.up.and.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text("\(Int(settingsStore.lineSpacing))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
                
            }
            .navigationTitle(settingsStore.appLanguage.localizedString("ReadingSettings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsStore.appLanguage.localizedString("Done")) {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

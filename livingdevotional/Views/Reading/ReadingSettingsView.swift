// ReadingSettingsView.swift
// Settings sheet for font size, line spacing, and translation preferences

import SwiftUI

struct ReadingSettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @EnvironmentObject var router: AppRouter
    
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
                
                // App Settings shortcut
                Section {
                    Button {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            router.showSettings = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentColor.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Text(profileInitial)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settingsStore.appLanguage.localizedString("Settings"))
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                Text(profileSubtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.secondaryText)
                        }
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
    
    private var profileInitial: String {
        let name = profileStore.profile.name
        return name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }
    
    private var profileSubtitle: String {
        let name = profileStore.profile.name
        let isChinese = settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
        if name.isEmpty {
            return isChinese ? "個人資料與通知" : "Profile & notifications"
        }
        return isChinese ? "\(name) · 個人資料與通知" : "\(name) · Profile & notifications"
    }
}

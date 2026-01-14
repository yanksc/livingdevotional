// SettingsView - Language preferences and app settings

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showSavedNotes = false
    @State private var showChatHistory = false
    @State private var showProfileEditor = false
    @State private var showMemoryInfo = false
    
    // Helper to determine if Chinese should be shown (handles .system case)
    private var isChinese: Bool {
        switch settingsStore.appLanguage {
        case .chineseTraditional:
            return true
        case .english:
            return false
        case .system:
            // Resolve system language to check if it's Chinese
            return settingsStore.appLanguage.resolvedLanguageCode().hasPrefix("zh")
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            Form {
                Section(header: 
                    Text(isChinese ? "應用程式語言" : "App Language")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker(isChinese ? "應用程式語言" : "App Language", selection: $settingsStore.appLanguage) {
                        ForEach(AppLanguage.allCases) { appLanguage in
                            Text(appLanguage.displayName).tag(appLanguage)
                        }
                    }
                    .tint(AppTheme.accentColor)
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "通知設定" : "Notifications")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Toggle(
                        isChinese ? "啟用通知" : "Enable Notifications",
                        isOn: $settingsStore.notificationsEnabled
                    )
                    .tint(AppTheme.accentColor)
                    .onChange(of: settingsStore.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let granted = await NotificationManager.shared.requestPermission()
                                if granted {
                                    NotificationManager.shared.scheduleAllNotifications()
                                } else {
                                    // User denied permission, disable toggle
                                    await MainActor.run {
                                        settingsStore.notificationsEnabled = false
                                    }
                                }
                            }
                        } else {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        }
                    }
                    
                    if settingsStore.notificationsEnabled {
                        DatePicker(
                            isChinese ? "早晨靈修提醒" : "Morning Devotional",
                            selection: $settingsStore.morningTime,
                            displayedComponents: .hourAndMinute
                        )
                        .tint(AppTheme.accentColor)
                        .onChange(of: settingsStore.morningTime) { _, _ in
                            NotificationManager.shared.refreshNotifications()
                        }
                        
                        DatePicker(
                            isChinese ? "禱告提醒" : "Prayer Reminder",
                            selection: $settingsStore.eveningTime,
                            displayedComponents: .hourAndMinute
                        )
                        .tint(AppTheme.accentColor)
                        .onChange(of: settingsStore.eveningTime) { _, _ in
                            NotificationManager.shared.refreshNotifications()
                        }
                        
                        Toggle(
                            isChinese ? "連續紀錄提醒" : "Streak Alerts",
                            isOn: $settingsStore.streakProtectionEnabled
                        )
                        .tint(AppTheme.accentColor)
                        .onChange(of: settingsStore.streakProtectionEnabled) { _, _ in
                            NotificationManager.shared.refreshNotifications()
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "我的屬靈檔案" : "My Spiritual Profile")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Button(action: {
                        showProfileEditor = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profileStore.profile.name.isEmpty ? (isChinese ? "未設定" : "Not Set") : profileStore.profile.name)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.primaryText)
                                Text(isChinese ? 
                                     profileStore.profile.spiritualMaturity.displayNameChinese : 
                                     profileStore.profile.spiritualMaturity.displayName)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Picker(
                        isChinese ? "屬靈夥伴風格" : "Spiritual Companion Style",
                        selection: $profileStore.profile.companionStyle
                    ) {
                        ForEach(AICompanionStyle.allCases) { style in
                            Text(isChinese ? style.displayNameChinese : style.displayName)
                                .tag(style)
                        }
                    }
                    .tint(AppTheme.accentColor)
                    .onChange(of: profileStore.profile.companionStyle) { _, _ in
                        // Profile is auto-saved via @Published
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "資料與記憶" : "Data & Memory")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Button(action: {
                        showMemoryInfo = true
                    }) {
                        HStack {
                            Text(isChinese ? "屬靈夥伴知道什麼" : "What Your Companion Knows")
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    
                    Button(action: {
                        ChatStore.shared.sessions.removeAll()
                    }) {
                        HStack {
                            Text(isChinese ? "清除聊天記錄" : "Clear Chat History")
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        profileStore.resetOnboarding()
                    }) {
                        HStack {
                            Text(isChinese ? "重置個人檔案" : "Reset Profile")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "已儲存的筆記" : "Saved Notes")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Button(action: {
                        showSavedNotes = true
                    }) {
                        HStack {
                            Text(isChinese ? "我的儲存經文" : "My Saved Verses")
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
                            Text(isChinese ? "問答記錄" : "Q&A History")
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
                    Text(isChinese ? "關於" : "About")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    HStack {
                        Text(isChinese ? "版本" : "Version")
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
        .navigationTitle(isChinese ? "設定" : "Settings")
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
        .sheet(isPresented: $showProfileEditor) {
            NavigationStack {
                ProfileEditorView()
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showMemoryInfo) {
            NavigationStack {
                MemoryInfoView()
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


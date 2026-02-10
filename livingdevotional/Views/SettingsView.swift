// SettingsView - Language preferences and app settings

import SwiftUI

// MARK: - Helper Components

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .cardStyle()
        .padding(.horizontal, 20)
    }
}

struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.accentColor)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    
    init(icon: String, title: String, isOn: Binding<Bool>, onChange: ((Bool) -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(AppTheme.accentColor)
                .labelsHidden()
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let badge: String?
    let action: () -> Void
    
    init(icon: String, title: String, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.trailing, 8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct SettingsCenteredNavigationRow: View {
    let icon: String
    let title: String
    let badge: String?
    let action: () -> Void
    
    init(icon: String, title: String, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 24)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.trailing, 8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let titleColor: Color
    let action: () -> Void
    
    init(icon: String, title: String, titleColor: Color = AppTheme.primaryText, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(titleColor == .red ? .red : AppTheme.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(titleColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct SettingsPickerRow<T: Hashable & Identifiable>: View {
    let icon: String
    let title: String
    let selection: Binding<T>
    let options: [T]
    let displayName: (T) -> String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            Picker("", selection: selection) {
                ForEach(options) { option in
                    Text(displayName(option))
                        .tag(option)
                }
            }
            .tint(AppTheme.accentColor)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct SettingsProfileRow: View {
    let name: String
    let maturity: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Not Set" : name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(maturity)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Main Settings View

struct SettingsView: View {
    @ObservedObject var settingsStore = SettingsStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var prayerLogStore = PrayerLogStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showSavedNotes = false
    @State private var showChatHistory = false
    @State private var showProfileEditor = false
    @State private var showReadingHistory = false
    @State private var showPrayerHistory = false
    @State private var isRefreshingVerse = false
    @State private var showVerseRefreshedAlert = false
    
    // MARK: - Computed Properties
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
    }
    
    // MARK: - Helper Functions
    
    private func localizedBookName(_ name: String) -> String {
        let chineseNames: [String: String] = [
            "Psalms": "詩篇",
            "Matthew": "馬太福音",
            "Philippians": "腓立比書",
            "John": "約翰福音",
            "Romans": "羅馬書",
            "Proverbs": "箴言",
            "Genesis": "創世記",
            "Exodus": "出埃及記",
            "Isaiah": "以賽亞書",
            "Jeremiah": "耶利米書",
            "Luke": "路加福音",
            "Mark": "馬可福音",
            "Acts": "使徒行傳",
            "Revelation": "啟示錄"
        ]
        
        if isChinese, let chinese = chineseNames[name] {
            return chinese
        }
        return name
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Language Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("AppLanguage"),
                        icon: "character"
                    )
                    
                    SettingsCard {
                        SettingsPickerRow(
                            icon: "textformat",
                            title: settingsStore.appLanguage.localizedString("AppLanguage"),
                            selection: $settingsStore.appLanguage,
                            options: Array(AppLanguage.allCases)
                        ) { language in
                            language.displayName
                        }
                    }
                    
                    // Bible Translation Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("BibleTranslation"),
                        icon: "book"
                    )
                    
                    SettingsCard {
                        SettingsPickerRow(
                            icon: "1.circle",
                            title: settingsStore.appLanguage.localizedString("PrimaryTranslation"),
                            selection: $settingsStore.primaryLanguage,
                            options: Language.allCases.filter { $0 != .none }
                        ) { language in
                            language.displayName
                        }
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsToggleRow(
                            icon: "rectangle.on.rectangle",
                            title: settingsStore.appLanguage.localizedString("ShowSecondLanguage"),
                            isOn: $settingsStore.showSecondaryLanguage
                        )
                        
                        if settingsStore.showSecondaryLanguage {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            SettingsPickerRow(
                                icon: "2.circle",
                                title: settingsStore.appLanguage.localizedString("SecondaryTranslation"),
                                selection: $settingsStore.secondaryLanguage,
                                options: Language.allCases.filter { $0 != .none && $0 != settingsStore.primaryLanguage }
                            ) { language in
                                language.displayName
                            }
                        }
                    }
                    
                    // Profile Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("Profile"),
                        icon: "person.crop.circle"
                    )
                    
                    SettingsCard {
                        // Name and Spiritual Journey
                        SettingsProfileRow(
                            name: profileStore.profile.name.isEmpty ? settingsStore.appLanguage.localizedString("NotSet") : profileStore.profile.name,
                            maturity: profileStore.profile.spiritualMaturity.localizedDisplayName(for: settingsStore.appLanguage),
                            action: {
                                showProfileEditor = true
                            }
                        )
                        
                        // Saved Onboarding Verse (from Step 6)
                        if let savedVerse = profileStore.profile.savedOnboardingVerse {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isChinese ? "收藏的經文" : "Saved Verse")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(savedVerse.reference)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(savedVerse.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        // Recommended Books (from Step 7)
                        if let books = profileStore.profile.recommendedBooks, !books.isEmpty {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "books.vertical")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isChinese ? "推薦書卷" : "Recommended Books")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(books.map { localizedBookName($0.bookName) }.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.primaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        // Personal Reflection (from Step 4)
                        if let reflection = profileStore.profile.personalReflection, !reflection.isEmpty {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "text.quote")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isChinese ? "心裡的話" : "Your Reflection")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(reflection)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.primaryText)
                                        .lineLimit(2)
                                        .italic()
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsActionRow(
                            icon: "arrow.counterclockwise",
                            title: settingsStore.appLanguage.localizedString("ResetProfile"),
                            titleColor: .red,
                            action: {
                                profileStore.resetOnboarding()
                            }
                        )
                    }
                    
                    // History & My Notes Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("HistoryAndMyNotes"),
                        icon: "bookmark"
                    )
                    
                    SettingsCard {
                        SettingsNavigationRow(
                            icon: "clock.arrow.circlepath",
                            title: settingsStore.appLanguage.localizedString("ReadingHistory"),
                            action: {
                                showReadingHistory = true
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsActionRow(
                            icon: "trash",
                            title: settingsStore.appLanguage.localizedString("ClearChatHistory"),
                            action: {
                                ChatStore.shared.sessions.removeAll()
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsNavigationRow(
                            icon: "book.fill",
                            title: settingsStore.appLanguage.localizedString("MyNotes"),
                            badge: noteStore.savedVerses.isEmpty ? nil : "\(noteStore.savedVerses.count)",
                            action: {
                                showSavedNotes = true
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsNavigationRow(
                            icon: "bubble.left.and.bubble.right",
                            title: settingsStore.appLanguage.localizedString("QAHistory"),
                            action: {
                                showChatHistory = true
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        SettingsNavigationRow(
                            icon: "hands.sparkles.fill",
                            title: settingsStore.appLanguage.localizedString("PrayerRecords"),
                            badge: prayerLogStore.logs.isEmpty ? nil : "\(prayerLogStore.logs.count)",
                            action: {
                                showPrayerHistory = true
                            }
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Refresh Verse of the Day
                        Button(action: {
                            refreshVerseOfTheDay()
                        }) {
                            HStack(spacing: 16) {
                                if isRefreshingVerse {
                                    ProgressView()
                                        .frame(width: 24)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 24)
                                }
                                
                                Text(settingsStore.appLanguage == .chineseTraditional ? "重新生成今日經文" :
                                     settingsStore.appLanguage == .chineseSimplified ? "重新生成今日经文" :
                                     "Refresh Verse of the Day")
                                    .font(.system(size: 16))
                                    .foregroundColor(isRefreshingVerse ? AppTheme.secondaryText : AppTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .disabled(isRefreshingVerse)
                    }
                    
                    // Notifications Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("Notifications"),
                        icon: "bell"
                    )
                    
                    SettingsCard {
                        SettingsToggleRow(
                            icon: "bell.badge",
                            title: settingsStore.appLanguage.localizedString("EnableNotifications"),
                            isOn: $settingsStore.notificationsEnabled
                        ) { enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationManager.shared.requestPermission()
                                    if granted {
                                        NotificationManager.shared.scheduleAllNotifications()
                                    } else {
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
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "sunrise")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                Text(settingsStore.appLanguage.localizedString("MorningDevotional"))
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                DatePicker(
                                    "",
                                    selection: $settingsStore.morningTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(AppTheme.accentColor)
                                .labelsHidden()
                                .onChange(of: settingsStore.morningTime) { _, _ in
                                    NotificationManager.shared.refreshNotifications()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "moon.stars")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                Text(settingsStore.appLanguage.localizedString("PrayerReminder"))
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                DatePicker(
                                    "",
                                    selection: $settingsStore.eveningTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(AppTheme.accentColor)
                                .labelsHidden()
                                .onChange(of: settingsStore.eveningTime) { _, _ in
                                    NotificationManager.shared.refreshNotifications()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            SettingsToggleRow(
                                icon: "cross",
                                title: settingsStore.appLanguage.localizedString("StreakAlerts"),
                                isOn: $settingsStore.streakProtectionEnabled
                            ) { _ in
                                NotificationManager.shared.refreshNotifications()
                            }
                        }
                    }
                    
                    // About Section
                    SettingsSectionHeader(
                        title: settingsStore.appLanguage.localizedString("About"),
                        icon: "info.circle.fill"
                    )
                    
                    SettingsCard {
                        HStack(spacing: 16) {
                            Image(systemName: "app.badge")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.accentColor)
                                .frame(width: 24)
                            
                            Text(settingsStore.appLanguage.localizedString("Version"))
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Spacer()
                            
                            Text("1.0.0")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    // Bottom padding
                    Spacer()
                        .frame(height: 32)
                }
            }
        }
        .navigationTitle(settingsStore.appLanguage.localizedString("Settings"))
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
        .sheet(isPresented: $showReadingHistory) {
            NavigationStack {
                ReadingHistoryView()
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showPrayerHistory) {
            NavigationStack {
                PrayerHistoryView()
                    .environmentObject(router)
            }
        }
        .alert(
            settingsStore.appLanguage == .chineseTraditional ? "今日經文已更新" :
            settingsStore.appLanguage == .chineseSimplified ? "今日经文已更新" :
            "Verse Updated",
            isPresented: $showVerseRefreshedAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(settingsStore.appLanguage == .chineseTraditional ? "返回首頁查看新的經文" :
                 settingsStore.appLanguage == .chineseSimplified ? "返回首页查看新的经文" :
                 "Return to Today to see your new verse")
        }
    }
    
    private func refreshVerseOfTheDay() {
        isRefreshingVerse = true
        Task {
            do {
                _ = try await DailyVerseService.shared.forceRefreshVerseOfTheDay()
                await MainActor.run {
                    isRefreshingVerse = false
                    showVerseRefreshedAlert = true
                    // Post notification so HomeView can reload
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshVerseOfTheDay"), object: nil)
                }
            } catch {
                await MainActor.run {
                    isRefreshingVerse = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}


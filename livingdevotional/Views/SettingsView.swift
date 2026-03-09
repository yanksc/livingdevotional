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
    let compactDisplayName: ((T) -> String)?
    
    init(
        icon: String,
        title: String,
        selection: Binding<T>,
        options: [T],
        compactDisplayName: ((T) -> String)? = nil,
        displayName: @escaping (T) -> String
    ) {
        self.icon = icon
        self.title = title
        self.selection = selection
        self.options = options
        self.compactDisplayName = compactDisplayName
        self.displayName = displayName
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
            
            if let compactDisplayName {
                Menu {
                    ForEach(options) { option in
                        Button {
                            selection.wrappedValue = option
                        } label: {
                            HStack {
                                Text(displayName(option))
                                if selection.wrappedValue == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(compactDisplayName(selection.wrappedValue))
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.accentColor)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            } else {
                Picker("", selection: selection) {
                    ForEach(options) { option in
                        Text(displayName(option))
                            .tag(option)
                    }
                }
                .tint(AppTheme.accentColor)
                .labelsHidden()
            }
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
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var supporterService = SupporterService.shared
    @EnvironmentObject var router: AppRouter
    @State private var showProfileEditor = false
    @State private var showSupporterPaywall = false
    @State private var restoreMessage: String?
    @State private var isRestoring = false
    
    // MARK: - Computed Properties
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || settingsStore.appLanguage == .chineseSimplified
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Settings title
                    Text(settingsStore.appLanguage.localizedString("Settings"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    
                    // Supporter Section
                    if supporterService.isSupporter {
                        SettingsSectionHeader(
                            title: settingsStore.appLanguage.localizedString("SupporterActive"),
                            icon: "heart.fill"
                        )
                        
                        SettingsCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentColor.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AppTheme.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(settingsStore.appLanguage.localizedString("SupporterActive"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text(settingsStore.appLanguage.localizedString("ThankYouSupport"))
                                        .font(.system(size: 13))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    } else {
                        SettingsSectionHeader(
                            title: settingsStore.appLanguage.localizedString("BecomeSupporter"),
                            icon: "heart.circle"
                        )
                        
                        SettingsCard {
                            Button(action: { showSupporterPaywall = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accentColor.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "heart.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.accentColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(settingsStore.appLanguage.localizedString("BecomeSupporter"))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(settingsStore.appLanguage.localizedString("UnlockAllFeatures"))
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.accentColor)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            Button(action: restorePurchases) {
                                HStack(spacing: 16) {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 24)
                                    
                                    if isRestoring {
                                        ProgressView()
                                            .tint(AppTheme.accentColor)
                                        Text(settingsStore.appLanguage.localizedString("Restoring"))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.primaryText)
                                    } else {
                                        Text(settingsStore.appLanguage.localizedString("RestorePurchases"))
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.primaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            .disabled(isRestoring)
                            
                            if let message = restoreMessage {
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                HStack {
                                    Text(message)
                                        .font(.system(size: 13))
                                        .foregroundColor(message.contains("✓") ? AppTheme.accentColor : .red)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
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
                            options: Language.allCases.filter { $0 != .none },
                            compactDisplayName: { $0.compactDisplayName }
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
                                options: Language.allCases.filter { $0 != .none && $0 != settingsStore.primaryLanguage },
                                compactDisplayName: { $0.compactDisplayName }
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
                        // Name and Spiritual Journey (Step 1 & 3)
                        SettingsProfileRow(
                            name: profileStore.profile.name.isEmpty ? settingsStore.appLanguage.localizedString("NotSet") : profileStore.profile.name,
                            maturity: profileStore.profile.spiritualMaturity.localizedDisplayName(for: settingsStore.appLanguage),
                            action: {
                                showProfileEditor = true
                            }
                        )
                        
                        // Personal Reflection (Step 4)
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
                        
                        // Saved Onboarding Verse (Step 5)
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
                        
                        // Relationship with God (Step 6)
                        if let desire = profileStore.profile.relationshipDesire {
                            Divider()
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 16) {
                                Image(systemName: "hands.sparkles")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isChinese ? "與神的關係" : "Seeking in Faith")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                    Text(desire.localizedDisplayName(for: settingsStore.appLanguage))
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.primaryText)
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
                    
                    #if DEBUG
                    // Debug: Simulate supporter (for testing without a real purchase)
                    SettingsSectionHeader(title: "Debug", icon: "ladybug")
                    SettingsCard {
                        SettingsToggleRow(
                            icon: "heart.circle",
                            title: "Simulate supporter (testing)",
                            isOn: Binding(
                                get: { SupporterService.simulateSupporterFromDefaults },
                                set: { supporterService.setSimulateSupporter($0) }
                            )
                        )
                    }
                    #endif
                    
                    // Bottom padding
                    Spacer()
                        .frame(height: 32)
                }
            }
        }
        .sheet(isPresented: $showProfileEditor) {
            NavigationStack {
                ProfileEditorView()
                    .environmentObject(router)
            }
        }
        .sheet(isPresented: $showSupporterPaywall) {
            SupporterFullPaywallView(
                contextualHeader: nil,
                onDismiss: {
                    showSupporterPaywall = false
                }
            )
        }
        .onAppear {
            Task {
                await supporterService.refreshStatus()
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    private func restorePurchases() {
        restoreMessage = nil
        isRestoring = true
        
        Task {
            do {
                let customerInfo = try await supporterService.restorePurchases()
                await MainActor.run {
                    isRestoring = false
                    if customerInfo.entitlements[SupporterIdentifiers.entitlementId]?.isActive == true {
                        restoreMessage = isChinese ? "✓ 已恢復" : "✓ Restored successfully"
                    } else {
                        restoreMessage = isChinese ? "沒有找到可恢復的購買" : "No purchases to restore"
                    }
                }
                
                // Clear message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    restoreMessage = nil
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    restoreMessage = isChinese ? "恢復失敗" : "Restore failed"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    restoreMessage = nil
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


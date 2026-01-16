// OnboardingView - Multi-step onboarding flow for user personalization

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var currentStep = 0
    @State private var name: String = ""
    @State private var selectedMaturity: SpiritualMaturity = .growing
    @State private var selectedGoals: Set<SpiritualGoal> = []
    @State private var selectedTradition: ChristianTradition = .nondenominational
    @State private var selectedPrimaryLanguage: Language
    @State private var selectedSecondaryLanguage: Language
    @State private var notificationsEnabled: Bool = true
    @State private var morningTime: Date = {
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var eveningTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private let totalSteps = 5
    
    init() {
        let store = SettingsStore.shared
        _selectedPrimaryLanguage = State(initialValue: store.primaryLanguage)
        _selectedSecondaryLanguage = State(initialValue: store.secondaryLanguage)
    }
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !selectedGoals.isEmpty
        default: return true
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                TabView(selection: $currentStep) {
                    step1Welcome.tag(0)
                    step2Journey.tag(1)
                    step3Goals.tag(2)
                    step4Tradition.tag(3)
                    step5Companion.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .allowsHitTesting(true) // Allow touches inside TabView
                
                navigationButtons
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(isChinese ? "上一步" : "Back") {
                    withAnimation { currentStep -= 1 }
                }
                .foregroundColor(AppTheme.primaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            Button(action: {
                if currentStep < totalSteps - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    completeOnboarding()
                }
            }) {
                let buttonText = currentStep == totalSteps - 1 ? (isChinese ? "開始旅程" : "Start Journey") : (isChinese ? "下一步" : "Next")
                Text(buttonText)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(10)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Step 1: Welcome & Language
    
    private var step1Welcome: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(isChinese ? "歡迎" : "Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.top, 40)
                
                Text(isChinese ? "讓我們開始您的靈修之旅" : "Let's start your devotional journey")
                    .font(.title3)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(isChinese ? "您的名字" : "Your Name")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    TextField(isChinese ? "輸入您的名字" : "Enter your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                    
                    Text(isChinese ? "您的名字幫助我們個人化禱告和訊息。" : "Your name helps us personalize prayers and messages.")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(isChinese ? "應用程式語言" : "App Language")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Picker("", selection: $settingsStore.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 2: Spiritual Journey
    
    private var step2Journey: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    title: isChinese ? "您的屬靈旅程" : "Your Spiritual Journey",
                    subtitle: isChinese ? "您在屬靈旅程的哪個階段？" : "Where are you on your spiritual journey?",
                    caption: isChinese ? "這幫助我們調整解釋的深度和語調。" : "This helps us adjust the depth and tone of explanations."
                )
                
                VStack(spacing: 12) {
                    ForEach(SpiritualMaturity.allCases) { maturity in
                        SelectionButton(
                            title: isChinese ? maturity.displayNameChinese : maturity.displayName,
                            isSelected: selectedMaturity == maturity
                        ) {
                            selectedMaturity = maturity
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 3: Goals
    
    private var step3Goals: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    title: isChinese ? "您的目標" : "Your Goals",
                    subtitle: isChinese ? "是什麼帶您來到這裡？" : "What brings you here?",
                    caption: isChinese ? "我們會突出顯示符合您屬靈焦點的內容。" : "We'll highlight content that matches your spiritual focus."
                )
                
                VStack(spacing: 12) {
                    ForEach(SpiritualGoal.allCases) { goal in
                        SelectionButton(
                            title: isChinese ? goal.displayNameChinese : goal.displayName,
                            isSelected: selectedGoals.contains(goal)
                        ) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 4: Tradition
    
    private var step4Tradition: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    title: isChinese ? "教會背景" : "Church Background",
                    subtitle: isChinese ? "您有特定的教會背景嗎？" : "Do you have a specific church background?",
                    caption: isChinese ? "我們尊重不同的傳統，並相應地調整見解。" : "We respect different traditions and tailor insights accordingly."
                )
                
                VStack(spacing: 12) {
                    ForEach(ChristianTradition.allCases) { tradition in
                        SelectionButton(
                            title: isChinese ? tradition.displayNameChinese : tradition.displayName,
                            isSelected: selectedTradition == tradition
                        ) {
                            selectedTradition = tradition
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Step 5: Settings
    
    private var step5Companion: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    title: isChinese ? "設定" : "Settings",
                    subtitle: isChinese ? "完成您的個人化設定" : "Complete your personalization",
                    caption: isChinese ? "選擇您的聖經譯本和通知偏好。" : "Choose your Bible translations and notification preferences."
                )
                
                bibleTranslationSection
                notificationSection
            }
            .padding(.bottom, 100)
        }
    }
    
    private var bibleTranslationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isChinese ? "聖經譯本" : "Bible Translation")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            Picker(isChinese ? "主要譯本" : "Primary Translation", selection: $selectedPrimaryLanguage) {
                ForEach(Language.allCases.filter { $0 != .none }) { language in
                    Text(language.displayName).tag(language)
                }
            }
            
            Picker(isChinese ? "次要譯本" : "Secondary Translation", selection: $selectedSecondaryLanguage) {
                ForEach(Language.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isChinese ? "啟用通知" : "Enable Notifications", isOn: $notificationsEnabled)
                .tint(AppTheme.accentColor)
            
            if notificationsEnabled {
                DatePicker(isChinese ? "早晨靈修提醒" : "Morning Devotional", selection: $morningTime, displayedComponents: .hourAndMinute)
                    .tint(AppTheme.accentColor)
                
                DatePicker(isChinese ? "禱告提醒" : "Prayer Reminder", selection: $eveningTime, displayedComponents: .hourAndMinute)
                    .tint(AppTheme.accentColor)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    // MARK: - Helper Views
    
    private func stepHeader(title: String, subtitle: String, caption: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
                .padding(.top, 40)
            
            Text(subtitle)
                .font(.title3)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(caption)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Completion
    
    private func completeOnboarding() {
        profileStore.profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            spiritualMaturity: selectedMaturity,
            spiritualGoals: Array(selectedGoals),
            tradition: selectedTradition
        )
        
        settingsStore.primaryLanguage = selectedPrimaryLanguage
        settingsStore.secondaryLanguage = selectedSecondaryLanguage
        settingsStore.notificationsEnabled = notificationsEnabled
        settingsStore.morningTime = morningTime
        settingsStore.eveningTime = eveningTime
        
        if notificationsEnabled {
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    await MainActor.run {
                        NotificationManager.shared.scheduleAllNotifications()
                    }
                }
            }
        }
        
        profileStore.completeOnboarding()
    }
}

// MARK: - Reusable Selection Button

private struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(buttonBackground)
            .overlay(buttonBorder)
            .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if isSelected {
            AppTheme.buttonGradient
        } else {
            Color.clear
        }
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.clear : AppTheme.accentColor.opacity(0.3), lineWidth: 1)
    }
}

#Preview {
    OnboardingView()
}

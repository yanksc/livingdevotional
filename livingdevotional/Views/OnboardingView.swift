// OnboardingView - Multi-step onboarding flow for user personalization

import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var currentStep = 0
    @State private var name: String = ""
    @State private var selectedMaturity: SpiritualMaturity = .growing
    @State private var selectedGoals: Set<SpiritualGoal> = []
    @State private var selectedLifeFocusAreas: Set<LifeFocusArea> = []
    @State private var selectedTimeCommitment: DailyTimeCommitment = .tenMinutes
    @State private var selectedExplanationDepth: ExplanationDepth = .someBackground
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
    @State private var showPrayerStep = false
    @State private var showInterstitial = false
    @State private var step1TitleAppeared = false
    @State private var step1SubtitleAppeared = false
    @State private var step1NameFieldAppeared = false
    @State private var step2LanguageOptionsAppeared: Set<String> = []
    @State private var selectionFeedback: String? = nil
    @FocusState private var isNameFieldFocused: Bool
    
    private let totalSteps = 10
    
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
        case 3: return !selectedGoals.isEmpty // Goals step (tag 3)
        default: return true
        }
    }
    
    var body: some View {
        ZStack {
            SereneGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if !showPrayerStep && !showInterstitial {
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                        .padding(.horizontal)
                        .padding(.top, 20)
                }
                
                if showPrayerStep {
                    prayerStepView
                } else if showInterstitial {
                    interstitialView
                } else {
                    TabView(selection: $currentStep) {
                        step1Welcome.tag(0)
                        step2Language.tag(1)
                        step3Journey.tag(2)
                        step4Goals.tag(3)
                        step5Denomination.tag(4)
                        step6LifeFocus.tag(5)
                        step7TimeAvailability.tag(6)
                        step8ExplanationDepth.tag(7)
                        step9Settings.tag(8)
                        step10Placeholder.tag(9)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .allowsHitTesting(true)
                    
                    navigationButtons
                }
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(isChinese ? "上一步" : "Back") {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                }
                .foregroundColor(AppTheme.primaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            Button(action: {
                if currentStep < totalSteps - 1 {
                    if currentStep == 4 {
                        // After Denomination step (tag 4) - show interstitial
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showInterstitial = true
                        }
                    } else if currentStep == 8 {
                        // Step 9 is settings (tag 8) - request notification permission if enabled
                        handleSettingsCompletion()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
                    }
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
    
    // MARK: - Step 1: Welcome & Name
    
    private var step1Welcome: some View {
        ScrollView {
            step1Content
        }
    }
    
    private var step1Content: some View {
        VStack(spacing: 32) {
            // Welcome Title - Animated entrance
            VStack(spacing: 12) {
                Text(isChinese ? "歡迎" : "Welcome")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                    .opacity(step1TitleAppeared ? 1.0 : 0.0)
                    .offset(y: step1TitleAppeared ? 0 : -20)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            step1TitleAppeared = true
                        }
                    }
                
                Text(isChinese ? "我來陪伴您走這段路" : "Hi there. I'm here to walk alongside you.")
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(step1SubtitleAppeared ? 1.0 : 0.0)
                    .offset(y: step1SubtitleAppeared ? 0 : -10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                step1SubtitleAppeared = true
                            }
                        }
                    }
            }
            .padding(.top, 60)
            
            // Name Input Card - Beautiful card design
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accentColor)
                    Text(isChinese ? "我該怎麼稱呼您？" : "What should I call you?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                
                TextField(isChinese ? "輸入您的名字" : "Enter your name", text: $name)
                    .focused($isNameFieldFocused)
                    .font(.system(size: 18))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isNameFieldFocused ? AppTheme.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .autocapitalization(.words)
                    .submitLabel(.next)
            }
            .padding(20)
            .background(AppTheme.cardGradient)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 24)
            .opacity(step1NameFieldAppeared ? 1.0 : 0.0)
            .offset(x: step1NameFieldAppeared ? 0 : -30)
            .scaleEffect(step1NameFieldAppeared ? 1.0 : 0.95)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        step1NameFieldAppeared = true
                    }
                }
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Step 2: Language
    
    private var step2Language: some View {
        OnboardingStepView(
            title: isChinese ? "語言設定" : "Language",
            subtitle: isChinese ? "哪種語言讓您感覺最自在？" : "Which language feels like home?",
            caption: isChinese ? "您可以隨時在設定中更改。" : "You can always change this later in settings.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, lang in
                    LanguageSelectionButton(
                        language: lang,
                        isSelected: settingsStore.appLanguage == lang,
                        isChinese: isChinese,
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settingsStore.appLanguage = lang
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Step 3: Spiritual Journey
    
    private var step3Journey: some View {
        OnboardingStepView(
            title: isChinese ? "您的屬靈旅程" : "Your Spiritual Journey",
            subtitle: isChinese ? "您在屬靈旅程的哪個階段？" : "Where are you on your spiritual journey?",
            caption: isChinese ? "這幫助我們調整解釋的深度和語調。" : "This helps us adjust the depth and tone of explanations.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(SpiritualMaturity.allCases.enumerated()), id: \.element.id) { index, maturity in
                    SelectionButton(
                        title: isChinese ? maturity.displayNameChinese : maturity.displayName,
                        isSelected: selectedMaturity == maturity,
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMaturity = maturity
                            showSelectionFeedback(for: .journey)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedMaturity) { _, _ in
                // Clear feedback when selection changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Goals
    
    private var step4Goals: some View {
        OnboardingStepView(
            title: isChinese ? "您的目標" : "Your Goals",
            subtitle: isChinese ? "是什麼帶您來到這裡？" : "What brings you here?",
            caption: isChinese ? "選擇所有適用的選項。" : "Select all that apply.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(SpiritualGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    SelectionButton(
                        title: isChinese ? goal.displayNameChinese : goal.displayName,
                        isSelected: selectedGoals.contains(goal),
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                            showSelectionFeedback(for: .goals)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedGoals) { _, _ in
                // Clear feedback when selection changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 5: Denomination
    
    private var step5Denomination: some View {
        OnboardingStepView(
            title: isChinese ? "傳統背景" : "Tradition",
            subtitle: isChinese ? "哪個傳統最符合您的背景？" : "What tradition resonates with you?",
            caption: isChinese ? "這幫助我們了解您的信仰背景。" : "This helps us understand your faith background.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(ChristianTradition.allCases.enumerated()), id: \.element.id) { index, tradition in
                    SelectionButton(
                        title: isChinese ? tradition.displayNameChinese : tradition.displayName,
                        isSelected: selectedTradition == tradition,
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTradition = tradition
                            showSelectionFeedback(for: .denomination)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedTradition) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 6: Life Focus
    
    private var step6LifeFocus: some View {
        OnboardingStepView(
            title: isChinese ? "生活焦點" : "Life Focus",
            subtitle: isChinese ? "您想將哪些生活領域帶到神面前？" : "What areas of your life would you like to bring before God?",
            caption: isChinese ? "選擇所有適用的選項。" : "Select all that apply.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(LifeFocusArea.allCases.enumerated()), id: \.element.id) { index, area in
                    SelectionButton(
                        title: isChinese ? area.displayNameChinese : area.displayName,
                        isSelected: selectedLifeFocusAreas.contains(area),
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedLifeFocusAreas.contains(area) {
                                selectedLifeFocusAreas.remove(area)
                            } else {
                                selectedLifeFocusAreas.insert(area)
                            }
                            showSelectionFeedback(for: .lifeFocus)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedLifeFocusAreas) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 7: Time Availability
    
    private var step7TimeAvailability: some View {
        OnboardingStepView(
            title: isChinese ? "時間安排" : "Time Availability",
            subtitle: isChinese ? "您每天可以撥出多少時間？" : "How much time can you set aside for daily devotion?",
            caption: isChinese ? "這幫助我們調整內容長度和建議。" : "This helps us calibrate content length and suggestions.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(DailyTimeCommitment.allCases.enumerated()), id: \.element.id) { index, commitment in
                    SelectionButton(
                        title: isChinese ? commitment.displayNameChinese : commitment.displayName,
                        isSelected: selectedTimeCommitment == commitment,
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimeCommitment = commitment
                            showSelectionFeedback(for: .time)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedTimeCommitment) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 8: Explanation Depth
    
    private var step8ExplanationDepth: some View {
        OnboardingStepView(
            title: isChinese ? "解釋深度" : "Explanation Depth",
            subtitle: isChinese ? "您希望解釋的感覺如何？" : "How would you like explanations to feel?",
            caption: isChinese ? "選擇最符合您偏好的選項。" : "Choose the option that best matches your preference.",
            isChinese: isChinese
        ) { questionComplete in
            VStack(spacing: 12) {
                ForEach(Array(ExplanationDepth.allCases.enumerated()), id: \.element.id) { index, depth in
                    ExplanationDepthOptionView(
                        depth: depth,
                        isSelected: selectedExplanationDepth == depth,
                        isChinese: isChinese,
                        appLanguage: settingsStore.appLanguage,
                        animationDelay: Double(index) * 0.1,
                        shouldAnimate: questionComplete
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedExplanationDepth = depth
                            showSelectionFeedback(for: .explanation)
                        }
                    }
                }
                
                if let feedback = selectionFeedback {
                    Text(feedback)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .onChange(of: selectedExplanationDepth) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectionFeedback = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Step 9: Settings
    
    private var step9Settings: some View {
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
            Toggle(isChinese ? "啟用通知" : "Would you like daily reminders?", isOn: $notificationsEnabled)
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
    
    // MARK: - Step 10: Placeholder (will be replaced by prayer step)
    
    private var step10Placeholder: some View {
        EmptyView()
    }
    
    // MARK: - Interstitial View
    
    private var interstitialView: some View {
        InterstitialEncouragementView(
            userName: name,
            isChinese: isChinese,
            onContinue: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showInterstitial = false
                    currentStep = 5 // Move to Life Focus step (tag 5)
                }
            }
        )
    }
    
    // MARK: - Prayer Step
    
    private var prayerStepView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 24) {
                Text(isChinese ? "讓我們開始" : "Let's Begin")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(generateOpeningPrayer())
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            OnboardingAmenButton(onComplete: {
                completeOnboarding()
            })
            .padding(.bottom, 60)
        }
    }
    
    private func generateOpeningPrayer() -> String {
        let userName = name.isEmpty ? (isChinese ? "朋友" : "friend") : name
        if isChinese {
            return """
            親愛的天父，
            
            感謝您帶領\(userName)來到這裡。求您祝福這段靈修旅程，讓\(userName)在您的話語中找到平安、智慧和力量。
            
            願這個應用成為\(userName)與您親近的管道，幫助\(userName)在每日生活中活出您的愛。
            
            奉主耶穌的名禱告，阿們。
            """
        } else {
            return """
            Dear Heavenly Father,
            
            Thank you for bringing \(userName) here. Bless this devotional journey, and may \(userName) find peace, wisdom, and strength in Your Word.
            
            May this app be a pathway for \(userName) to draw near to You, and help \(userName) live out Your love in daily life.
            
            In Jesus' name, Amen.
            """
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleSettingsCompletion() {
        // Request notification permission if enabled, then proceed to prayer
        if notificationsEnabled {
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    await MainActor.run {
                        settingsStore.notificationsEnabled = true
                        settingsStore.morningTime = morningTime
                        settingsStore.eveningTime = eveningTime
                        NotificationManager.shared.scheduleAllNotifications()
                    }
                } else {
                    await MainActor.run {
                        settingsStore.notificationsEnabled = false
                    }
                }
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showPrayerStep = true
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                showPrayerStep = true
            }
        }
    }
    
    private func completeOnboarding() {
        profileStore.profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            spiritualMaturity: selectedMaturity,
            spiritualGoals: Array(selectedGoals),
            tradition: selectedTradition,
            companionStyle: .mentor, // Keep for backward compatibility
            lifeFocusAreas: Array(selectedLifeFocusAreas),
            dailyTimeCommitment: selectedTimeCommitment,
            explanationDepth: selectedExplanationDepth
        )
        
        settingsStore.primaryLanguage = selectedPrimaryLanguage
        settingsStore.secondaryLanguage = selectedSecondaryLanguage
        
        profileStore.completeOnboarding()
    }
    
    // MARK: - Helper Functions
    
    private enum FeedbackType {
        case journey
        case goals
        case denomination
        case lifeFocus
        case time
        case explanation
    }
    
    private func showSelectionFeedback(for type: FeedbackType) {
        let messages: [String]
        if isChinese {
            switch type {
            case .journey:
                messages = ["那是個美好的階段", "感謝您願意分享", "每個階段都有它的意義"]
            case .goals:
                messages = ["這些都是有意義的追求", "很好的選擇", "我們會根據這些為您推薦內容"]
            case .denomination:
                messages = ["了解您的背景很有幫助", "感謝分享"]
            case .lifeFocus:
                messages = ["這些都是重要的領域", "我們會為這些領域推薦經文"]
            case .time:
                messages = ["好的，我們會調整內容長度", "了解您的時間安排很有幫助"]
            case .explanation:
                messages = ["我們會依此調整解釋方式", "很好的選擇"]
            }
        } else {
            switch type {
            case .journey:
                messages = ["That's a beautiful place to be", "Thank you for sharing", "Every stage has its purpose"]
            case .goals:
                messages = ["Those are meaningful pursuits", "Great choices", "We'll tailor content to these"]
            case .denomination:
                messages = ["Understanding your background helps", "Thanks for sharing"]
            case .lifeFocus:
                messages = ["These are important areas", "We'll suggest verses for these"]
            case .time:
                messages = ["Good to know, we'll adjust content length", "Understanding your schedule helps"]
            case .explanation:
                messages = ["We'll adjust explanations accordingly", "Good choice"]
            }
        }
        
        withAnimation(.easeIn(duration: 0.3)) {
            selectionFeedback = messages.randomElement()
        }
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
}

// MARK: - Onboarding Step View with Typewriter Effect

private struct OnboardingStepView<Content: View>: View {
    let title: String
    let subtitle: String
    let caption: String
    let isChinese: Bool
    let content: (Bool) -> Content
    
    @State private var titleComplete = false
    @State private var subtitleComplete = false
    @State private var captionComplete = false
    @State private var displayedTitle = ""
    @State private var displayedSubtitle = ""
    @State private var displayedCaption = ""
    
    private var questionComplete: Bool {
        titleComplete && subtitleComplete && captionComplete
    }
    
    init(
        title: String,
        subtitle: String,
        caption: String,
        isChinese: Bool,
        @ViewBuilder content: @escaping (Bool) -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.caption = caption
        self.isChinese = isChinese
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated header
                VStack(spacing: 12) {
                    Text(displayedTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.top, 40)
                        .frame(minHeight: 44)
                    
                    Text(displayedSubtitle)
                        .font(.title3)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(minHeight: 28)
                    
                    Text(displayedCaption)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(minHeight: 18)
                }
                
                // Content (options) - passed questionComplete state
                content(questionComplete)
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            startTypewriterAnimation()
        }
    }
    
    private func startTypewriterAnimation() {
        // Reset states
        displayedTitle = ""
        displayedSubtitle = ""
        displayedCaption = ""
        titleComplete = false
        subtitleComplete = false
        captionComplete = false
        
        // Animate title first
        animateText(title, isChinese: isChinese, speed: 0.08) { char in
            displayedTitle += char
        } completion: {
            titleComplete = true
            // Small pause before subtitle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateText(subtitle, isChinese: isChinese, speed: 0.05) { char in
                    displayedSubtitle += char
                } completion: {
                    subtitleComplete = true
                    // Small pause before caption
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animateText(caption, isChinese: isChinese, speed: 0.04) { char in
                            displayedCaption += char
                        } completion: {
                            captionComplete = true
                        }
                    }
                }
            }
        }
    }
    
    private func animateText(_ text: String, isChinese: Bool, speed: Double, onChar: @escaping (String) -> Void, completion: @escaping () -> Void) {
        let characters = Array(text)
        var index = 0
        
        func typeNext() {
            guard index < characters.count else {
                completion()
                return
            }
            
            let char = String(characters[index])
            onChar(char)
            index += 1
            
            // Adjust speed based on character type
            var delay = speed
            if isChinese {
                // Slightly slower for Chinese characters
                delay = speed * 1.2
            }
            // Add slight pause after punctuation
            if [".", ",", "?", "!", "。", "，", "？", "！"].contains(char) {
                delay = speed * 4
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        typeNext()
    }
}

// MARK: - Explanation Depth Option View

private struct ExplanationDepthOptionView: View {
    let depth: ExplanationDepth
    let isSelected: Bool
    let isChinese: Bool
    let appLanguage: AppLanguage
    let animationDelay: Double
    let shouldAnimate: Bool
    let action: () -> Void
    
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SelectionButton(
                title: isChinese ? depth.localizedDisplayName(for: appLanguage) : depth.displayName,
                isSelected: isSelected,
                animationDelay: animationDelay,
                shouldAnimate: shouldAnimate,
                action: action
            )
            
            if hasAppeared {
                Text(isChinese ? depth.localizedDescription(for: appLanguage) : depth.displayDescription)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.leading, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: shouldAnimate) { _, newValue in
            if newValue && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasAppeared = true
                    }
                }
            }
        }
        .onAppear {
            if shouldAnimate && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }
}

// MARK: - Reusable Selection Button

private struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let animationDelay: Double
    let shouldAnimate: Bool
    @State private var hasAppeared = false
    
    init(title: String, isSelected: Bool, animationDelay: Double = 0, shouldAnimate: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.animationDelay = animationDelay
        self.shouldAnimate = shouldAnimate
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(buttonBackground)
            .overlay(buttonBorder)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(x: hasAppeared ? 0 : 30)
        .onChange(of: shouldAnimate) { _, newValue in
            if newValue && !hasAppeared {
                // Animate in with staggered delay once question is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasAppeared = true
                    }
                }
            }
        }
        .onAppear {
            // If shouldAnimate is already true on appear, start animation
            if shouldAnimate && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if isSelected {
            AppTheme.buttonGradient
        } else {
            AppTheme.cardGradient
        }
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.clear : AppTheme.accentColor.opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Amen Button

private struct OnboardingAmenButton: View {
    var onComplete: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    @State private var isHolding = false
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private let holdDuration: Double = 2.0 // 2 seconds
    private let buttonSize: CGFloat = 80
    private let progressRingWidth: CGFloat = 6
    
    var body: some View {
        ZStack {
            // Outer progress ring
            if isHolding {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.accentColor.opacity(0.9),
                                AppTheme.accentColor,
                                AppTheme.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: progressRingWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
                    .animation(.linear(duration: 0.05), value: progress)
            }
            
            // Button background
            Circle()
                .fill(
                    LinearGradient(
                        colors: isHolding ? [
                            AppTheme.accentColor.opacity(0.9),
                            AppTheme.accentColor
                        ] : [
                            AppTheme.accentColor.opacity(0.8),
                            AppTheme.accentColor.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: AppTheme.accentColor.opacity(isHolding ? 0.5 : 0.3), radius: isHolding ? 15 : 8)
                .scaleEffect(isHolding ? 1.05 : 1.0)
            
            // Button text
            Text(settingsStore.appLanguage == .chineseTraditional ? "阿們" : "Amen")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(isHolding ? 1.1 : 1.0)
        }
        .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        startHolding()
                    }
                }
                .onEnded { _ in
                    stopHolding()
                }
        )
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startHolding() {
        isHolding = true
        progress = 0.0
        
        hapticLight.prepare()
        hapticLight.impactOccurred()
        
        let startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            progress = min(elapsed / holdDuration, 1.0)
            
            if progress >= 0.5 && progress < 0.52 {
                hapticMedium.prepare()
                hapticMedium.impactOccurred()
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                completeAmen()
            }
        }
    }
    
    private func stopHolding() {
        isHolding = false
        timer?.invalidate()
        timer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0.0
        }
    }
    
    private func completeAmen() {
        notificationGenerator.notificationOccurred(.success)
        
        withAnimation(.easeOut(duration: 0.5)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

// MARK: - Language Option Button

private struct LanguageOptionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let isChinese: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.displayName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.accentColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.accentColor.opacity(0.3) : Color.black.opacity(0.03),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Language Selection Button (with animation support)

private struct LanguageSelectionButton: View {
    let language: AppLanguage
    let isSelected: Bool
    let isChinese: Bool
    let animationDelay: Double
    let shouldAnimate: Bool
    let action: () -> Void
    
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(language.displayName)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.accentColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.accentColor.opacity(0.3) : Color.black.opacity(0.03),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(x: hasAppeared ? 0 : 30)
        .onChange(of: shouldAnimate) { _, newValue in
            if newValue && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasAppeared = true
                    }
                }
            }
        }
        .onAppear {
            if shouldAnimate && !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasAppeared = true
                    }
                }
            }
        }
    }
}

// MARK: - Interstitial Encouragement View

private struct InterstitialEncouragementView: View {
    let userName: String
    let isChinese: Bool
    let onContinue: () -> Void
    
    @State private var displayedTitle = ""
    @State private var displayedSubtitle = ""
    @State private var titleComplete = false
    @State private var subtitleComplete = false
    @State private var showButton = false
    
    private var encouragementMessage: (title: String, subtitle: String) {
        let name = userName.isEmpty ? "" : userName
        let greeting = name.isEmpty ? "" : (isChinese ? "，\(name)" : ", \(name)")
        
        if isChinese {
            return (
                title: "了解您了\(greeting)",
                subtitle: "現在我們知道您的屬靈旅程和目標，\n就能為您推薦最適合的經文和禱告。\n\n再幾個問題，讓我們把體驗調整得更好。"
            )
        } else {
            return (
                title: "We're getting to know you\(greeting)",
                subtitle: "Now that we understand your journey and goals,\nwe can suggest Scripture and prayers that truly resonate.\n\nA few more questions to fine-tune your experience."
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 16) {
                // Title with typewriter effect
                Text(displayedTitle)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.primaryText)
                    .frame(minHeight: 40)
                
                // Subtitle with typewriter effect
                Text(displayedSubtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .frame(minHeight: 100)
            }
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text(isChinese ? "繼續" : "Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.buttonGradient)
                    .cornerRadius(14)
                    .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
            .opacity(showButton ? 1.0 : 0.0)
            .offset(y: showButton ? 0 : 20)
        }
        .onAppear {
            startTypewriterAnimation()
        }
    }
    
    private func startTypewriterAnimation() {
        let message = encouragementMessage
        
        // Reset states
        displayedTitle = ""
        displayedSubtitle = ""
        titleComplete = false
        subtitleComplete = false
        
        // Animate title first
        animateText(message.title, isChinese: isChinese, speed: 0.08) { char in
            displayedTitle += char
        } completion: {
            titleComplete = true
            // Pause before subtitle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateText(message.subtitle, isChinese: isChinese, speed: 0.05) { char in
                    displayedSubtitle += char
                } completion: {
                    subtitleComplete = true
                    // Show button after subtitle completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showButton = true
                        }
                    }
                }
            }
        }
    }
    
    private func animateText(_ text: String, isChinese: Bool, speed: Double, onChar: @escaping (String) -> Void, completion: @escaping () -> Void) {
        let characters = Array(text)
        var index = 0
        
        func typeNext() {
            guard index < characters.count else {
                completion()
                return
            }
            
            let char = String(characters[index])
            onChar(char)
            index += 1
            
            var delay = speed
            if isChinese {
                delay = speed * 1.2
            }
            if [".", ",", "?", "!", "。", "，", "？", "！", "\n"].contains(char) {
                delay = speed * 4
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                typeNext()
            }
        }
        
        typeNext()
    }
}

#Preview {
    OnboardingView()
}

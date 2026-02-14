// PersonalizedPlanConfigView - Multi-step flow for creating personalized reading plans

import SwiftUI

enum PlanCreationStep {
    case profileConfirmation
    case questionnaire
    case generation
    case review
}

struct PersonalizedPlanConfigView: View {
    @Environment(\.services) var services
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var planStore = ReadingPlanStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    @ObservedObject private var prayerStore = PrayerLogStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    
    private var aiService: AIService? {
        services.aiService as? AIService
    }
    
    @State private var currentStep: PlanCreationStep = .profileConfirmation
    @State private var dynamicQuestions: [AIService.PlanQuestion] = []
    @State private var answers: [String: String] = [:]
    @State private var generatedPlan: ReadingPlan?
    @State private var isLoadingQuestions = false
    @State private var isGeneratingPlan = false
    @State private var errorMessage: String?
    @State private var draftPlan: ReadingPlan?
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Content
                    Group {
                        switch currentStep {
                        case .profileConfirmation:
                            ProfileConfirmationStep(
                                profile: profileStore.profile,
                                onConfirm: { proceedToQuestionnaire() },
                                onEdit: { navigateToProfile() },
                                settingsStore: settingsStore
                            )
                        case .questionnaire:
                            QuestionnaireStep(
                                dynamicQuestions: dynamicQuestions,
                                answers: $answers,
                                isLoading: isLoadingQuestions,
                                onComplete: { generatePlan() },
                                settingsStore: settingsStore
                            )
                        case .generation:
                            GenerationLoadingStep(
                                isGenerating: isGeneratingPlan,
                                settingsStore: settingsStore
                            )
                        case .review:
                            if let plan = generatedPlan ?? draftPlan {
                                PlanReviewStep(
                                    plan: plan,
                                    onStart: { startPlan(plan) },
                                    onRegenerate: { regeneratePlan() },
                                    onCancel: { dismiss() },
                                    settingsStore: settingsStore
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(isChinese ? "創建個人化計劃" : "Create Personalized Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep != .profileConfirmation {
                        Button(isChinese ? "返回" : "Back") {
                            goBack()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep != .generation {
                        Button(isChinese ? "取消" : "Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                loadDynamicQuestions()
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(stepIndex <= index ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 16)
    }
    
    private var stepIndex: Int {
        switch currentStep {
        case .profileConfirmation: return 0
        case .questionnaire: return 1
        case .generation: return 2
        case .review: return 3
        }
    }
    
    private func proceedToQuestionnaire() {
        currentStep = .questionnaire
    }
    
    private func navigateToProfile() {
        // Navigate to profile editor - this would need router integration
        // For now, just proceed
        proceedToQuestionnaire()
    }
    
    private func loadDynamicQuestions() {
        isLoadingQuestions = true
        Task {
            do {
                guard let aiService = aiService else {
                    throw NSError(domain: "PersonalizedPlanConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service unavailable"])
                }
                let history = buildHistoryContext()
                let questions = try await aiService.generatePersonalizedPlanQuestions(
                    profile: profileStore.profile,
                    history: history,
                    appLanguage: settingsStore.appLanguage
                )
                await MainActor.run {
                    dynamicQuestions = questions
                    isLoadingQuestions = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingQuestions = false
                    // Fallback to empty questions
                    dynamicQuestions = []
                }
            }
        }
    }
    
    private func buildHistoryContext() -> AIService.UserHistoryContext? {
        // Build history from stores
        let recentNotes = noteStore.savedVerses.prefix(5).map { verse -> String in
            if !verse.content.isEmpty {
                return "\(verse.verseReference): \(verse.content.prefix(50))"
            }
            return verse.verseReference
        }
        
        let recentPrayers = prayerStore.getRecentLogs(limit: 5).map { log in
            log.customTopicText ?? log.topic
        }
        
        let recentQuestions = chatStore.sessions.prefix(5).compactMap { session -> String? in
            session.messages.first(where: { $0.role == .user })?.content
        }
        
        let readingHistory = progressStore.readingHistory.prefix(10).map { item in
            "\(item.book) \(item.chapter)"
        }
        
        let savedReferences = noteStore.savedVerses.prefix(10).map { $0.verseReference }
        
        // Only return context if there's meaningful data
        if recentNotes.isEmpty && recentPrayers.isEmpty && recentQuestions.isEmpty && readingHistory.isEmpty {
            return nil
        }
        
        return AIService.UserHistoryContext(
            recentNotes: Array(recentNotes),
            recentPrayers: recentPrayers,
            recentQuestions: recentQuestions,
            readingHistory: readingHistory,
            savedVerseReferences: savedReferences
        )
    }
    
    private func generatePlan() {
        guard UsageLimitStore.shared.canCreatePersonalizedPlan() else {
            router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("PlanLimitReached"))
            return
        }
        
        currentStep = .generation
        isGeneratingPlan = true
        
        Task {
            do {
                guard let aiService = aiService else {
                    throw NSError(domain: "PersonalizedPlanConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "AI service unavailable"])
                }
                let plan = try await aiService.generateReadingPlan(
                    answers: answers,
                    profile: profileStore.profile,
                    appLanguage: settingsStore.appLanguage
                )
                await MainActor.run {
                    generatedPlan = plan
                    draftPlan = plan // Save draft
                    isGeneratingPlan = false
                    currentStep = .review
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGeneratingPlan = false
                    // Show error and allow retry
                }
            }
        }
    }
    
    private func regeneratePlan() {
        generatePlan()
    }
    
    private func startPlan(_ plan: ReadingPlan) {
        planStore.addCustomPlan(plan)
        planStore.startPlan(plan.id)
        dismiss()
    }
    
    private func goBack() {
        switch currentStep {
        case .questionnaire:
            currentStep = .profileConfirmation
        case .review:
            currentStep = .questionnaire
        default:
            break
        }
    }
}

// MARK: - Profile Confirmation Step

struct ProfileConfirmationStep: View {
    let profile: UserProfile
    let onConfirm: () -> Void
    let onEdit: () -> Void
    @ObservedObject var settingsStore: SettingsStore
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(isChinese ? "確認個人資料" : "Confirm Your Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(isChinese ? "我們將根據以下資訊為您創建個人化閱讀計劃" : "We'll use this information to create your personalized reading plan")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Profile Summary
                VStack(alignment: .leading, spacing: 16) {
                    profileRow(
                        label: isChinese ? "屬靈階段" : "Spiritual Maturity",
                        value: profile.spiritualMaturity.localizedDisplayName(for: settingsStore.appLanguage)
                    )
                    
                    profileRow(
                        label: isChinese ? "目標" : "Goals",
                        value: profile.spiritualGoals.isEmpty ? 
                            (isChinese ? "無" : "None") :
                            profile.spiritualGoals.map { $0.localizedDisplayName(for: settingsStore.appLanguage) }.joined(separator: ", ")
                    )
                    
                    profileRow(
                        label: isChinese ? "生活焦點" : "Life Focus",
                        value: profile.lifeFocusAreas.isEmpty ?
                            (isChinese ? "無" : "None") :
                            profile.lifeFocusAreas.map { $0.localizedDisplayName(for: settingsStore.appLanguage) }.joined(separator: ", ")
                    )
                }
                .padding()
                .background(AppTheme.cardGradient)
                .cornerRadius(16)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onConfirm) {
                        Text(isChinese ? "確認並繼續" : "Confirm & Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onEdit) {
                        Text(isChinese ? "編輯個人資料" : "Edit Profile")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(AppTheme.accentColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentColor, lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
        }
    }
    
    private func profileRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Text(value)
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
        }
    }
}

// MARK: - Questionnaire Step

struct QuestionnaireStep: View {
    let dynamicQuestions: [AIService.PlanQuestion]
    @Binding var answers: [String: String]
    let isLoading: Bool
    let onComplete: () -> Void
    @ObservedObject var settingsStore: SettingsStore
    
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedDuration: Int = 7
    @State private var selectedFocus: PlanFocus = .topic
    @State private var selectedDirection: PlanDirection = .new
    @State private var selectedOptions: [String: Set<String>] = [:] // question index -> selected option IDs
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    private var allQuestions: [QuestionItem] {
        var items: [QuestionItem] = []
        // Add dynamic questions
        for (index, question) in dynamicQuestions.enumerated() {
            items.append(.dynamic(question, index: index))
        }
        // Add static questions
        items.append(.duration)
        items.append(.focus)
        items.append(.direction)
        return items
    }
    
    private var currentQuestion: QuestionItem? {
        guard currentQuestionIndex < allQuestions.count else { return nil }
        return allQuestions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex >= allQuestions.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text(isChinese ? "準備問題中..." : "Preparing questions...")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.top, 16)
                Spacer()
            } else if let question = currentQuestion {
                // Question content
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        progressIndicator
                        
                        // Question content
                        questionContent(question)
                    }
                    .padding()
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentQuestionIndex > 0 {
                        Button(action: previousQuestion) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(isChinese ? "上一題" : "Previous")
                            }
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.cardGradient)
                            .foregroundColor(AppTheme.primaryText)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: nextQuestion) {
                        HStack {
                            Text(isLastQuestion ? (isChinese ? "完成" : "Complete") : (isChinese ? "下一題" : "Next"))
                            if !isLastQuestion {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed(question) ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canProceed(question))
                }
                .padding()
                .background(AppTheme.backgroundGradient)
            }
        }
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            Text(isChinese ? "問題 \(currentQuestionIndex + 1) / \(allQuestions.count)" : "Question \(currentQuestionIndex + 1) / \(allQuestions.count)")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.secondaryText.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.accentColor)
                        .frame(
                            width: max(0, geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(max(1, allQuestions.count))),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }
    
    private func questionContent(_ question: QuestionItem) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            switch question {
            case .dynamic(let planQuestion, let index):
                dynamicQuestionView(planQuestion, index: index)
            case .duration:
                durationQuestionView
            case .focus:
                focusQuestionView
            case .direction:
                directionQuestionView
            }
        }
    }
    
    private func dynamicQuestionView(_ question: AIService.PlanQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Context caption
            Text(question.contextCaption)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .italic()
            
            // Question
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            // Multiple choice options
            VStack(spacing: 12) {
                ForEach(question.options, id: \.id) { option in
                    multipleChoiceOption(
                        option: option,
                        isSelected: selectedOptions["question_\(index)"]?.contains(option.id) ?? false,
                        allowsMultiple: question.allowsMultipleSelection
                    ) {
                        toggleOption(questionIndex: index, optionId: option.id, allowsMultiple: question.allowsMultipleSelection)
                    }
                }
            }
        }
    }
    
    private func multipleChoiceOption(
        option: AIService.QuestionOption,
        isSelected: Bool,
        allowsMultiple: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            optionContent(option: option, isSelected: isSelected, allowsMultiple: allowsMultiple)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func optionContent(option: AIService.QuestionOption, isSelected: Bool, allowsMultiple: Bool) -> some View {
        HStack(spacing: 16) {
            selectionIndicator(isSelected: isSelected, allowsMultiple: allowsMultiple)
            optionText(option.text)
            Spacer()
        }
        .padding()
        .background(backgroundForOption(isSelected: isSelected))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private func selectionIndicator(isSelected: Bool, allowsMultiple: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
            
            if isSelected {
                Circle()
                    .fill(AppTheme.accentColor)
                    .frame(width: 16, height: 16)
                
                if allowsMultiple {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func optionText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(AppTheme.primaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func backgroundForOption(isSelected: Bool) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(AppTheme.accentColor.opacity(0.1))
        } else {
            return AnyShapeStyle(AppTheme.cardGradient)
        }
    }
    
    private var durationQuestionView: some View {
        let title = isChinese ? "計劃持續時間" : "Plan Duration"
        let durationOptions = [3, 5, 7, 14]
        
        return VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
            
            durationOptionsView(options: durationOptions)
        }
    }
    
    private func durationOptionsView(options: [Int]) -> some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { days in
                durationOptionButton(days: days)
            }
        }
    }
    
    private func durationOptionButton(days: Int) -> some View {
        let isSelected = selectedDuration == days
        let daysText = "\(days) \(isChinese ? "天" : "days")"
        
        return Button(action: {
            selectedDuration = days
        }) {
            HStack {
                Text(daysText)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding()
            .background(backgroundForOption(isSelected: isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var focusQuestionView: some View {
        let title = isChinese ? "閱讀重點" : "Reading Focus"
        let focusOptions = [PlanFocus.topic, PlanFocus.book, PlanFocus.mix]
        
        return VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
            
            focusOptionsView(options: focusOptions)
        }
    }
    
    private func focusOptionsView(options: [PlanFocus]) -> some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { focus in
                focusOptionButton(focus: focus)
            }
        }
    }
    
    private func focusOptionButton(focus: PlanFocus) -> some View {
        let isSelected = selectedFocus == focus
        
        return Button(action: {
            selectedFocus = focus
        }) {
            HStack {
                Text(focus.displayName(isChinese: isChinese))
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding()
            .background(backgroundForOption(isSelected: isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var directionQuestionView: some View {
        let title = isChinese ? "閱讀方向" : "Reading Direction"
        let directionOptions = [PlanDirection.review, PlanDirection.continue, PlanDirection.new]
        
        return VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primaryText)
            
            directionOptionsView(options: directionOptions)
        }
    }
    
    private func directionOptionsView(options: [PlanDirection]) -> some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { direction in
                directionOptionButton(direction: direction)
            }
        }
    }
    
    private func directionOptionButton(direction: PlanDirection) -> some View {
        let isSelected = selectedDirection == direction
        
        return Button(action: {
            selectedDirection = direction
        }) {
            HStack {
                Text(direction.displayName(isChinese: isChinese))
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .padding()
            .background(backgroundForOption(isSelected: isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleOption(questionIndex: Int, optionId: String, allowsMultiple: Bool) {
        let key = "question_\(questionIndex)"
        var selected = selectedOptions[key] ?? Set<String>()
        
        if allowsMultiple {
            if selected.contains(optionId) {
                selected.remove(optionId)
            } else {
                selected.insert(optionId)
            }
        } else {
            selected = [optionId]
        }
        
        if selected.isEmpty {
            selectedOptions.removeValue(forKey: key)
        } else {
            selectedOptions[key] = selected
        }
    }
    
    private func canProceed(_ question: QuestionItem) -> Bool {
        switch question {
        case .dynamic(_, let index):
            let key = "question_\(index)"
            return !(selectedOptions[key]?.isEmpty ?? true)
        case .duration:
            return true // Always has a default
        case .focus:
            return true // Always has a default
        case .direction:
            return true // Always has a default
        }
    }
    
    private func nextQuestion() {
        if isLastQuestion {
            collectAnswers()
            onComplete()
        } else {
            withAnimation {
                currentQuestionIndex += 1
            }
        }
    }
    
    private func previousQuestion() {
        withAnimation {
            currentQuestionIndex = max(0, currentQuestionIndex - 1)
        }
    }
    
    private func collectAnswers() {
        // Collect dynamic question answers
        for (index, question) in dynamicQuestions.enumerated() {
            let key = "question_\(index)"
            if let selected = selectedOptions[key], !selected.isEmpty {
                let selectedTexts = question.options
                    .filter { selected.contains($0.id) }
                    .map { $0.text }
                    .joined(separator: ", ")
                answers[key] = selectedTexts
            }
        }
        
        // Collect static answers
        answers["duration"] = "\(selectedDuration)"
        answers["focus"] = selectedFocus.rawValue
        answers["direction"] = selectedDirection.rawValue
    }
}

enum QuestionItem {
    case dynamic(AIService.PlanQuestion, index: Int)
    case duration
    case focus
    case direction
}

extension PlanFocus {
    func displayName(isChinese: Bool) -> String {
        switch self {
        case .topic:
            return isChinese ? "主題" : "Topic"
        case .book:
            return isChinese ? "書卷" : "Book"
        case .mix:
            return isChinese ? "混合" : "Mix"
        }
    }
}

extension PlanDirection {
    func displayName(isChinese: Bool) -> String {
        switch self {
        case .review:
            return isChinese ? "回顧已讀" : "Review Read"
        case .continue:
            return isChinese ? "繼續未讀" : "Continue Unread"
        case .new:
            return isChinese ? "全新探索" : "New Exploration"
        }
    }
}

enum PlanFocus: String {
    case topic = "topic"
    case book = "book"
    case mix = "mix"
}

enum PlanDirection: String {
    case review = "review"
    case `continue` = "continue"
    case new = "new"
}

// MARK: - Generation Loading Step

struct GenerationLoadingStep: View {
    let isGenerating: Bool
    @ObservedObject var settingsStore: SettingsStore
    
    @State private var loadingMessageIndex = 0
    
    private let loadingMessages: [String] = [
        "Praying over your plan...",
        "Analyzing your needs...",
        "Curating verses for you...",
        "Almost ready..."
    ]
    
    private let loadingMessagesChinese: [String] = [
        "為您禱告計劃中...",
        "分析您的需求...",
        "為您挑選經文...",
        "即將完成..."
    ]
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accentColor)
            
            Text(isChinese ? loadingMessagesChinese[min(loadingMessageIndex, loadingMessagesChinese.count - 1)] : loadingMessages[min(loadingMessageIndex, loadingMessages.count - 1)])
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startMessageRotation()
        }
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            withAnimation {
                loadingMessageIndex = (loadingMessageIndex + 1) % (isChinese ? loadingMessagesChinese.count : loadingMessages.count)
            }
        }
    }
}

// MARK: - Plan Review Step

struct PlanReviewStep: View {
    let plan: ReadingPlan
    let onStart: () -> Void
    let onRegenerate: () -> Void
    let onCancel: () -> Void
    @ObservedObject var settingsStore: SettingsStore
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(isChinese ? "您的個人化計劃" : "Your Personalized Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(isChinese ? "請查看計劃詳情" : "Review your plan details")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Plan Preview Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: plan.icon)
                            .font(.title)
                            .foregroundColor(AppTheme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.title)
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text("\(plan.duration) \(isChinese ? "天" : "days")")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    Text(plan.description)
                        .font(.body)
                        .foregroundColor(AppTheme.primaryText)
                    
                    if let extended = plan.extendedDescription {
                        Text(extended)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    // Days preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isChinese ? "閱讀計劃" : "Reading Schedule")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryText)
                        
                        ForEach(plan.days.prefix(5)) { day in
                            HStack {
                                Text("\(day.dayNumber)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(AppTheme.accentColor)
                                    .clipShape(Circle())
                                
                                Text("\(day.book) \(day.chapter)")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                            }
                        }
                        
                        if plan.days.count > 5 {
                            Text(isChinese ? "...還有 \(plan.days.count - 5) 天" : "...and \(plan.days.count - 5) more days")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .padding()
                    .background(AppTheme.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                .background(AppTheme.cardGradient)
                .cornerRadius(16)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onStart) {
                        Text(isChinese ? "開始計劃" : "Start Plan")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onRegenerate) {
                        Text(isChinese ? "重新生成" : "Regenerate")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(AppTheme.accentColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentColor, lineWidth: 1)
                            )
                    }
                    
                    Button(action: onCancel) {
                        Text(isChinese ? "取消" : "Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            .padding()
        }
    }
}

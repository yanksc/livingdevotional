// ProfileEditorView - Edit user spiritual profile with inline editing

import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedMaturity: SpiritualMaturity
    @State private var selectedGoals: Set<SpiritualGoal>
    @State private var selectedLifeFocusAreas: Set<LifeFocusArea>
    @State private var selectedTimeCommitment: DailyTimeCommitment
    @State private var selectedExplanationDepth: ExplanationDepth
    @State private var selectedTradition: ChristianTradition
    
    init() {
        let store = UserProfileStore.shared
        _name = State(initialValue: store.profile.name)
        _selectedMaturity = State(initialValue: store.profile.spiritualMaturity)
        _selectedGoals = State(initialValue: Set(store.profile.spiritualGoals))
        _selectedLifeFocusAreas = State(initialValue: Set(store.profile.lifeFocusAreas))
        _selectedTimeCommitment = State(initialValue: store.profile.dailyTimeCommitment)
        _selectedExplanationDepth = State(initialValue: store.profile.explanationDepth)
        _selectedTradition = State(initialValue: store.profile.tradition)
    }
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional || 
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                mainContent
            }
        }
        .navigationTitle(isChinese ? "個人檔案" : "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isChinese ? "完成" : "Done") {
                    saveProfile()
                    dismiss()
                }
            }
        }
        .onChange(of: name) { _, newValue in
            profileStore.profile.name = newValue.trimmingCharacters(in: .whitespaces)
        }
        .onChange(of: selectedMaturity) { _, newValue in
            profileStore.profile.spiritualMaturity = newValue
        }
        .onChange(of: selectedGoals) { _, newValue in
            profileStore.profile.spiritualGoals = Array(newValue)
        }
        .onChange(of: selectedLifeFocusAreas) { _, newValue in
            profileStore.profile.lifeFocusAreas = Array(newValue)
        }
        .onChange(of: selectedTimeCommitment) { _, newValue in
            profileStore.profile.dailyTimeCommitment = newValue
        }
        .onChange(of: selectedExplanationDepth) { _, newValue in
            profileStore.profile.explanationDepth = newValue
        }
        .onChange(of: selectedTradition) { _, newValue in
            profileStore.profile.tradition = newValue
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            profileFieldsSection
            footerText
        }
        .padding()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isChinese ? "個人資料" : "Personal Data")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
                .padding(.top, 20)
            
            Text(isChinese ? "以下是目前儲存的資訊：" : "Here's what is currently stored:")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    private var profileFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            nameField
            spiritualStageField
            goalsField
            lifeFocusField
            timeCommitmentField
            explanationDepthField
            churchBackgroundField
            chatSessionsField
        }
        .padding()
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
    }
    
    private var nameField: some View {
        editableInfoRow(
            title: isChinese ? "名字" : "Name",
            value: name.isEmpty ? (isChinese ? "未設定" : "Not Set") : name,
            textBinding: $name
        )
    }
    
    private var spiritualStageField: some View {
        editablePickerRow(
            title: isChinese ? "屬靈階段" : "Spiritual Stage",
            value: maturityDisplayValue,
            selection: $selectedMaturity,
            options: SpiritualMaturity.allCases,
            displayName: maturityDisplayName
        )
    }
    
    private var maturityDisplayValue: String {
        isChinese ? selectedMaturity.displayNameChinese : selectedMaturity.displayName
    }
    
    private func maturityDisplayName(_ maturity: SpiritualMaturity) -> String {
        isChinese ? maturity.displayNameChinese : maturity.displayName
    }
    
    private var goalsField: some View {
        editableGoalsRow(
            title: isChinese ? "目標" : "Goals",
            value: goalsDisplayValue,
            selectedGoals: $selectedGoals
        )
    }
    
    private var goalsDisplayValue: String {
        if selectedGoals.isEmpty {
            return isChinese ? "無" : "None"
        }
        return selectedGoals.map { goal in
            isChinese ? goal.displayNameChinese : goal.displayName
        }.joined(separator: ", ")
    }
    
    private var lifeFocusField: some View {
        editableLifeFocusRow(
            title: isChinese ? "生活焦點" : "Life Focus Areas",
            value: lifeFocusDisplayValue,
            selectedAreas: $selectedLifeFocusAreas
        )
    }
    
    private var lifeFocusDisplayValue: String {
        if selectedLifeFocusAreas.isEmpty {
            return isChinese ? "無" : "None"
        }
        return selectedLifeFocusAreas.map { area in
            isChinese ? area.displayNameChinese : area.displayName
        }.joined(separator: ", ")
    }
    
    private var timeCommitmentField: some View {
        editablePickerRow(
            title: isChinese ? "每日時間" : "Daily Time Commitment",
            value: timeCommitmentDisplayValue,
            selection: $selectedTimeCommitment,
            options: DailyTimeCommitment.allCases,
            displayName: timeCommitmentDisplayName
        )
    }
    
    private var timeCommitmentDisplayValue: String {
        isChinese ? selectedTimeCommitment.displayNameChinese : selectedTimeCommitment.displayName
    }
    
    private func timeCommitmentDisplayName(_ commitment: DailyTimeCommitment) -> String {
        isChinese ? commitment.displayNameChinese : commitment.displayName
    }
    
    private var explanationDepthField: some View {
        editablePickerRow(
            title: isChinese ? "解釋深度" : "Explanation Depth",
            value: explanationDepthDisplayValue,
            selection: $selectedExplanationDepth,
            options: ExplanationDepth.allCases,
            displayName: explanationDepthDisplayName
        )
    }
    
    private var explanationDepthDisplayValue: String {
        isChinese ? selectedExplanationDepth.localizedDisplayName(for: settingsStore.appLanguage) : selectedExplanationDepth.displayName
    }
    
    private func explanationDepthDisplayName(_ depth: ExplanationDepth) -> String {
        isChinese ? depth.localizedDisplayName(for: settingsStore.appLanguage) : depth.displayName
    }
    
    private var churchBackgroundField: some View {
        editablePickerRow(
            title: isChinese ? "教會背景" : "Church Background",
            value: traditionDisplayValue,
            selection: $selectedTradition,
            options: ChristianTradition.allCases,
            displayName: traditionDisplayName
        )
    }
    
    private var traditionDisplayValue: String {
        isChinese ? selectedTradition.displayNameChinese : selectedTradition.displayName
    }
    
    private func traditionDisplayName(_ tradition: ChristianTradition) -> String {
        isChinese ? tradition.displayNameChinese : tradition.displayName
    }
    
    private var chatSessionsField: some View {
        infoRow(
            title: isChinese ? "聊天記錄" : "Chat Sessions",
            value: chatSessionsDisplayValue
        )
    }
    
    private var chatSessionsDisplayValue: String {
        let count = chatStore.sessions.count
        let suffix = isChinese ? "個對話" : "conversations"
        return "\(count) \(suffix)"
    }
    
    private var footerText: some View {
        Text(isChinese ? 
             "您的所有資料都儲存在裝置上，不會與他人分享。" :
             "All your data is stored on your device and is never shared with anyone.")
            .font(.caption)
            .foregroundColor(AppTheme.secondaryText)
            .padding(.horizontal)
    }
    
    private func saveProfile() {
        profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
        profileStore.profile.spiritualMaturity = selectedMaturity
        profileStore.profile.spiritualGoals = Array(selectedGoals)
        profileStore.profile.lifeFocusAreas = Array(selectedLifeFocusAreas)
        profileStore.profile.dailyTimeCommitment = selectedTimeCommitment
        profileStore.profile.explanationDepth = selectedExplanationDepth
        profileStore.profile.tradition = selectedTradition
    }
    
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Text(value)
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
        }
    }
    
    @ViewBuilder
    private func editableInfoRow(title: String, value: String, textBinding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            TextField(title, text: textBinding)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
        }
    }
    
    @ViewBuilder
    private func editablePickerRow<T: Hashable & Identifiable>(
        title: String,
        value: String,
        selection: Binding<T>,
        options: [T],
        displayName: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(displayName(option))
                        .tag(option)
                }
            }
            .tint(AppTheme.accentColor)
            .font(.body)
        }
    }
    
    @ViewBuilder
    private func editableGoalsRow(
        title: String,
        value: String,
        selectedGoals: Binding<Set<SpiritualGoal>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(SpiritualGoal.allCases) { goal in
                    Toggle(
                        isChinese ? goal.displayNameChinese : goal.displayName,
                        isOn: Binding(
                            get: { selectedGoals.wrappedValue.contains(goal) },
                            set: { isOn in
                                if isOn {
                                    selectedGoals.wrappedValue.insert(goal)
                                } else {
                                    selectedGoals.wrappedValue.remove(goal)
                                }
                            }
                        )
                    )
                    .tint(AppTheme.accentColor)
                    .font(.body)
                }
            }
        }
    }
    
    @ViewBuilder
    private func editableLifeFocusRow(
        title: String,
        value: String,
        selectedAreas: Binding<Set<LifeFocusArea>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(LifeFocusArea.allCases) { area in
                    Toggle(
                        isChinese ? area.displayNameChinese : area.displayName,
                        isOn: Binding(
                            get: { selectedAreas.wrappedValue.contains(area) },
                            set: { isOn in
                                if isOn {
                                    selectedAreas.wrappedValue.insert(area)
                                } else {
                                    selectedAreas.wrappedValue.remove(area)
                                }
                            }
                        )
                    )
                    .tint(AppTheme.accentColor)
                    .font(.body)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditorView()
    }
}

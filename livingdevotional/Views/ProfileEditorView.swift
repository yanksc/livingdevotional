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
        selectedMaturity.localizedDisplayName(for: settingsStore.appLanguage)
    }
    
    private func maturityDisplayName(_ maturity: SpiritualMaturity) -> String {
        maturity.localizedDisplayName(for: settingsStore.appLanguage)
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
            goal.localizedDisplayName(for: settingsStore.appLanguage)
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
            area.localizedDisplayName(for: settingsStore.appLanguage)
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
        selectedTimeCommitment.localizedDisplayName(for: settingsStore.appLanguage)
    }
    
    private func timeCommitmentDisplayName(_ commitment: DailyTimeCommitment) -> String {
        commitment.localizedDisplayName(for: settingsStore.appLanguage)
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
        selectedExplanationDepth.localizedDisplayName(for: settingsStore.appLanguage)
    }
    
    private func explanationDepthDisplayName(_ depth: ExplanationDepth) -> String {
        depth.localizedDisplayName(for: settingsStore.appLanguage)
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
        selectedTradition.localizedDisplayName(for: settingsStore.appLanguage)
    }
    
    private func traditionDisplayName(_ tradition: ChristianTradition) -> String {
        tradition.localizedDisplayName(for: settingsStore.appLanguage)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            FlowLayout(spacing: 8) {
                ForEach(SpiritualGoal.allCases) { goal in
                    SelectableTag(
                        title: goal.localizedDisplayName(for: settingsStore.appLanguage),
                        isSelected: selectedGoals.wrappedValue.contains(goal)
                    ) {
                        if selectedGoals.wrappedValue.contains(goal) {
                            selectedGoals.wrappedValue.remove(goal)
                        } else {
                            selectedGoals.wrappedValue.insert(goal)
                        }
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            FlowLayout(spacing: 8) {
                ForEach(LifeFocusArea.allCases) { area in
                    SelectableTag(
                        title: area.localizedDisplayName(for: settingsStore.appLanguage),
                        isSelected: selectedAreas.wrappedValue.contains(area)
                    ) {
                        if selectedAreas.wrappedValue.contains(area) {
                            selectedAreas.wrappedValue.remove(area)
                        } else {
                            selectedAreas.wrappedValue.insert(area)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Selectable Tag Component

struct SelectableTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AppTheme.accentColor.opacity(0.2)
                    : Color.clear
            )
            .foregroundColor(
                isSelected
                    ? AppTheme.accentColor
                    : AppTheme.primaryText
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.4),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .cornerRadius(20)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if we need to wrap to next line
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        totalHeight = currentY + lineHeight
        
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        ProfileEditorView()
    }
}

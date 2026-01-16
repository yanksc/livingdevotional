// MemoryInfoView - Display what your assistant knows about you

import SwiftUI

struct MemoryInfoView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var selectedMaturity: SpiritualMaturity = .growing
    @State private var selectedGoals: Set<SpiritualGoal> = []
    @State private var selectedTradition: ChristianTradition = .nondenominational
    @State private var selectedCompanionStyle: AICompanionStyle = .mentor
    
    private var isChinese: Bool {
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        return languageCode == "zh-Hans" || languageCode == "zh-Hant"
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(isChinese ? "個人資料" : "Personal Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.top, 20)
                    
                    Text(isChinese ? "以下是目前儲存的資訊：" : "Here's what is currently stored:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        editableInfoRow(
                            title: isChinese ? "名字" : "Name",
                            value: profileStore.profile.name.isEmpty ? (isChinese ? "未設定" : "Not Set") : profileStore.profile.name,
                            isEditing: isEditing,
                            textBinding: $editedName
                        )
                        
                        editablePickerRow(
                            title: isChinese ? "屬靈階段" : "Spiritual Stage",
                            value: isChinese ? 
                                profileStore.profile.spiritualMaturity.displayNameChinese : 
                                profileStore.profile.spiritualMaturity.displayName,
                            isEditing: isEditing,
                            selection: $selectedMaturity,
                            options: SpiritualMaturity.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        editableGoalsRow(
                            title: isChinese ? "目標" : "Goals",
                            value: profileStore.profile.spiritualGoals.isEmpty ? 
                                (isChinese ? "無" : "None") :
                                profileStore.profile.spiritualGoals.map { 
                                    isChinese ? $0.displayNameChinese : $0.displayName 
                                }.joined(separator: ", "),
                            isEditing: isEditing,
                            selectedGoals: $selectedGoals
                        )
                        
                        editablePickerRow(
                            title: isChinese ? "教會背景" : "Church Background",
                            value: isChinese ? 
                                profileStore.profile.tradition.displayNameChinese : 
                                profileStore.profile.tradition.displayName,
                            isEditing: isEditing,
                            selection: $selectedTradition,
                            options: ChristianTradition.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        editablePickerRow(
                            title: isChinese ? "互動風格" : "Interaction Style",
                            value: isChinese ? 
                                profileStore.profile.companionStyle.displayNameChinese : 
                                profileStore.profile.companionStyle.displayName,
                            isEditing: isEditing,
                            selection: $selectedCompanionStyle,
                            options: AICompanionStyle.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        infoRow(
                            title: isChinese ? "聊天記錄" : "Chat Sessions",
                            value: "\(chatStore.sessions.count) " + (isChinese ? "個對話" : "conversations")
                        )
                    }
                    .padding()
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
                    
                    Text(isChinese ? 
                         "您的所有資料都儲存在裝置上，不會與他人分享。" :
                         "All your data is stored on your device and is never shared with anyone.")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationTitle(isChinese ? "資料與記憶" : "Data & Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button(isChinese ? "儲存" : "Save") {
                        saveChanges()
                        isEditing = false
                    }
                } else {
                    Button(isChinese ? "編輯" : "Edit") {
                        startEditing()
                        isEditing = true
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    Button(isChinese ? "取消" : "Cancel") {
                        cancelEditing()
                        isEditing = false
                    }
                } else {
                    Button(isChinese ? "完成" : "Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startEditing() {
        editedName = profileStore.profile.name
        selectedMaturity = profileStore.profile.spiritualMaturity
        selectedGoals = Set(profileStore.profile.spiritualGoals)
        selectedTradition = profileStore.profile.tradition
        selectedCompanionStyle = profileStore.profile.companionStyle
    }
    
    private func cancelEditing() {
        editedName = profileStore.profile.name
        selectedMaturity = profileStore.profile.spiritualMaturity
        selectedGoals = Set(profileStore.profile.spiritualGoals)
        selectedTradition = profileStore.profile.tradition
        selectedCompanionStyle = profileStore.profile.companionStyle
    }
    
    private func saveChanges() {
        profileStore.profile.name = editedName.trimmingCharacters(in: .whitespaces)
        profileStore.profile.spiritualMaturity = selectedMaturity
        profileStore.profile.spiritualGoals = Array(selectedGoals)
        profileStore.profile.tradition = selectedTradition
        profileStore.profile.companionStyle = selectedCompanionStyle
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
    private func editableInfoRow(title: String, value: String, isEditing: Bool, textBinding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            if isEditing {
                TextField(title, text: textBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
            } else {
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
            }
        }
    }
    
    @ViewBuilder
    private func editablePickerRow<T: Hashable & Identifiable>(
        title: String,
        value: String,
        isEditing: Bool,
        selection: Binding<T>,
        options: [T],
        displayName: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            if isEditing {
                Picker(title, selection: selection) {
                    ForEach(options) { option in
                        Text(displayName(option))
                            .tag(option)
                    }
                }
                .tint(AppTheme.accentColor)
                .font(.body)
            } else {
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
            }
        }
    }
    
    @ViewBuilder
    private func editableGoalsRow(
        title: String,
        value: String,
        isEditing: Bool,
        selectedGoals: Binding<Set<SpiritualGoal>>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            if isEditing {
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
            } else {
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MemoryInfoView()
    }
}

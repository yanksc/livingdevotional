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
    @State private var selectedTradition: ChristianTradition
    @State private var selectedCompanionStyle: AICompanionStyle
    
    init() {
        let store = UserProfileStore.shared
        _name = State(initialValue: store.profile.name)
        _selectedMaturity = State(initialValue: store.profile.spiritualMaturity)
        _selectedGoals = State(initialValue: Set(store.profile.spiritualGoals))
        _selectedTradition = State(initialValue: store.profile.tradition)
        _selectedCompanionStyle = State(initialValue: store.profile.companionStyle)
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
                        // Name - Inline editable
                        editableInfoRow(
                            title: isChinese ? "名字" : "Name",
                            value: name.isEmpty ? (isChinese ? "未設定" : "Not Set") : name,
                            textBinding: $name
                        )
                        
                        // Spiritual Stage - Inline editable
                        editablePickerRow(
                            title: isChinese ? "屬靈階段" : "Spiritual Stage",
                            value: isChinese ? 
                                selectedMaturity.displayNameChinese : 
                                selectedMaturity.displayName,
                            selection: $selectedMaturity,
                            options: SpiritualMaturity.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        // Goals - Inline editable
                        editableGoalsRow(
                            title: isChinese ? "目標" : "Goals",
                            value: selectedGoals.isEmpty ? 
                                (isChinese ? "無" : "None") :
                                selectedGoals.map { 
                                    isChinese ? $0.displayNameChinese : $0.displayName 
                                }.joined(separator: ", "),
                            selectedGoals: $selectedGoals
                        )
                        
                        // Church Background - Inline editable
                        editablePickerRow(
                            title: isChinese ? "教會背景" : "Church Background",
                            value: isChinese ? 
                                selectedTradition.displayNameChinese : 
                                selectedTradition.displayName,
                            selection: $selectedTradition,
                            options: ChristianTradition.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        // Interaction Style - Inline editable
                        editablePickerRow(
                            title: isChinese ? "互動風格" : "Interaction Style",
                            value: isChinese ? 
                                selectedCompanionStyle.displayNameChinese : 
                                selectedCompanionStyle.displayName,
                            selection: $selectedCompanionStyle,
                            options: AICompanionStyle.allCases,
                            displayName: { isChinese ? $0.displayNameChinese : $0.displayName }
                        )
                        
                        // Chat Sessions - Read-only info
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
        .onChange(of: selectedTradition) { _, newValue in
            profileStore.profile.tradition = newValue
        }
        .onChange(of: selectedCompanionStyle) { _, newValue in
            profileStore.profile.companionStyle = newValue
        }
    }
    
    private func saveProfile() {
        profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
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
}

#Preview {
    NavigationStack {
        ProfileEditorView()
    }
}

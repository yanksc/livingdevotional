// ProfileEditorView - Edit user spiritual profile

import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedMaturity: SpiritualMaturity
    @State private var selectedGoals: Set<SpiritualGoal>
    @State private var selectedTradition: ChristianTradition
    
    init() {
        let store = UserProfileStore.shared
        _name = State(initialValue: store.profile.name)
        _selectedMaturity = State(initialValue: store.profile.spiritualMaturity)
        _selectedGoals = State(initialValue: Set(store.profile.spiritualGoals))
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
            
            Form {
                Section(header: 
                    Text(isChinese ? "基本資訊" : "Basic Information")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    TextField(isChinese ? "您的名字" : "Your Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "屬靈旅程" : "Spiritual Journey")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker(isChinese ? "階段" : "Stage", selection: $selectedMaturity) {
                        ForEach(SpiritualMaturity.allCases) { maturity in
                            Text(isChinese ? maturity.displayNameChinese : maturity.displayName)
                                .tag(maturity)
                        }
                    }
                    .tint(AppTheme.accentColor)
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "目標" : "Goals")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    ForEach(SpiritualGoal.allCases) { goal in
                        Toggle(
                            isChinese ? goal.displayNameChinese : goal.displayName,
                            isOn: Binding(
                                get: { selectedGoals.contains(goal) },
                                set: { isOn in
                                    if isOn {
                                        selectedGoals.insert(goal)
                                    } else {
                                        selectedGoals.remove(goal)
                                    }
                                }
                            )
                        )
                        .tint(AppTheme.accentColor)
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: 
                    Text(isChinese ? "教會背景" : "Church Background")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                ) {
                    Picker(isChinese ? "傳統" : "Tradition", selection: $selectedTradition) {
                        ForEach(ChristianTradition.allCases) { tradition in
                            Text(isChinese ? tradition.displayNameChinese : tradition.displayName)
                                .tag(tradition)
                        }
                    }
                    .tint(AppTheme.accentColor)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(isChinese ? "編輯個人檔案" : "Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isChinese ? "完成" : "Done") {
                    saveProfile()
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(isChinese ? "取消" : "Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func saveProfile() {
        profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
        profileStore.profile.spiritualMaturity = selectedMaturity
        profileStore.profile.spiritualGoals = Array(selectedGoals)
        profileStore.profile.tradition = selectedTradition
    }
}

#Preview {
    NavigationStack {
        ProfileEditorView()
    }
}

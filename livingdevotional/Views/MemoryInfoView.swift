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
    }
    
    private func cancelEditing() {
        editedName = profileStore.profile.name
        selectedMaturity = profileStore.profile.spiritualMaturity
    }
    
    private func saveChanges() {
        profileStore.profile.name = editedName.trimmingCharacters(in: .whitespaces)
        profileStore.profile.spiritualMaturity = selectedMaturity
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
    
}

#Preview {
    NavigationStack {
        MemoryInfoView()
    }
}

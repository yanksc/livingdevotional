// MemoryInfoView - Display what your companion knows about you

import SwiftUI

struct MemoryInfoView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @Environment(\.dismiss) var dismiss
    
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
                    Text(isChinese ? "屬靈夥伴知道什麼" : "What Your Companion Knows")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                        .padding(.top, 20)
                    
                    Text(isChinese ? "以下是您的屬靈夥伴目前了解的資訊：" : "Here's what your spiritual companion currently knows:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        infoRow(
                            title: isChinese ? "名字" : "Name",
                            value: profileStore.profile.name.isEmpty ? (isChinese ? "未設定" : "Not Set") : profileStore.profile.name
                        )
                        
                        infoRow(
                            title: isChinese ? "屬靈階段" : "Spiritual Stage",
                            value: isChinese ? 
                                profileStore.profile.spiritualMaturity.displayNameChinese : 
                                profileStore.profile.spiritualMaturity.displayName
                        )
                        
                        infoRow(
                            title: isChinese ? "目標" : "Goals",
                            value: profileStore.profile.spiritualGoals.isEmpty ? 
                                (isChinese ? "無" : "None") :
                                profileStore.profile.spiritualGoals.map { 
                                    isChinese ? $0.displayNameChinese : $0.displayName 
                                }.joined(separator: ", ")
                        )
                        
                        infoRow(
                            title: isChinese ? "教會背景" : "Church Background",
                            value: isChinese ? 
                                profileStore.profile.tradition.displayNameChinese : 
                                profileStore.profile.tradition.displayName
                        )
                        
                        infoRow(
                            title: isChinese ? "屬靈夥伴風格" : "Spiritual Companion Style",
                            value: isChinese ? 
                                profileStore.profile.companionStyle.displayNameChinese : 
                                profileStore.profile.companionStyle.displayName
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
                Button(isChinese ? "完成" : "Done") {
                    dismiss()
                }
            }
        }
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
}

#Preview {
    NavigationStack {
        MemoryInfoView()
    }
}

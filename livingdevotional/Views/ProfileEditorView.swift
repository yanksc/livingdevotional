// ProfileEditorView - View and edit user profile aligned with onboarding data

import SwiftUI

struct ProfileEditorView: View {
    @ObservedObject private var profileStore = UserProfileStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var chatStore = ChatStore.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedMaturity: SpiritualMaturity
    @State private var selectedRelationshipDesire: RelationshipDesire?
    @State private var selectedExplanationDepth: ExplanationDepth
    
    init() {
        let store = UserProfileStore.shared
        _name = State(initialValue: store.profile.name)
        _selectedMaturity = State(initialValue: store.profile.spiritualMaturity)
        _selectedRelationshipDesire = State(initialValue: store.profile.relationshipDesire)
        _selectedExplanationDepth = State(initialValue: store.profile.explanationDepth)
    }
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional ||
        settingsStore.appLanguage == .chineseSimplified ||
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    editableSection
                    onboardingDataSection
                    appDataSection
                    footerText
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
        .onChange(of: selectedRelationshipDesire) { _, newValue in
            profileStore.profile.relationshipDesire = newValue
        }
        .onChange(of: selectedExplanationDepth) { _, newValue in
            profileStore.profile.explanationDepth = newValue
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isChinese ? "個人資料" : "Personal Data")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
                .padding(.top, 12)
            
            Text(isChinese ? "以下是目前儲存的資訊：" : "Here's what is currently stored:")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
    
    // MARK: - Editable Profile Section
    
    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel(isChinese ? "基本資料" : "Profile", icon: "person.circle")
            
            VStack(alignment: .leading, spacing: 16) {
                // Name
                editableInfoRow(
                    title: isChinese ? "名字" : "Name",
                    textBinding: $name,
                    placeholder: isChinese ? "輸入你的名字" : "Enter your name"
                )
                
                // Spiritual Stage
                editablePickerRow(
                    title: isChinese ? "屬靈階段" : "Spiritual Stage",
                    selection: $selectedMaturity,
                    options: SpiritualMaturity.allCases,
                    displayName: { $0.localizedDisplayName(for: settingsStore.appLanguage) }
                )
                
                // Relationship Desire
                if selectedRelationshipDesire != nil {
                    editablePickerRow(
                        title: isChinese ? "與神的關係" : "Seeking in Faith",
                        selection: Binding(
                            get: { selectedRelationshipDesire ?? .closerWalk },
                            set: { selectedRelationshipDesire = $0 }
                        ),
                        options: RelationshipDesire.allCases,
                        displayName: { $0.localizedDisplayName(for: settingsStore.appLanguage) }
                    )
                }
                
                // Explanation Depth
                editablePickerRow(
                    title: isChinese ? "解釋深度" : "Explanation Depth",
                    selection: $selectedExplanationDepth,
                    options: ExplanationDepth.allCases,
                    displayName: { $0.localizedDisplayName(for: settingsStore.appLanguage) }
                )
            }
            .padding(16)
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Onboarding Data Section (read-only)
    
    private var onboardingDataSection: some View {
        let hasAnyData = profileStore.profile.personalReflection != nil ||
                         profileStore.profile.savedOnboardingVerse != nil ||
                         profileStore.profile.recommendedVerses?.first != nil
        
        return Group {
            if hasAnyData {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel(isChinese ? "你的旅程" : "Your Journey", icon: "leaf")
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Personal Reflection
                        if let reflection = profileStore.profile.personalReflection, !reflection.isEmpty {
                            readOnlyRow(
                                icon: "text.quote",
                                title: isChinese ? "心裡的話" : "Your Reflection",
                                content: reflection,
                                isItalic: true
                            )
                        }
                        
                        // Saved Verse (from Scripture Echo)
                        if let savedVerse = profileStore.profile.savedOnboardingVerse {
                            if profileStore.profile.personalReflection != nil {
                                rowDivider
                            }
                            readOnlyVerseRow(
                                icon: "bookmark.fill",
                                title: isChinese ? "收藏的經文" : "Saved Verse",
                                reference: savedVerse.reference,
                                text: savedVerse.text
                            )
                        }
                        
                        // Verse of the Day (from onboarding)
                        if let verse = profileStore.profile.recommendedVerses?.first {
                            if profileStore.profile.savedOnboardingVerse != nil || profileStore.profile.personalReflection != nil {
                                rowDivider
                            }
                            readOnlyVerseRow(
                                icon: "sun.max",
                                title: isChinese ? "為你挑選的經文" : "Your First Verse of the Day",
                                reference: verse.reference,
                                text: verse.text
                            )
                        }
                    }
                    .padding(16)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - App Data Section
    
    private var appDataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel(isChinese ? "應用資料" : "App Data", icon: "square.stack.3d.up")
            
            VStack(alignment: .leading, spacing: 0) {
                // Chat sessions
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.accentColor)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isChinese ? "聊天記錄" : "Chat Sessions")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Text(chatSessionsDisplayValue)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                // Recommended Books
                if let books = profileStore.profile.recommendedBooks, !books.isEmpty {
                    rowDivider
                    
                    HStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.accentColor)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isChinese ? "推薦書卷" : "Recommended Books")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                            Text(books.map { $0.bookName }.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Footer
    
    private var footerText: some View {
        Text(isChinese ?
             "您的所有資料都儲存在裝置上，不會與他人分享。" :
             "All your data is stored on your device and is never shared with anyone.")
            .font(.caption)
            .foregroundColor(AppTheme.secondaryText)
            .padding(.horizontal)
            .padding(.top, 4)
    }
    
    // MARK: - Save
    
    private func saveProfile() {
        profileStore.profile.name = name.trimmingCharacters(in: .whitespaces)
        profileStore.profile.spiritualMaturity = selectedMaturity
        profileStore.profile.relationshipDesire = selectedRelationshipDesire
        profileStore.profile.explanationDepth = selectedExplanationDepth
    }
    
    // MARK: - Helpers
    
    private var chatSessionsDisplayValue: String {
        let count = chatStore.sessions.count
        return isChinese ? "\(count) 個對話" : "\(count) conversations"
    }
    
    // MARK: - Reusable Row Components
    
    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.accentColor)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.bottom, 8)
    }
    
    private var rowDivider: some View {
        Divider()
            .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func editableInfoRow(title: String, textBinding: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            
            TextField(placeholder, text: textBinding)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .foregroundColor(AppTheme.primaryText)
        }
    }
    
    @ViewBuilder
    private func editablePickerRow<T: Hashable & Identifiable>(
        title: String,
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
    
    private func readOnlyRow(icon: String, title: String, content: String, isItalic: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                Group {
                    if isItalic {
                        Text(content)
                            .italic()
                    } else {
                        Text(content)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func readOnlyVerseRow(icon: String, title: String, reference: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 20)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                
                Text(reference)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Text(text)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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

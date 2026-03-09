// AskCategoryDetailView - Shows questions within a category

import SwiftUI

struct AskCategoryDetailView: View {
    let category: AskCategory
    @Environment(\.services) var services
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    @State private var selectedQuestion: AskQuestion?
    
    // Get category index for consistent background assignment
    private var categoryIndex: Int {
        AskCategoryStore.shared.categories.firstIndex(where: { $0.id == category.id }) ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with large image - full width, extends to top edge
                GeometryReader { geometry in
                    let imageHeight = UIScreen.main.bounds.height * 0.4
                    ZStack(alignment: .bottomLeading) {
                        SereneBackgroundImage(filename: backgroundManager.background(at: categoryIndex))
                            .frame(width: geometry.size.width, height: imageHeight)
                            .clipped()
                        
                        // Gradient overlay for text readability
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        
                        // Title and description overlay on image
                        VStack(alignment: .leading, spacing: 12) {
                            // Icon and title
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                                
                                Text(category.localizedTitle(for: settingsStore.appLanguage))
                                    .font(.system(size: 28, weight: .bold, design: .serif))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 3)
                            }
                            
                            // Description
                            Text(category.localizedDescription(for: settingsStore.appLanguage))
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                            
                            // Question count badge
                            HStack(spacing: 8) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.caption)
                                Text("\(category.questions.count) \(settingsStore.appLanguage == .chineseTraditional ? "問題" : settingsStore.appLanguage == .chineseSimplified ? "问题" : "questions")")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(20)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .ignoresSafeArea(edges: .top)
                
                // Questions list
                VStack(spacing: 0) {
                    ForEach(category.questions) { question in
                        Button {
                            if !UsageLimitStore.shared.canUseAIQuestion() {
                                router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                                return
                            }
                            selectedQuestion = question
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                // Question number/icon
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentColor.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.accentColor)
                                }
                                
                                // Question text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.localizedQuestion(for: settingsStore.appLanguage))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppTheme.primaryText)
                                        .multilineTextAlignment(.leading)
                                    
                                    // Verse reference if available
                                    if let verseRef = question.verseReference {
                                        HStack(spacing: 4) {
                                            Image(systemName: "book.fill")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.accentColor)
                                            Text(verseRef)
                                                .font(.caption)
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Chevron
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                            }
                            .padding()
                            .background(Color.clear)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if question.id != category.questions.last?.id {
                            Divider()
                                .padding(.leading, 72) // Align with question text
                        }
                    }
                }
                .background(AppTheme.cardGradient)
                .cornerRadius(16)
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text(settingsStore.appLanguage == .chineseTraditional ? "返回探索" : settingsStore.appLanguage == .chineseSimplified ? "返回探索" : "Back to Explore")
                            .font(.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selectedQuestion) { question in
            if let aiService = services.aiService {
                ChatView(
                    viewModel: ChatViewModel(
                        aiService: aiService,
                        book: question.verseBook,
                        chapter: question.verseChapter,
                        verse: question.verseNumber,
                        verseText: nil, // We don't have verse text here, will be loaded if needed
                        appLanguage: settingsStore.appLanguage,
                        initialQuestion: question.localizedQuestion(for: settingsStore.appLanguage),
                        onLimitReached: {
                            router.presentUsageLimitPaywall(context: settingsStore.appLanguage.localizedString("UsageLimitReached"))
                        }
                    ),
                    settingsStore: settingsStore,
                    onClose: {
                        selectedQuestion = nil
                    }
                )
                .environmentObject(router)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(settingsStore.appLanguage == .chineseTraditional ? "服務暫時無法使用" : "Service is currently unavailable")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.backgroundGradient.ignoresSafeArea())
            }
        }
    }
}

#Preview {
    if let category = AskCategoryStore.shared.categories.first {
        NavigationStack {
            AskCategoryDetailView(category: category)
                .environmentObject(AppRouter())
        }
    }
}

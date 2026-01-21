// AskCategoryDetailView - Shows questions within a category

import SwiftUI

struct AskCategoryDetailView: View {
    let category: AskCategory
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var selectedQuestion: AskQuestion?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Category header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundColor(AppTheme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.localizedTitle(for: settingsStore.appLanguage))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primaryText)
                            
                            Text(category.localizedDescription(for: settingsStore.appLanguage))
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(AppTheme.cardGradient)
                
                // Questions list
                VStack(spacing: 0) {
                    ForEach(category.questions) { question in
                        Button {
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
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle(category.localizedTitle(for: settingsStore.appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                        initialQuestion: question.localizedQuestion(for: settingsStore.appLanguage)
                    ),
                    settingsStore: settingsStore,
                    onClose: {
                        selectedQuestion = nil
                    }
                )
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(settingsStore.appLanguage == .chineseTraditional ? "AI 服務暫時無法使用" : "AI service is currently unavailable")
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
    NavigationStack {
        AskCategoryDetailView(category: AskCategoryStore.shared.categories[0])
            .environmentObject(AppRouter())
    }
}

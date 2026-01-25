// VerseDetailView - Displays detailed view of the Verse of the Day with context
//
import SwiftUI

struct VerseDetailView: View {
    let verse: DailyVerse
    @EnvironmentObject var router: AppRouter
    @Environment(\.services) var services
    @ObservedObject var settingsStore = SettingsStore.shared
    
    @State private var showChat = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header / Context
                if let reason = verse.reason {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Verse Card
                VStack(spacing: 24) {
                    Text(verse.text(for: settingsStore.primaryLanguage))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if settingsStore.secondaryLanguage != .none {
                        Text(verse.text(for: settingsStore.secondaryLanguage))
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Text(verse.reference)
                        .font(.headline)
                        .foregroundColor(AppTheme.accentColor)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 4)
                
                // Explanation / Source
                if let source = verse.source {
                     VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppTheme.accentColor)
                            Text("Why this verse?")
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                        }
                        
                        Text(source)
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineSpacing(4)
                     }
                     .padding(20)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .background(AppTheme.cardGradient)
                     .cornerRadius(16)
                }
                
                Spacer(minLength: 20)
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        showChat = true
                    }) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Ask Deeper Questions")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        navigateToChapter()
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Read Chapter")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.sectionBackground)
                        .foregroundColor(AppTheme.primaryText)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
        }
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Your Verse")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChat) {
             ChatViewWrapper(verse: verse, services: services)
        }
    }
    
    private func navigateToChapter() {
        if let book = BibleData.book(named: verse.book) {
            router.navigateToReading(book: book, chapter: verse.chapter, verse: verse.verseNumber)
        }
    }
}

// Helper wrapper for ChatView to handle environment injection
struct ChatViewWrapper: View {
    let verse: DailyVerse
    let services: ServiceContainer
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        if let aiService = services.aiService {
            let viewModel = ChatViewModel(
                aiService: aiService,
                book: verse.book,
                chapter: verse.chapter,
                verse: verse.verseNumber,
                verseText: verse.text(for: SettingsStore.shared.primaryLanguage),
                appLanguage: SettingsStore.shared.appLanguage
            )
            
            ChatView(
                viewModel: viewModel,
                settingsStore: SettingsStore.shared,
                onClose: { dismiss() }
            )
            .environmentObject(router)
        } else {
            // Fallback if AI service not available (shouldn't happen)
            Text("AI Service Unavailable")
                .onTapGesture { dismiss() }
        }
    }
}

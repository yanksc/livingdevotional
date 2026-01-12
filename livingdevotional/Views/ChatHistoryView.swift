// ChatHistoryView - Lists previous Q&A sessions

import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject private var chatStore = ChatStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        List {
            if chatStore.sessions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(settingsStore.appLanguage == .chineseTraditional ? "尚無對話記錄" : "No conversation history")
                        .font(.headline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(chatStore.sessions) { session in
                    ChatHistoryRow(session: session, settingsStore: settingsStore)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Navigate to reading view with chat open would be ideal, 
                            // but for now let's just show the reading view for context
                            // In a real app we might want to restore the chat state
                            if let book = BibleData.book(named: session.book) {
                                router.navigateToReading(book: book, chapter: session.chapter, verse: session.verseNumber)
                                // We can't easily auto-open the chat sheet from here without significant plumbing,
                                // but we can take the user to the verse.
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                chatStore.deleteSession(id: session.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "AI 問答記錄" : "Q&A History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatHistoryRow: View {
    let session: ChatSession
    @ObservedObject var settingsStore: SettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localizedReference)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentColor.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Text(session.title)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .lineLimit(2)
            
            Text(session.verseText)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
    
    private var localizedReference: String {
        let localizedBook = BibleData.localizedBookName(session.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(session.chapter):\(session.verseNumber)"
    }
}

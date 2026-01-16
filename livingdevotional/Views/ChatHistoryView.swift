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
                            // Navigate to reading view and open chat with this session
                            if let book = BibleData.book(named: session.book) {
                                // Set the pending chat session ID in the router's bibleViewModel
                                // We'll need to access it through the environment
                                router.navigateToReading(book: book, chapter: session.chapter, verse: session.verseNumber)
                                // The session ID will be passed via a notification or environment
                                // For now, we'll use a simpler approach: store it in a shared location
                                // and ReadingView will check for it
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenChatSession"),
                                    object: nil,
                                    userInfo: ["sessionId": session.id]
                                )
                            }
                            dismiss()
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
        .navigationTitle(settingsStore.appLanguage == .chineseTraditional ? "問答記錄" : "Q&A History")
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
            
            // Show verse text
            Text(session.verseText)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(1)
            
            // Show conversation preview
            if !session.messages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(session.messages.prefix(3))) { message in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: message.role == .user ? "person.fill" : "bubble.left.fill")
                                .font(.system(size: 10))
                                .foregroundColor(message.role == .user ? AppTheme.accentColor : AppTheme.secondaryText)
                            
                            Text(message.content)
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(2)
                        }
                    }
                    
                    if session.messages.count > 3 {
                        Text(settingsStore.appLanguage == .chineseTraditional ? 
                             "還有 \(session.messages.count - 3) 則訊息..." : 
                             "\(session.messages.count - 3) more messages...")
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                            .italic()
                    }
                }
                .padding(.top, 4)
            } else {
                Text(session.title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var localizedReference: String {
        let localizedBook = BibleData.localizedBookName(session.book, language: settingsStore.primaryLanguage)
        return "\(localizedBook) \(session.chapter):\(session.verseNumber)"
    }
}

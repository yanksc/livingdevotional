// ChatViewModel - Manages chat session and conversation interaction

import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var session: ChatSession?
    @Published var suggestedQuestions: [String] = []
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var inputMessage: String = ""
    
    private let aiService: AIServiceProtocol
    private let chatStore = ChatStore.shared
    
    // Current verse context
    private var book: String
    private var chapter: Int
    private var verse: Int
    private var verseText: String
    private var appLanguage: AppLanguage
    
    init(aiService: AIServiceProtocol, book: String, chapter: Int, verse: Int, verseText: String, appLanguage: AppLanguage, sessionId: String? = nil) {
        self.aiService = aiService
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.verseText = verseText
        self.appLanguage = appLanguage
        
        if let sessionId = sessionId, let existingSession = chatStore.getSession(id: sessionId) {
            self.session = existingSession
        } else {
            // New session will be created on first message or if explicitly requested
        }
    }
    
    func loadSuggestions() async {
        guard session == nil || session?.messages.isEmpty == true else { return }
        
        do {
            if let service = aiService as? AIService {
                suggestedQuestions = try await service.generateSuggestedQuestions(
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    appLanguage: appLanguage
                )
            }
        } catch {
            print("Failed to load suggestions: \(error)")
        }
    }
    
    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        let question = content
        inputMessage = "" // Clear input
        
        // Create session if needed
        if session == nil {
            session = chatStore.createSession(
                book: book,
                chapter: chapter,
                verseNumber: verse,
                verseText: verseText
            )
        }
        
        guard let currentSessionId = session?.id else { return }
        
        // Capture history before adding new message to avoid duplication in AI request
        let history = session?.messages ?? []
        
        // Add user message
        let userMsg = ChatMessage(role: .user, content: question, createdAt: Date())
        chatStore.addMessage(userMsg, to: currentSessionId)
        refreshSession()
        
        // Prepare for AI response
        isGenerating = true
        var fullResponse = ""
        let assistantMsgId = UUID().uuidString
        // Optimistic update with empty message or placeholder if needed
        
        do {
            if let service = aiService as? AIService {
                let stream = try await service.chatWithVerse(
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    appLanguage: appLanguage,
                    conversationHistory: history,
                    userQuestion: question
                )
                
                // Add placeholder assistant message
                let assistantMsg = ChatMessage(id: assistantMsgId, role: .assistant, content: "", createdAt: Date())
                chatStore.addMessage(assistantMsg, to: currentSessionId)
                refreshSession()
                
                for try await chunk in stream {
                    fullResponse += chunk
                    // Update the last message (which is the assistant's)
                    if var currentSession = session, !currentSession.messages.isEmpty {
                        var messages = currentSession.messages
                        if let index = messages.firstIndex(where: { $0.id == assistantMsgId }) {
                            let updatedMsg = ChatMessage(id: assistantMsgId, role: .assistant, content: fullResponse, createdAt: Date())
                            messages[index] = updatedMsg
                            // Update local state directly for smooth UI
                            session?.messages = messages
                        }
                    }
                }
                
                // Final save to store
                if let currentSession = session {
                   // We need to update the store with the final complete message
                   // The store's addMessage appends, so we actually need a way to update a message or just replace the session
                   // For simplicity, let's update the session in the store
                    var finalSession = currentSession
                    if let index = finalSession.messages.firstIndex(where: { $0.id == assistantMsgId }) {
                        finalSession.messages[index] = ChatMessage(id: assistantMsgId, role: .assistant, content: fullResponse, createdAt: Date())
                        chatStore.updateSession(finalSession)
                    }
                }
                
                refreshSession()
            }
        } catch {
            errorMessage = error.localizedDescription
            // Remove the user message if failed? Or keep it with error?
            // For now, keep it.
        }
        
        isLoading = false
        isGenerating = false
    }
    
    private func refreshSession() {
        if let id = session?.id {
            session = chatStore.getSession(id: id)
        }
    }
}

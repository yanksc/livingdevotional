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
    @Published var loadedVerseText: String?
    @Published var verseLoadError: String?
    
    private let aiService: AIServiceProtocol
    private let chatStore = ChatStore.shared
    private let onLimitReached: (() -> Void)?
    
    // Current verse context (exposed for UI display) - optional for general chat
    let book: String?
    let chapter: Int?
    let verse: Int?
    private let initialVerseText: String?
    let appLanguage: AppLanguage
    let initialQuestion: String?
    let chapterContext: String?
    let chapterContextType: String?
    
    /// Returns the verse text - either provided or loaded from BibleService
    var verseText: String? {
        return loadedVerseText ?? initialVerseText
    }
    
    /// Check if verse context exists
    var hasVerseContext: Bool {
        return book != nil && chapter != nil && verse != nil
    }
    
    /// Check if chapter-level context exists (context or summary, no specific verse)
    var hasChapterContext: Bool {
        return book != nil && chapter != nil && verse == nil && chapterContext != nil
    }
    
    init(aiService: AIServiceProtocol, book: String? = nil, chapter: Int? = nil, verse: Int? = nil, verseText: String? = nil, appLanguage: AppLanguage, sessionId: String? = nil, initialQuestion: String? = nil, chapterContext: String? = nil, chapterContextType: String? = nil, onLimitReached: (() -> Void)? = nil) {
        self.aiService = aiService
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.initialVerseText = verseText
        self.loadedVerseText = verseText
        self.appLanguage = appLanguage
        self.initialQuestion = initialQuestion
        self.chapterContext = chapterContext
        self.chapterContextType = chapterContextType
        self.onLimitReached = onLimitReached
        
        if let sessionId = sessionId, let existingSession = chatStore.getSession(id: sessionId) {
            self.session = existingSession
        } else {
            // New session will be created on first message or if explicitly requested
        }
    }
    
    /// Load verse text from BibleService if not already provided
    func loadVerseTextIfNeeded(primaryLanguage: Language) async {
        // Only load if we have verse context but no verse text
        guard let book = book, let chapter = chapter, let verse = verse,
              loadedVerseText == nil else {
            print("ChatViewModel: Skipping verse load - already have text or missing context")
            return
        }
        
        print("ChatViewModel: Loading verse text for \(book) \(chapter):\(verse) in \(primaryLanguage)")
        
        do {
            let verses = try await BibleService.shared.loadVerses(book: book, chapter: chapter, translation: primaryLanguage)
            if let matchingVerse = verses.first(where: { $0.verseNumber == verse }) {
                loadedVerseText = matchingVerse.text(for: primaryLanguage)
                print("ChatViewModel: Successfully loaded verse text: \(String(loadedVerseText?.prefix(50) ?? ""))")
            } else {
                print("ChatViewModel: No matching verse found for verse number \(verse)")
                verseLoadError = "Verse not found"
                // Set empty string to prevent infinite loading
                loadedVerseText = ""
            }
        } catch {
            print("ChatViewModel: Failed to load verse text: \(error)")
            print("ChatViewModel: Error details - book: \(book), chapter: \(chapter), translation: \(primaryLanguage)")
            verseLoadError = error.localizedDescription
            // Set empty string to prevent infinite loading
            loadedVerseText = ""
        }
    }
    
    func loadSuggestions() async {
        guard session == nil || session?.messages.isEmpty == true else { return }
        
        guard let service = aiService as? AIService else { return }
        
        do {
            if let book = book, let chapter = chapter, let verse = verse, let verseText = verseText {
                // Verse-specific suggestions
                suggestedQuestions = try await service.generateSuggestedQuestions(
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    appLanguage: appLanguage
                )
            } else if let book = book, let chapter = chapter,
                      let chapterContext = chapterContext, let chapterContextType = chapterContextType {
                // Chapter-level suggestions based on context or summary
                suggestedQuestions = try await service.generateChapterSuggestedQuestions(
                    book: book,
                    chapter: chapter,
                    chapterContent: chapterContext,
                    contentType: chapterContextType,
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
        
        guard UsageLimitStore.shared.canUseAIQuestion() else {
            errorMessage = appLanguage.localizedString("UsageLimitReached")
            onLimitReached?()
            isLoading = false
            return
        }
        
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
        
        do {
            if let service = aiService as? AIService {
                let stream: AsyncThrowingStream<String, Error>
                
                // Route to the appropriate chat method based on available context
                if let book = book, let chapter = chapter, let verse = verse, let verseText = verseText {
                    // Verse-specific chat
                    stream = try await service.chatWithVerse(
                        book: book,
                        chapter: chapter,
                        verse: verse,
                        verseText: verseText,
                        appLanguage: appLanguage,
                        conversationHistory: history,
                        userQuestion: question
                    )
                } else if let book = book, let chapter = chapter,
                          let chapterContext = chapterContext, let chapterContextType = chapterContextType {
                    // Chapter-level chat using context or summary
                    stream = try await service.chatWithChapterContext(
                        book: book,
                        chapter: chapter,
                        chapterContent: chapterContext,
                        contentType: chapterContextType,
                        appLanguage: appLanguage,
                        conversationHistory: history,
                        userQuestion: question
                    )
                } else {
                    stream = try await service.chatGeneral(
                        appLanguage: appLanguage,
                        conversationHistory: history,
                        userQuestion: question
                    )
                }
                
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
                
                UsageLimitStore.shared.recordAIQuestionUsed()
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
    
    func sendInitialQuestionIfNeeded() async {
        // If we have an initial question and no messages yet, send it automatically
        if let initialQuestion = initialQuestion,
           (session == nil || session?.messages.isEmpty == true),
           !initialQuestion.isEmpty {
            await sendMessage(initialQuestion)
        }
    }
}

// ChatStore - Manages AI chat history using JSON file storage

import Foundation
import Combine

struct ChatSession: Codable, Identifiable {
    let id: String
    let book: String?
    let chapter: Int?
    let verseNumber: Int?
    let verseText: String?
    var messages: [ChatMessage]
    var updatedAt: Date
    
    // Preview/Title for the history list
    var title: String {
        if let firstQuestion = messages.first(where: { $0.role == .user })?.content {
            return firstQuestion
        }
        if let book = book, let chapter = chapter, let verseNumber = verseNumber {
            return "Conversation on \(book) \(chapter):\(verseNumber)"
        }
        return "General Conversation"
    }
    
    var isGeneralChat: Bool {
        return book == nil && chapter == nil && verseNumber == nil
    }
    
    init(id: String = UUID().uuidString, book: String? = nil, chapter: Int? = nil, verseNumber: Int? = nil, verseText: String? = nil, messages: [ChatMessage] = []) {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.verseText = verseText
        self.messages = messages
        self.updatedAt = Date()
    }
}

class ChatStore: ObservableObject {
    static let shared = ChatStore()
    
    @Published var sessions: [ChatSession] = []
    
    private let fileManager = FileManager.default
    private let fileName = "chat_history.json"
    
    private var fileURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    private init() {
        loadSessions()
    }
    
    // MARK: - CRUD Operations
    
    func createSession(book: String? = nil, chapter: Int? = nil, verseNumber: Int? = nil, verseText: String? = nil) -> ChatSession {
        let newSession = ChatSession(
            book: book,
            chapter: chapter,
            verseNumber: verseNumber,
            verseText: verseText
        )
        sessions.insert(newSession, at: 0)
        saveSessions()
        return newSession
    }
    
    func addMessage(_ message: ChatMessage, to sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        var session = sessions[index]
        session.messages.append(message)
        session.updatedAt = Date()
        
        // Move to top
        sessions.remove(at: index)
        sessions.insert(session, at: 0)
        
        saveSessions()
    }
    
    func updateSession(_ session: ChatSession) {
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        
        var updatedSession = session
        updatedSession.updatedAt = Date()
        
        sessions.remove(at: index)
        sessions.insert(updatedSession, at: 0)
        saveSessions()
    }
    
    func deleteSession(id: String) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }
    
    func getSession(id: String) -> ChatSession? {
        return sessions.first(where: { $0.id == id })
    }
    
    // MARK: - Persistence
    
    private func loadSessions() {
        guard let url = fileURL, fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([ChatSession].self, from: data)
            
            // Sort by date descending
            sessions.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Error loading chat history: \(error)")
        }
    }
    
    private func saveSessions() {
        guard let url = fileURL else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(sessions)
            try data.write(to: url)
        } catch {
            print("Error saving chat history: \(error)")
        }
    }
}

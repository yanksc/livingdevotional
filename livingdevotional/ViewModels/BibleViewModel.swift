// BibleViewModel - Manages Bible navigation state

import Foundation
import Combine

class BibleViewModel: ObservableObject {
    @Published var selectedBook: BibleBook?
    @Published var selectedChapter: Int?
    @Published var targetVerse: Int? // verse to auto-scroll to when loading
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let oldTestamentBooks = BibleData.oldTestamentBooks
    let newTestamentBooks = BibleData.newTestamentBooks
    
    private let progressStore = ProgressStore.shared
    
    init() {
        // Load last reading progress
        if let lastBook = progressStore.currentBook,
           let lastChapter = progressStore.currentChapter {
            selectedBook = BibleData.book(named: lastBook)
            selectedChapter = lastChapter
        }
    }
    
    func selectBook(_ book: BibleBook) {
        selectedBook = book
        selectedChapter = nil // Reset chapter selection when book changes
    }
    
    func selectChapter(_ chapter: Int) {
        guard let book = selectedBook else { return }
        selectedChapter = chapter
        targetVerse = nil // clear target when manually changing chapter
        
        // Save progress
        progressStore.saveProgress(book: book.name, chapter: chapter)
    }
    
    func selectBookAndChapter(_ book: BibleBook, chapter: Int, targetVerse: Int? = nil) {
        // #region agent log
        let logPath = "/Users/yhuang10/Code/livingdevotional/.cursor/debug.log"
        let logEntry: [String: Any] = [
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "location": "BibleViewModel.selectBookAndChapter",
            "message": "selectBookAndChapter called",
            "data": [
                "book": book.name,
                "chapter": chapter,
                "targetVerse": targetVerse as Any,
                "prevBook": selectedBook?.name as Any,
                "prevChapter": selectedChapter as Any,
                "prevTargetVerse": self.targetVerse as Any,
                "hypothesisId": "D"
            ],
            "sessionId": "debug-session"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write((jsonString + "\n").data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try? (jsonString + "\n").write(toFile: logPath, atomically: true, encoding: .utf8)
            }
        }
        // #endregion agent log
        
        // Set both atomically to avoid race conditions
        selectedBook = book
        selectedChapter = chapter
        self.targetVerse = targetVerse
        
        // Save progress
        progressStore.saveProgress(book: book.name, chapter: chapter)
    }
    
    func goBackToBookList() {
        selectedBook = nil
        selectedChapter = nil
    }
    
    func goBackToChapterList() {
        selectedChapter = nil
    }
}

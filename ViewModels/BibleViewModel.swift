// BibleViewModel - Manages Bible navigation state

import Foundation
import Combine

class BibleViewModel: ObservableObject {
    @Published var selectedBook: BibleBook?
    @Published var selectedChapter: Int?
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


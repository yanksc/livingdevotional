// NoteStore - Manages saved verses using SwiftData

import Foundation
import SwiftData
import Combine

class NoteStore: ObservableObject {
    static let shared = NoteStore()
    
    private var modelContext: ModelContext?
    
    @Published var savedVerses: [SavedVerse] = []
    @Published var allLabels: [String] = []
    
    private init() {
        // ModelContext will be injected via setModelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSavedVerses()
    }
    
    // Load all saved verses
    func loadSavedVerses() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<SavedVerse>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            savedVerses = try context.fetch(descriptor)
            updateLabels()
        } catch {
            print("Error loading saved verses: \(error)")
            savedVerses = []
        }
    }
    
    // Check if a verse is saved
    func isVerseSaved(book: String, chapter: Int, verse: Int) -> Bool {
        let reference = SavedVerse.generateReference(book: book, chapter: chapter, verse: verse)
        return savedVerses.contains { $0.verseReference == reference }
    }
    
    // Get saved verse for a specific reference
    func getSavedVerse(book: String, chapter: Int, verse: Int) -> SavedVerse? {
        let reference = SavedVerse.generateReference(book: book, chapter: chapter, verse: verse)
        return savedVerses.first { $0.verseReference == reference }
    }
    
    // Save or update a verse
    func saveVerse(
        book: String,
        chapter: Int,
        verse: Int,
        content: String = "",
        labels: [String] = [],
        color: String? = nil
    ) {
        guard let context = modelContext else { return }
        
        let reference = SavedVerse.generateReference(book: book, chapter: chapter, verse: verse)
        
        // Check if verse already exists
        if let existing = savedVerses.first(where: { $0.verseReference == reference }) {
            // Update existing
            existing.content = content
            existing.labels = labels
            existing.timestamp = Date()
            if let color = color {
                existing.color = color
            }
        } else {
            // Create new
            let savedVerse = SavedVerse(
                verseReference: reference,
                book: book,
                chapter: chapter,
                verse: verse,
                content: content,
                labels: labels,
                timestamp: Date(),
                color: color
            )
            context.insert(savedVerse)
        }
        
        do {
            try context.save()
            loadSavedVerses()
        } catch {
            print("Error saving verse: \(error)")
        }
    }
    
    // Delete a saved verse
    func deleteVerse(book: String, chapter: Int, verse: Int) {
        guard let context = modelContext else { return }
        
        let reference = SavedVerse.generateReference(book: book, chapter: chapter, verse: verse)
        
        if let verseToDelete = savedVerses.first(where: { $0.verseReference == reference }) {
            context.delete(verseToDelete)
            
            do {
                try context.save()
                loadSavedVerses()
            } catch {
                print("Error deleting verse: \(error)")
            }
        }
    }
    
    // Get verses filtered by label
    func getVersesFilteredByLabel(_ label: String?) -> [SavedVerse] {
        guard let label = label, !label.isEmpty else {
            return savedVerses
        }
        return savedVerses.filter { $0.labels.contains(label) }
    }
    
    // Update labels list from all saved verses
    private func updateLabels() {
        var labelSet = Set<String>()
        for verse in savedVerses {
            for label in verse.labels {
                labelSet.insert(label)
            }
        }
        allLabels = Array(labelSet).sorted()
    }
    
    // Get all unique labels
    func getAllLabels() -> [String] {
        return allLabels
    }
}


// SaveVerseSheet - Input sheet for saving verses with notes and labels

import SwiftUI

struct SaveVerseSheet: View {
    let verse: BibleVerse
    let book: BibleBook
    let chapter: Int
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var noteStore: NoteStore
    
    @Environment(\.dismiss) private var dismiss
    @State private var noteContent: String = ""
    @State private var labels: [String] = []
    @State private var newLabel: String = ""
    @State private var isEditingExisting: Bool = false
    
    var primaryText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var secondaryText: String {
        verse.text(for: settingsStore.secondaryLanguage)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Verse context header
                        verseContextSection
                        
                        // Note input section
                        noteInputSection
                        
                        // Labels section
                        labelsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Save Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVerse()
                    }
                    .foregroundColor(AppTheme.accentColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadExistingNote()
        }
    }
    
    // MARK: - View Components
    
    private var verseContextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(book.localizedName(for: settingsStore.primaryLanguage)) \(chapter):\(verse.verseNumber)")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            if !primaryText.isEmpty && settingsStore.primaryLanguage != .none {
                Text(primaryText)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(4)
            }
            
            if !secondaryText.isEmpty &&
               settingsStore.secondaryLanguage != .none &&
               settingsStore.secondaryLanguage != settingsStore.primaryLanguage {
                Text(secondaryText)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardGradient)
        .cornerRadius(12)
    }
    
    private var noteInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (Optional)")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            TextEditor(text: $noteContent)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Labels (Optional)")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            // Existing labels
            if !labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(labels, id: \.self) { label in
                            LabelChip(label: label, isSelected: true) {
                                removeLabel(label)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Available labels to add
            if !availableLabels.isEmpty {
                Text("Add Label")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableLabels, id: \.self) { label in
                            LabelChip(label: label, isSelected: false) {
                                addLabel(label)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Add new label input
            HStack {
                TextField("New label", text: $newLabel)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addNewLabel()
                    }
                
                Button(action: addNewLabel) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.accentColor)
                }
                .disabled(newLabel.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private var availableLabels: [String] {
        noteStore.getAllLabels().filter { !labels.contains($0) }
    }
    
    // MARK: - Actions
    
    private func loadExistingNote() {
        if let saved = noteStore.getSavedVerse(book: book.name, chapter: chapter, verse: verse.verseNumber) {
            noteContent = saved.content
            labels = saved.labels
            isEditingExisting = true
        }
    }
    
    private func addLabel(_ label: String) {
        if !labels.contains(label) {
            labels.append(label)
        }
    }
    
    private func removeLabel(_ label: String) {
        labels.removeAll { $0 == label }
    }
    
    private func addNewLabel() {
        let trimmed = newLabel.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !labels.contains(trimmed) {
            labels.append(trimmed)
            newLabel = ""
        }
    }
    
    private func saveVerse() {
        noteStore.saveVerse(
            book: book.name,
            chapter: chapter,
            verse: verse.verseNumber,
            content: noteContent,
            labels: labels
        )
        dismiss()
    }
}

// MARK: - Label Chip Component

struct LabelChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                }
            }
            .foregroundColor(isSelected ? .white : AppTheme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? AppTheme.accentColor : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.accentColor, lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

#Preview {
    SaveVerseSheet(
        verse: BibleVerse(
            id: "1",
            book: "John",
            chapter: 3,
            verseNumber: 16,
            textBsb: "For God so loved the world...",
            textCuv: "神愛世人...",
            textCu1: "神愛世人...",
            textKjv: "For God so loved the world...",
            textWeb: "For God so loved the world...",
            textSpa: "Porque de tal manera amó Dios al mundo...",
            textPor: "Porque Deus amou o mundo de tal maneira...",
            testament: "New"
        ),
        book: BibleBook(name: "John", testament: .new, chapters: 21, hasData: true),
        chapter: 3,
        settingsStore: SettingsStore.shared,
        noteStore: NoteStore.shared
    )
}


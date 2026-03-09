// VerseView.swift
// Individual verse display with selection, highlighting, and context menu

import SwiftUI

struct VerseView: View {
    let verse: BibleVerse
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var noteStore = NoteStore.shared
    let fontSize: Double
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    init(verse: BibleVerse, settingsStore: SettingsStore, fontSize: Double, isSelected: Bool, onTap: @escaping () -> Void, onLongPress: (() -> Void)? = nil) {
        self.verse = verse
        self.settingsStore = settingsStore
        self.fontSize = fontSize
        self.isSelected = isSelected
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var isSaved: Bool {
        noteStore.isVerseSaved(book: verse.book, chapter: verse.chapter, verse: verse.verseNumber)
    }
    
    var primaryText: String {
        verse.text(for: settingsStore.primaryLanguage)
    }
    
    var secondaryText: String {
        verse.text(for: settingsStore.secondaryLanguage)
    }
    
    private func formatVerseForShare(_ verse: BibleVerse) -> String {
        VerseShareFormatter.format(verse, language: settingsStore.primaryLanguage)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Verse number with save indicator
            HStack(spacing: 4) {
                Text("\(verse.verseNumber)")
                    .font(.system(size: fontSize, weight: .semibold, design: .serif))
                    .foregroundColor(isSaved ? AppTheme.accentColor : AppTheme.verseNumberColor)
                
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: fontSize * 0.6))
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            .frame(minWidth: 28, alignment: .leading)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: settingsStore.lineSpacing) {
                // Primary language text
                if !primaryText.isEmpty && settingsStore.primaryLanguage != .none {
                    Text(primaryText)
                        .font(.system(size: fontSize, design: .serif))
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(settingsStore.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Secondary language text (if not none and different from primary)
                if settingsStore.showSecondaryLanguage &&
                   !secondaryText.isEmpty && 
                   settingsStore.secondaryLanguage != .none &&
                   settingsStore.secondaryLanguage != settingsStore.primaryLanguage {
                    Text(secondaryText)
                        .font(.system(size: fontSize, design: .serif))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(settingsStore.lineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    AppTheme.verseSelectionGradient
                        .cornerRadius(8)
                } else if isSaved {
                    AppTheme.accentColor.opacity(0.15)
                        .cornerRadius(8)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            Group {
                if isSaved && !isSelected {
                    Rectangle()
                        .frame(width: 4)
                        .foregroundColor(AppTheme.accentColor)
                        .cornerRadius(2)
                } else {
                    Color.clear
                }
            },
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                // Copy verse
                let text = verse.text(for: settingsStore.primaryLanguage)
                let reference = "\(verse.book) \(verse.chapter):\(verse.verseNumber)"
                UIPasteboard.general.string = "\"\(text)\"\n- \(reference)"
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            ShareLink(item: formatVerseForShare(verse)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            if let onLongPress = onLongPress {
                Button {
                    onLongPress()
                } label: {
                    Label("Context", systemImage: "sparkles")
                }
            }
        }
    }
}

// VerseResultRow - Reusable view for displaying a single verse search result

import SwiftUI

struct VerseResultRow: View {
    let verse: RelatedVerse
    @ObservedObject var settingsStore: SettingsStore
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Reference (Headline)
                Text(verse.reference)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accentColor)
                
                // Text (Body)
                Text(verse.text)
                    .font(.body)
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                
                // Relevance (Footnote/Caption)
                Text(verse.relevance)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardGradient)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VerseResultRow(
        verse: RelatedVerse(
            book: "John",
            chapter: 3,
            verse: 16,
            reference: "John 3:16",
            text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            relevance: "This verse explains the core message of salvation."
        ),
        settingsStore: SettingsStore.shared,
        onTap: {}
    )
    .padding()
}

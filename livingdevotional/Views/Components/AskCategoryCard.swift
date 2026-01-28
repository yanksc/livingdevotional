// AskCategoryCard - Compact card component for ask categories

import SwiftUI

struct AskCategoryCard: View {
    let category: AskCategory
    let backgroundImage: String? // Optional custom background image
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    init(category: AskCategory, backgroundImage: String? = nil) {
        self.category = category
        self.backgroundImage = backgroundImage
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image from bg_serene folder - use custom background if provided, otherwise use category's imageName
            SereneBackgroundImage(filename: backgroundImage ?? category.imageName)
                .frame(width: 160, height: 180)
                .clipped()
            
            // Gradient overlay for text readability (bottom to top)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content overlay at bottom
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(category.localizedTitle(for: settingsStore.appLanguage))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Question count badge
                Text("\(category.questions.count) \(settingsStore.appLanguage == .chineseTraditional ? "問題" : settingsStore.appLanguage == .chineseSimplified ? "问题" : "questions")")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 160, height: 180)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HStack {
        AskCategoryCard(category: AskCategoryStore.shared.categories[0], backgroundImage: "SereneBackground1")
        AskCategoryCard(category: AskCategoryStore.shared.categories[1], backgroundImage: "SereneBackground2")
    }
    .padding()
}

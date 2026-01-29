// AskAnyQuestionCard - Card component for asking any question

import SwiftUI

struct AskAnyQuestionCard: View {
    let backgroundImage: String
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        ZStack(alignment: .center) {
            // Background image from bg_serene folder
            SereneBackgroundImage(filename: backgroundImage)
                .frame(width: 160, height: 180)
                .clipped()
            
            // Gradient overlay for text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content centered
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "questionmark.bubble.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Title
                Text(localizedTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(16)
        }
        .frame(width: 160, height: 180)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var localizedTitle: String {
        switch settingsStore.appLanguage {
        case .chineseTraditional:
            return "問任何問題"
        case .chineseSimplified:
            return "问任何问题"
        default:
            return "Ask Any Question"
        }
    }
}

#Preview {
    AskAnyQuestionCard(backgroundImage: "SereneBackground1")
        .padding()
}

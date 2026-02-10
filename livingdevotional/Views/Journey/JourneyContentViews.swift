// JourneyContentViews.swift
// Content views for the Journey feature: encouragement, path status, summary, verse, highlights, next step

import SwiftUI

// MARK: - Encouragement Hero View (Short 1-sentence encouragement with light serene background)

struct EncouragementHeroView: View {
    let encouragement: String
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    // Use a consistent background based on encouragement text hash
    private var backgroundFilename: String {
        let hash = abs(encouragement.hashValue)
        let index = hash % backgroundManager.count
        return backgroundManager.background(at: index)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(encouragement)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Serene background image - lighter overlay for short text
                SereneBackgroundImage(
                    filename: backgroundFilename,
                    targetSize: CGSize(width: UIScreen.main.bounds.width, height: 120)
                )
                .aspectRatio(contentMode: .fill)
                
                // Very light gradient overlay - just enough for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipped()
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Path Status Card View (Redesigned with dark serene background, centered text, no icon)

struct PathStatusCardView: View {
    let pathStatus: PathStatus
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    // Randomly select a dark serene background (1-5) - persisted across renders
    @State private var backgroundImageName: String = {
        let randomIndex = Int.random(in: 1...5)
        return "dark_serene_\(randomIndex)"
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Centered title - creative status based on user's journey
            Text(pathStatus.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
            
            // Expanded description - ~60 words of in-context analysis
            Text(pathStatus.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Dark serene background image
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                
                // Subtle overlay for text readability
                Color.black.opacity(0.35)
            }
        )
        .clipped()
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Journey Summary View

struct JourneySummaryView: View {
    let summary: String
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settingsStore.appLanguage == .chineseTraditional ? "歷程摘要" : "Journey Summary")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.secondaryText)
                .textCase(.uppercase)
            
            Text(summary)
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.sectionBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Recommended Verse View

struct RecommendedVerseView: View {
    let verse: RecommendedVerse
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    // Use a consistent background based on verse reference hash
    private var backgroundFilename: String {
        let hash = abs(verse.reference.hashValue)
        let index = hash % backgroundManager.count
        return backgroundManager.background(at: index)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(settingsStore.appLanguage == .chineseTraditional ? "為你推薦" : "Recommended for You")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .textCase(.uppercase)
                Spacer()
            }
            
            Text("\"\(verse.text)\"")
                .font(.body)
                .italic()
                .foregroundColor(.white)
                .lineSpacing(4)
            
            HStack {
                Text(verse.reference)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text(verse.reason)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Serene background image
                SereneBackgroundImage(
                    filename: backgroundFilename,
                    targetSize: CGSize(width: UIScreen.main.bounds.width, height: 180)
                )
                .aspectRatio(contentMode: .fill)
                
                // Dark gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.65),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipped()
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Path Highlights View (Collapsible)

struct PathHighlightsView: View {
    let highlights: [PathHighlight]
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - tappable to expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "路徑亮點" : "Path Highlights")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.cardGradient)
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(highlights) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Text(highlight.emoji)
                                .font(.title3)
                            
                            Text(highlight.fact)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(2)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.sectionBackground.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Next Step View

struct NextStepView: View {
    let nextStep: String
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsStore.appLanguage == .chineseTraditional ? "下一步" : "Next Step")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.secondaryText)
                    .textCase(.uppercase)
                
                Text(nextStep)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.accentColor.opacity(0.1), AppTheme.primaryPurple.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
    }
}

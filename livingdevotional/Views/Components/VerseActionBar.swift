// VerseActionBar - Action buttons displayed underneath selected verse

import SwiftUI

struct VerseActionBar: View {
    let verse: BibleVerse
    @ObservedObject var settingsStore: SettingsStore
    let onCopy: () -> Void
    let onShare: () -> Void
    let onAIInsight: () -> Void
    let onAIReflect: () -> Void
    let onAIPray: () -> Void
    let onAIAsk: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            AppTheme.accentColor.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 8)
            
            // Action buttons - Two row layout for better space utilization
            VStack(spacing: 8) {
                // Top row: Verse action buttons
                HStack(spacing: 8) {
                    // Insight button
                    Button(action: onAIInsight) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(settingsStore.appLanguage.localizedString("AIInsight"))
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.primaryPurple)
                        )
                    }
                    
                    // Reflect button
                    Button(action: onAIReflect) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(settingsStore.appLanguage.localizedString("AIReflect"))
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.8, green: 0.4, blue: 0.6))
                        )
                    }
                    
                    // Pray button
                    Button(action: onAIPray) {
                        HStack(spacing: 4) {
                            Image(systemName: "hands.clap.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(settingsStore.appLanguage.localizedString("AIPray"))
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.3, green: 0.7, blue: 0.5))
                        )
                    }
                    
                    // Ask button
                    Button(action: onAIAsk) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(settingsStore.appLanguage == .chineseTraditional ? "問答" : "Ask")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                }
                
                // Bottom row: Action buttons
                HStack(spacing: 8) {
                    // Copy button
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                    }
                    
                    // Share button
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                    }
                    
                    // Save button
                    Button(action: onSave) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.cardGradient(darkMode: settingsStore.isDarkMode))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

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
    let onRelated: () -> Void
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
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "理解" : "Context")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Reflect button
                    Button(action: onAIReflect) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "反思" : "Reflect")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Pray button
                    Button(action: onAIPray) {
                        HStack(spacing: 4) {
                            Image(systemName: "hands.clap.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "禱告" : "Pray")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Ask button
                    Button(action: onAIAsk) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "問答" : "Ask")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
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
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "複製" : "Copy")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Share button
                    Button(action: onShare) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "分享" : "Share")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Related button
                    Button(action: onRelated) {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "相關" : "Related")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
                        )
                    }
                    
                    // Save button
                    Button(action: onSave) {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 14, height: 14)
                            Text(settingsStore.appLanguage == .chineseTraditional ? "儲存" : "Save")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.accentColor)
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

// PrayerEncouragementView.swift
// Shown when user hasn't prayed yet and selects "No"

import SwiftUI

struct PrayerEncouragementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    var onPrayNow: () -> Void
    
    // Simple list of encouraging verses for prayer
    private let encouragingVerses: [(book: String, chapter: Int, verse: Int, textEn: String, textZh: String)] = [
        ("Philippians", 4, 6, "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.", "應當一無掛慮，只要凡事藉著禱告、祈求，和感謝，將你們所要的告訴神。"),
        ("1 Thessalonians", 5, 17, "Pray without ceasing.", "不住地禱告。"),
        ("Matthew", 6, 6, "But when you pray, go into your room, close the door and pray to your Father, who is unseen. Then your Father, who sees what is done in secret, will reward you.", "你禱告的時候，要進你的內屋，關上門，禱告你在暗中的父，你父在暗中察看，必然報答你。"),
        ("Jeremiah", 29, 12, "Then you will call on me and come and pray to me, and I will listen to you.", "你們要呼求我，禱告我，我就應允你們。")
    ]
    
    @State private var selectedVerse: (book: String, chapter: Int, verse: Int, textEn: String, textZh: String) = ("Philippians", 4, 6, "Do not be anxious about anything...", "")
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Top spacing
                    Spacer()
                        .frame(height: 40)
                    
                    // Icon
                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor)
                        .padding(.bottom, 16)
                    
                    // Title
                    Text(settingsStore.appLanguage == .chineseTraditional ? "與神對話的時間" : "Time for Prayer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text(settingsStore.appLanguage == .chineseTraditional ? "禱告是我們與神連結的橋樑。哪怕只是簡短的幾句話，神都在傾聽。" : "Prayer connects us with God. Even a few short words are heard by Him.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal)
                    
                    // Verse Card
                    VStack(spacing: 12) {
                        // Show verse in primary language
                        let isChinese = settingsStore.appLanguage.resolvedLanguageCode() == "zh-Hant"
                        Text(isChinese ? selectedVerse.textZh : selectedVerse.textEn)
                            .font(settingsStore.selectedFont.font(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                        
                        // Show secondary language if enabled
                        if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                            let showSecondaryChinese = (settingsStore.secondaryLanguage == .cuv || settingsStore.secondaryLanguage == .cu1)
                            Text(showSecondaryChinese ? selectedVerse.textZh : selectedVerse.textEn)
                                .font(settingsStore.selectedFont.font(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        
                        Text("\(BibleData.localizedBookName(selectedVerse.book, language: settingsStore.primaryLanguage)) \(selectedVerse.chapter):\(selectedVerse.verse)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentColor)
                            .padding(.top, 8)
                    }
                    .padding(24)
                    .background(AppTheme.cardGradient)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            onPrayNow()
                            dismiss()
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "我現在禱告" : "I'll Pray Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text(settingsStore.appLanguage == .chineseTraditional ? "稍後再說" : "Maybe Later")
                                .font(.headline)
                                .foregroundColor(AppTheme.secondaryText)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .onAppear {
            selectedVerse = encouragingVerses.randomElement()!
        }
    }
}

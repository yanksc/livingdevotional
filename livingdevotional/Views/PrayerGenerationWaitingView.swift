// PrayerGenerationWaitingView.swift
// Calming waiting screen during prayer generation

import SwiftUI

struct PrayerGenerationWaitingView: View {
    let verse: DailyVerse?
    let focus: PrayerFocus?
    let emotionalNeed: EmotionalNeed?
    var prayerIntent: PrayerIntent? = nil
    
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var currentCalmingWordIndex = 0
    @State private var verseOpacity: Double = 0.0
    
    private var calmingWords: [String] {
        let languageCode = settingsStore.appLanguage.resolvedLanguageCode()
        let isSimplified = languageCode == "zh-Hans"
        let isChinese = languageCode == "zh-Hans" || languageCode == "zh-Hant"
        
        // Intent-specific calming words (pray for me = intercessory; help me pray = guided)
        if let intent = prayerIntent {
            switch intent {
            case .prayForMe:
                if isSimplified {
                    return [
                        "我们为你祷告...",
                        "将你交托给神...",
                        "神必看顾你...",
                        "在祷告中等候..."
                    ]
                } else if isChinese {
                    return [
                        "我們為你禱告...",
                        "將你交託給神...",
                        "神必看顧你...",
                        "在禱告中等候..."
                    ]
                } else {
                    return [
                        "We are praying for you...",
                        "Lifting you to the Lord...",
                        "He will watch over you...",
                        "Waiting in prayer..."
                    ]
                }
            case .helpMePray:
                if isSimplified {
                    return [
                        "为你预备祷告文...",
                        "将你的心归向神...",
                        "在经文中寻见主...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "為你預備禱告文...",
                        "將你的心歸向神...",
                        "在經文中尋見主...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Preparing your prayer...",
                        "Turn your heart to God...",
                        "Finding Him in His Word...",
                        "Wait quietly..."
                    ]
                }
            }
        }
        
        // Determine words based on focus or emotional need
        if let need = emotionalNeed {
            switch need {
            case .peace:
                if isSimplified {
                    return [
                        "将你的重担卸给神...",
                        "祂必使你安然居住...",
                        "在祂里面有平安...",
                        "静静地等候..."
                    ]
                } else if isChinese {
                    return [
                        "將你的重擔卸給神...",
                        "祂必使你安然居住...",
                        "在祂裡面有平安...",
                        "靜靜地等候..."
                    ]
                } else {
                    return [
                        "Cast your cares on Him...",
                        "He will give you rest...",
                        "Peace be with you...",
                        "Rest in His presence..."
                    ]
                }
            case .wisdom:
                if isSimplified {
                    return [
                        "寻求祂的智慧...",
                        "祂必指引你的路...",
                        "将你的心归向神...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "尋求祂的智慧...",
                        "祂必指引你的路...",
                        "將你的心歸向神...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Seek His wisdom...",
                        "He will guide your path...",
                        "Turn your heart to God...",
                        "Wait quietly..."
                    ]
                }
            case .strength:
                if isSimplified {
                    return [
                        "祂是你的力量...",
                        "靠主得刚强...",
                        "祂必加添力量...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "祂是你的力量...",
                        "靠主得剛強...",
                        "祂必加添力量...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "He is your strength...",
                        "Be strong in the Lord...",
                        "He will renew your strength...",
                        "Wait patiently..."
                    ]
                }
            case .hope:
                if isSimplified {
                    return [
                        "在祂里面有盼望...",
                        "祂的应许永不改变...",
                        "仰望祂的慈爱...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "在祂裡面有盼望...",
                        "祂的應許永不改變...",
                        "仰望祂的慈愛...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Hope is in Him...",
                        "His promises never fail...",
                        "Look to His love...",
                        "Wait with hope..."
                    ]
                }
            case .forgiveness:
                if isSimplified {
                    return [
                        "祂的恩典够用...",
                        "在祂里面有医治...",
                        "祂的爱遮盖一切...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "祂的恩典夠用...",
                        "在祂裡面有醫治...",
                        "祂的愛遮蓋一切...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "His grace is sufficient...",
                        "Healing is in Him...",
                        "His love covers all...",
                        "Rest in His grace..."
                    ]
                }
            case .other:
                if isSimplified {
                    return [
                        "亲近神...",
                        "祂必亲近你...",
                        "安静等候...",
                        "在祂里面有平安..."
                    ]
                } else if isChinese {
                    return [
                        "親近神...",
                        "祂必親近你...",
                        "安靜等候...",
                        "在祂裡面有平安..."
                    ]
                } else {
                    return [
                        "Draw near to God...",
                        "He will draw near to you...",
                        "Wait quietly...",
                        "Peace is in Him..."
                    ]
                }
            }
        } else if let focus = focus {
            switch focus {
            case .worry:
                if isSimplified {
                    return [
                        "将一切忧虑卸给神...",
                        "祂必顾念你...",
                        "不要忧虑...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "將一切憂慮卸給神...",
                        "祂必顧念你...",
                        "不要憂慮...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Cast all anxiety on Him...",
                        "He cares for you...",
                        "Do not worry...",
                        "Rest in His care..."
                    ]
                }
            case .gratitude:
                if isSimplified {
                    return [
                        "感谢祂的恩典...",
                        "数算祂的恩惠...",
                        "赞美祂的名...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "感謝祂的恩典...",
                        "數算祂的恩惠...",
                        "讚美祂的名...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Give thanks to Him...",
                        "Count your blessings...",
                        "Praise His name...",
                        "Rest in gratitude..."
                    ]
                }
            case .guidance:
                if isSimplified {
                    return [
                        "寻求祂的引导...",
                        "祂必指示你的路...",
                        "将你的道路交托祂...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "尋求祂的引導...",
                        "祂必指示你的路...",
                        "將你的道路交託祂...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "Seek His guidance...",
                        "He will direct your path...",
                        "Commit your way to Him...",
                        "Wait for His leading..."
                    ]
                }
            case .strength:
                if isSimplified {
                    return [
                        "祂是你的力量...",
                        "靠主得刚强...",
                        "祂必加添力量...",
                        "安静等候..."
                    ]
                } else if isChinese {
                    return [
                        "祂是你的力量...",
                        "靠主得剛強...",
                        "祂必加添力量...",
                        "安靜等候..."
                    ]
                } else {
                    return [
                        "He is your strength...",
                        "Be strong in the Lord...",
                        "He will renew you...",
                        "Wait in strength..."
                    ]
                }
            case .recentFocus:
                if isSimplified {
                    return [
                        "回顾最近的关注...",
                        "将一切交托给神...",
                        "安静等候...",
                        "在祂里面有平安..."
                    ]
                } else if isChinese {
                    return [
                        "回顧最近的關注...",
                        "將一切交託給神...",
                        "安靜等候...",
                        "在祂裡面有平安..."
                    ]
                } else {
                    return [
                        "Reflect on recent focus...",
                        "Commit all to God...",
                        "Wait quietly...",
                        "Peace is in Him..."
                    ]
                }
            case .custom:
                if isSimplified {
                    return [
                        "将你的心愿告诉神...",
                        "祂必垂听你的祷告...",
                        "安静等候...",
                        "在祂里面有平安..."
                    ]
                } else if isChinese {
                    return [
                        "將你的心願告訴神...",
                        "祂必垂聽你的禱告...",
                        "安靜等候...",
                        "在祂裡面有平安..."
                    ]
                } else {
                    return [
                        "Tell God your heart's desire...",
                        "He will hear your prayer...",
                        "Wait quietly...",
                        "Peace is in Him..."
                    ]
                }
            }
        } else {
            // Default calming words
            if isSimplified {
                return [
                    "亲近神...",
                    "祂必亲近你...",
                    "安静等候...",
                    "在祂里面有平安..."
                ]
            } else if isChinese {
                return [
                    "親近神...",
                    "祂必親近你...",
                    "安靜等候...",
                    "在祂裡面有平安..."
                ]
            } else {
                return [
                    "Draw near to God...",
                    "He will draw near to you...",
                    "Wait quietly...",
                    "Peace is in Him..."
                ]
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geometry.size.height * 0.35)
                
                VStack(spacing: 40) {
                        // Verse display with fade-in animation
                        if let verse = verse {
                            VStack(spacing: 16) {
                                Text(verse.text(for: settingsStore.primaryLanguage))
                                    .font(.system(size: 22, weight: .medium, design: .serif))
                                    .foregroundColor(.white.opacity(0.95))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(8)
                                    .padding(.horizontal, 32)
                                    .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                                
                                if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                                    Text(verse.text(for: settingsStore.secondaryLanguage))
                                        .font(.system(size: 18, design: .serif))
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(6)
                                        .padding(.horizontal, 32)
                                        .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                                }
                                
                                Text("\(BibleData.localizedBookName(verse.book, language: settingsStore.primaryLanguage)) \(verse.chapter):\(verse.verseNumber)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                            }
                            .opacity(verseOpacity)
                            .transition(.opacity)
                        }
                        
                        // Calming words
                        Text(calmingWords[currentCalmingWordIndex])
                            .font(.title3)
                            .fontWeight(.light)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                    .frame(height: geometry.size.height * 0.65)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            // Animate verse fade-in
            if verse != nil {
                withAnimation(.easeIn(duration: 2.0)) {
                    verseOpacity = 1.0
                }
            }
            
            // Cycle through calming words
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentCalmingWordIndex = (currentCalmingWordIndex + 1) % calmingWords.count
                }
            }
        }
    }
}

// NotificationContentGenerator - Generates personalized notification content based on user behavior

import Foundation
import UserNotifications

class NotificationContentGenerator {
    
    private var settingsStore: SettingsStore { SettingsStore.shared }
    private var checkInStore: CheckInStore { CheckInStore.shared }
    private var progressStore: ProgressStore { ProgressStore.shared }
    private var chatStore: ChatStore { ChatStore.shared }
    private var noteStore: NoteStore { NoteStore.shared }
    
    private var isChinese: Bool {
        settingsStore.appLanguage == .chineseTraditional ||
        (settingsStore.appLanguage == .system && Locale.preferredLanguages.first?.hasPrefix("zh") == true)
    }
    
    // MARK: - Morning Devotional
    
    func generateMorningContent() async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        let streak = checkInStore.currentStreak
        let hasReadingProgress = progressStore.currentBook != nil
        
        if streak > 0 && hasReadingProgress {
            // Active reader with streak - anchor on their reading progress
            let book = progressStore.currentBook ?? ""
            let chapter = progressStore.currentChapter ?? 1
            let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
            
            if isChinese {
                content.title = "第 \(streak) 天"
                content.body = "繼續閱讀 \(localizedBook) 第\(chapter)章"
            } else {
                content.title = "Day \(streak)"
                content.body = "Continue reading \(localizedBook) \(chapter)"
            }
            
        } else if streak > 2 {
            // Has good streak but no specific reading progress
            if isChinese {
                content.title = "第 \(streak) 天"
                content.body = "保持與神親近的時間"
            } else {
                content.title = "Day \(streak)"
                content.body = "Keep your time with God going"
            }
            
        } else {
            // New or casual user - simple daily verse prompt
            if isChinese {
                content.title = "新的一天"
                content.body = "今天的經文已經為您準備好了"
            } else {
                content.title = "A New Day"
                content.body = "Today's verse is waiting for you"
            }
        }
        
        return content
    }
    
    // MARK: - Prayer Reminder
    
    func generatePrayerReminderContent() async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        let hasPrayed = checkInStore.hasPrayedToday
        let today = Calendar.current.startOfDay(for: Date())
        let todayRecord = checkInStore.getRecord(for: today)
        let hasOpenedApp = todayRecord?.hasOpenedApp ?? false
        
        // If already prayed, return empty content (will be filtered out)
        if hasPrayed {
            return content
        }
        
        if hasOpenedApp {
            // Opened app but didn't pray - anchor on their reading
            if let book = progressStore.currentBook {
                let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                
                if isChinese {
                    content.title = "結束這一天"
                    content.body = "您今天讀了 \(localizedBook)。花一點時間為此禱告"
                } else {
                    content.title = "End Your Day"
                    content.body = "You read \(localizedBook) today. Take a moment to pray over it"
                }
            } else {
                // Opened app but no specific book
                if isChinese {
                    content.title = "結束這一天"
                    content.body = "您今天讀了聖經。花一點時間禱告"
                } else {
                    content.title = "End Your Day"
                    content.body = "You read Scripture today. Take a moment to pray"
                }
            }
        } else {
            // Didn't open app today - gentle reminder
            if isChinese {
                content.title = "睡前時刻"
                content.body = "花一分鐘安靜禱告"
            } else {
                content.title = "Before You Sleep"
                content.body = "A quiet moment with God"
            }
        }
        
        return content
    }
    
    // MARK: - Streak Protection
    
    func generateStreakProtectionContent(streak: Int) async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        if isChinese {
            content.title = "別讓連續紀錄中斷"
            content.body = "您已經連續 \(streak) 天了。只需 1 分鐘就能繼續"
        } else {
            content.title = "Don't Lose Your Streak"
            content.body = "You're on a \(streak)-day streak. Just 1 minute to check in"
        }
        
        return content
    }
    
    // MARK: - Deep Engagement
    
    func generateAIEngagementContent() async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // Priority 1: Recent chat sessions (within 7 days)
        if let recentSession = chatStore.sessions.first,
           let book = recentSession.book,
           let chapter = recentSession.chapter,
           let verseNumber = recentSession.verseNumber {
            let daysSince = Calendar.current.dateComponents([.day], from: recentSession.updatedAt, to: Date()).day ?? 0
            if daysSince <= 7 {
                let localizedBook = BibleData.localizedBookName(book, language: settingsStore.primaryLanguage)
                
                if isChinese {
                    content.title = "繼續您的對話"
                    content.body = "還在思考 \(localizedBook) \(chapter):\(verseNumber) 嗎？問另一個問題"
                } else {
                    content.title = "Continue Your Conversation"
                    content.body = "Still thinking about \(localizedBook) \(chapter):\(verseNumber)? Ask another question"
                }
                return content
            }
        }
        
        // Priority 2: Saved verses
        if let savedVerse = noteStore.savedVerses.first {
            let localizedBook = BibleData.localizedBookName(savedVerse.book, language: settingsStore.primaryLanguage)
            
            if savedVerse.content.isEmpty {
                // Saved but no notes - encourage exploration
                if isChinese {
                    content.title = "深入了解您收藏的經文"
                    content.body = "回顧 \(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
                } else {
                    content.title = "Explore Your Saved Verse"
                    content.body = "Revisit \(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
                }
            } else {
                // Has notes - encourage revisit
                if isChinese {
                    content.title = "回顧您的靈修筆記"
                    content.body = "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
                } else {
                    content.title = "Revisit Your Reflection"
                    content.body = "\(localizedBook) \(savedVerse.chapter):\(savedVerse.verse)"
                }
            }
            return content
        }
        
        // Fallback: Generic encouragement
        if isChinese {
            content.title = "今天有什麼問題嗎"
            content.body = "隨時可以詢問關於聖經的問題"
        } else {
            content.title = "Have a Question Today"
            content.body = "Ask anything about today's reading"
        }
        
        return content
    }
    
    // MARK: - Weekly Summary
    
    func generateWeeklySummaryContent() async -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // Calculate weekly stats
        let calendar = Calendar.current
        let today = Date()
        var daysOpened = 0
        var prayerDays = 0
        
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
               let record = checkInStore.getRecord(for: date) {
                if record.hasOpenedApp { daysOpened += 1 }
                if record.hasPrayed { prayerDays += 1 }
            }
        }
        
        let streak = checkInStore.currentStreak
        
        if isChinese {
            content.title = "本週回顧"
            content.body = "閱讀 \(daysOpened) 天・禱告 \(prayerDays) 次・連續 \(streak) 天"
        } else {
            content.title = "Your Week in Review"
            content.body = "\(daysOpened) days reading · \(prayerDays) prayers · \(streak) day streak"
        }
        
        return content
    }
}

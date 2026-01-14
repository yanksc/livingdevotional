// NotificationManager - Manages notification scheduling and permissions

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private let contentGenerator = NotificationContentGenerator()
    
    private var settingsStore: SettingsStore { SettingsStore.shared }
    
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule All Notifications
    
    func scheduleAllNotifications() {
        guard settingsStore.notificationsEnabled else {
            // If disabled, remove all pending notifications
            center.removeAllPendingNotificationRequests()
            return
        }
        
        Task {
            // Clear existing scheduled notifications
            center.removeAllPendingNotificationRequests()
            
            // Schedule each type
            await scheduleMorningDevotional()
            await schedulePrayerReminder()
            
            if settingsStore.streakProtectionEnabled {
                await scheduleStreakProtection()
            }
            
            await scheduleAIEngagement()
            await scheduleWeeklySummary()
        }
    }
    
    // MARK: - Morning Devotional (Daily, user-configurable time)
    
    private func scheduleMorningDevotional() async {
        let content = await contentGenerator.generateMorningContent()
        
        // Skip if content is empty (shouldn't happen for morning, but safety check)
        guard !content.title.isEmpty else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settingsStore.morningTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "morning_devotional",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling morning devotional: \(error)")
        }
    }
    
    // MARK: - Prayer Reminder (Daily, user-configurable time)
    
    private func schedulePrayerReminder() async {
        // Generate content dynamically - this will check prayer status at scheduling time
        // Note: Since notifications are scheduled ahead, we'll need to refresh this daily
        // For now, we schedule it and the content generator will check status
        let content = await contentGenerator.generatePrayerReminderContent()
        
        // Skip if already prayed (content will be empty)
        guard !content.title.isEmpty else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settingsStore.eveningTime)
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "prayer_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling prayer reminder: \(error)")
        }
    }
    
    // MARK: - Streak Protection (6:00 PM if streak is at risk)
    
    private func scheduleStreakProtection() async {
        let streak = CheckInStore.shared.currentStreak
        guard streak >= 3 else { return } // Only for users with meaningful streaks
        
        let content = await contentGenerator.generateStreakProtectionContent(streak: streak)
        
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_protection",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling streak protection: \(error)")
        }
    }
    
    // MARK: - Deep Engagement (Tue, Thu, Sat at 2:00 PM)
    
    private func scheduleAIEngagement() async {
        let weekdays = [3, 5, 7] // Tuesday, Thursday, Saturday
        
        for (index, weekday) in weekdays.enumerated() {
            let content = await contentGenerator.generateAIEngagementContent()
            
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = 14
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "ai_engagement_\(index)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Error scheduling deep engagement: \(error)")
            }
        }
    }
    
    // MARK: - Weekly Summary (Sunday 9:00 AM)
    
    private func scheduleWeeklySummary() async {
        let content = await contentGenerator.generateWeeklySummaryContent()
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Error scheduling weekly summary: \(error)")
        }
    }
    
    // MARK: - Refresh Notifications
    
    func refreshNotifications() {
        // Reschedule all notifications with fresh content based on current state
        scheduleAllNotifications()
    }
    
    // MARK: - Cancel Specific Notification Types
    
    func cancelPrayerReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["prayer_reminder"])
    }
    
    func cancelStreakProtection() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_protection"])
    }
}

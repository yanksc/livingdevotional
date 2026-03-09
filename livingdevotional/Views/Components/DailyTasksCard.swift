// DailyTasksCard.swift
// Component showing daily tasks (Read Scripture + Pray) with completion status

import SwiftUI

struct DailyTasksCard: View {
    @ObservedObject var checkInStore: CheckInStore
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var progressStore = ProgressStore.shared
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = HomeViewModel()
    @State private var showEncouragement = false
    
    var tasksCompleted: Int {
        var count = 1 // "Open App" is always completed
        if checkInStore.hasReadToday { count += 1 }
        if checkInStore.hasPrayedToday { count += 1 }
        return count
    }
    
    var allTasksCompleted: Bool {
        tasksCompleted == 3
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(settingsStore.appLanguage == .chineseTraditional ? "今日任務" : "Today's Tasks")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 4) {
                    Text("\(tasksCompleted)/3")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(allTasksCompleted ? AppTheme.accentColor : AppTheme.secondaryText)
                    
                    if allTasksCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            // Task list
            VStack(spacing: 12) {
                // Open App Task (always completed)
                TaskRow(
                    title: settingsStore.appLanguage == .chineseTraditional ? "開啟 Living Path" : "Open Living Path",
                    icon: "app.fill",
                    isCompleted: true, // Always completed when viewing the app
                    action: { }, // No action needed
                    settingsStore: settingsStore
                )
                
                // Read Scripture Task
                TaskRow(
                    title: settingsStore.appLanguage == .chineseTraditional ? "讀經" : "Read Scripture",
                    icon: "book.fill",
                    isCompleted: checkInStore.hasReadToday,
                    action: {
                        // Navigate to verse of the day or continue reading
                        if let verse = viewModel.verseOfTheDay,
                           let book = BibleData.book(named: verse.book) {
                            router.navigateToReading(book: book, chapter: verse.chapter, verse: verse.verseNumber)
                        } else if let book = progressStore.currentBook,
                                  let chapter = progressStore.currentChapter,
                                  let bibleBook = BibleData.book(named: book) {
                            router.navigateToReading(book: bibleBook, chapter: chapter, verse: nil)
                        }
                    },
                    settingsStore: settingsStore
                )
                
                // Pray Task
                TaskRow(
                    title: settingsStore.appLanguage == .chineseTraditional ? "禱告" : "Pray",
                    icon: "hands.sparkles.fill",
                    isCompleted: checkInStore.hasPrayedToday,
                    action: {
                        if !checkInStore.hasPrayedToday {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                checkInStore.recordPrayer()
                            }
                        }
                    },
                    settingsStore: settingsStore
                )
            }
            
            // Completion celebration
            if allTasksCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text(settingsStore.appLanguage == .chineseTraditional ? "今日任務已完成！" : "All tasks completed!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppTheme.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            viewModel.loadHomeData()
        }
    }
}

struct TaskRow: View {
    let title: String
    let icon: String
    let isCompleted: Bool
    let action: () -> Void
    @ObservedObject var settingsStore: SettingsStore
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .fill(isCompleted ? AppTheme.accentColor : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isCompleted ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.3), lineWidth: 2)
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isCompleted ? AppTheme.accentColor : AppTheme.secondaryText)
                    .frame(width: 24)
                
                // Title
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? AppTheme.primaryText.opacity(0.7) : AppTheme.primaryText)
                    .strikethrough(isCompleted)
                
                Spacer()
                
                // Arrow (if not completed)
                if !isCompleted {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText.opacity(0.5))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isCompleted ? AppTheme.accentColor.opacity(0.05) : AppTheme.secondaryText.opacity(0.03))
            .cornerRadius(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    DailyTasksCard(checkInStore: CheckInStore.shared)
        .environmentObject(AppRouter())
        .padding()
}

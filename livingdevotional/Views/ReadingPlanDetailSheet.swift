// ReadingPlanDetailSheet - Detail view for reading plans

import SwiftUI

struct ReadingPlanDetailSheet: View {
    let plan: ReadingPlan
    @ObservedObject private var planStore = ReadingPlanStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    
    @State private var progress: ReadingPlanProgress?
    
    var planProgress: ReadingPlanProgress? {
        planStore.getProgress(for: plan.id)
    }
    
    var progressPercentage: Double {
        planStore.getProgressPercentage(for: plan.id)
    }
    
    var currentDayReading: ReadingPlanDay? {
        planStore.getTodayReading(for: plan.id)
    }
    
    var isStarted: Bool {
        planProgress?.isStarted ?? false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with large image
                        VStack(spacing: 0) {
                            // Full-width header image - larger and more prominent
                            ZStack(alignment: .bottomLeading) {
                                Image(plan.imageName, bundle: .main)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 350)
                                    .clipped()
                                
                                // Gradient overlay for text readability
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.4),
                                        Color.clear
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                
                                // Title overlay on image
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(plan.title)
                                        .font(.system(size: 32, weight: .bold, design: .serif))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 3)
                                    
                                    // Duration badge
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                        Text("\(plan.duration) \(settingsStore.appLanguage.localizedString("days"))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Enhanced description section
                            VStack(alignment: .leading, spacing: 16) {
                                Text(plan.description)
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.leading)
                                
                                // Why this plan is worth reading
                                if let extendedDescription = plan.extendedDescription {
                                    Text(extendedDescription)
                                        .font(.system(size: 16, weight: .regular, design: .serif))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .lineSpacing(5)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Progress visualization
                        if isStarted {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(settingsStore.appLanguage.localizedString("Progress"))
                                        .font(.headline)
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(progressPercentage))%")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.accentColor)
                                }
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // Background
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppTheme.secondaryText.opacity(0.1))
                                            .frame(height: 12)
                                        
                                        // Progress
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    colors: [AppTheme.accentColor, AppTheme.primaryPurple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geometry.size.width * CGFloat(progressPercentage / 100), height: 12)
                                    }
                                }
                                .frame(height: 12)
                                
                                Text("\(planProgress?.completedDays.count ?? 0) / \(plan.duration) \(settingsStore.appLanguage.localizedString("daysCompleted"))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(16)
                            .background(AppTheme.cardGradient)
                            .cornerRadius(16)
                        }
                        
                        // Day-by-day breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text(settingsStore.appLanguage.localizedString("DailyReading"))
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            
                            VStack(spacing: 12) {
                                ForEach(plan.days) { day in
                                    DayRow(
                                        day: day,
                                        isCompleted: planProgress?.completedDays.contains(day.dayNumber) ?? false,
                                        isCurrentDay: planProgress?.currentDay == day.dayNumber - 1,
                                        settingsStore: settingsStore
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardGradient)
                        .cornerRadius(16)
                        
                        // CTA Button
                        Button(action: {
                            handleCTAAction()
                        }) {
                            HStack {
                                if isStarted {
                                    Image(systemName: "book.fill")
                                    Text(settingsStore.appLanguage.localizedString("ContinueReading"))
                                } else {
                                    Image(systemName: "play.fill")
                                    Text(settingsStore.appLanguage.localizedString("StartPlan"))
                                }
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.buttonGradient)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settingsStore.appLanguage.localizedString("Done")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            .toolbarBackground(AppTheme.backgroundGradient, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            progress = planProgress
        }
    }
    
    private func handleCTAAction() {
        if !isStarted {
            planStore.startPlan(plan.id)
        }
        
        // Navigate to today's reading
        if let todayReading = currentDayReading,
           let book = BibleData.book(named: todayReading.book) {
            router.navigateToReading(
                book: book,
                chapter: todayReading.chapter,
                verse: todayReading.verseStart
            )
            dismiss()
        }
    }
}

// MARK: - Day Row Component

struct DayRow: View {
    let day: ReadingPlanDay
    let isCompleted: Bool
    let isCurrentDay: Bool
    @ObservedObject var settingsStore: SettingsStore
    
    var body: some View {
        HStack(spacing: 12) {
            // Day number with checkmark
            ZStack {
                Circle()
                    .fill(isCompleted ? AppTheme.accentColor : (isCurrentDay ? AppTheme.accentColor.opacity(0.2) : Color.clear))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isCurrentDay ? AppTheme.accentColor : AppTheme.secondaryText.opacity(0.3), lineWidth: 2)
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(day.dayNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCurrentDay ? AppTheme.accentColor : AppTheme.secondaryText)
                }
            }
            
            // Reading info
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedReference)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(isCompleted ? AppTheme.primaryText.opacity(0.6) : AppTheme.primaryText)
                
                if let description = day.description {
                    Text(description)
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundColor(AppTheme.accentColor)
                        .padding(.top, 2)
                }
                
                // Chapter description explaining why it's worth reading
                if let chapterDescription = day.chapterDescription {
                    Text(chapterDescription)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if isCurrentDay && !isCompleted {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(AppTheme.accentColor)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(isCurrentDay ? AppTheme.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
    
    private var localizedReference: String {
        let localizedBook = BibleData.localizedBookName(day.book, language: settingsStore.primaryLanguage)
        let chapterPrefix = BibleData.localizedChapterText(language: settingsStore.primaryLanguage)
        
        if let verseStart = day.verseStart, let verseEnd = day.verseEnd {
            if chapterPrefix == "第" {
                return "\(localizedBook) \(chapterPrefix)\(day.chapter)章 \(verseStart)-\(verseEnd)"
            } else {
                return "\(localizedBook) \(chapterPrefix) \(day.chapter):\(verseStart)-\(verseEnd)"
            }
        } else {
            if chapterPrefix == "第" {
                return "\(localizedBook) \(chapterPrefix)\(day.chapter)章"
            } else {
                return "\(localizedBook) \(chapterPrefix) \(day.chapter)"
            }
        }
    }
}

#Preview {
    ReadingPlanDetailSheet(plan: ReadingPlanStore.shared.plans[0])
        .environmentObject(AppRouter())
}

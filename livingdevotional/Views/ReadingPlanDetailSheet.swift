// ReadingPlanDetailSheet - Detail view for reading plans

import SwiftUI

struct ReadingPlanDetailSheet: View {
    let plan: ReadingPlan
    @ObservedObject private var planStore = ReadingPlanStore.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
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
                        // Header with large image - full width, no padding
                        GeometryReader { geometry in
                            let imageHeight = UIScreen.main.bounds.height * 0.4
                            ZStack(alignment: .bottomLeading) {
                                SereneBackgroundImage(filename: backgroundManager.backgroundForPlan(planId: plan.id))
                                    .frame(width: geometry.size.width, height: imageHeight)
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
                                        .font(.system(size: 28, weight: .bold, design: .serif))
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
                                .padding(20)
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                        .ignoresSafeArea(edges: .top)
                        
                        // Description section with horizontal padding
                        VStack(alignment: .leading, spacing: 16) {
                            Text(plan.description)
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(5)
                                .multilineTextAlignment(.leading)
                            
                            // Why this plan is worth reading
                            if let extendedDescription = plan.extendedDescription {
                                Text(extendedDescription)
                                    .font(.system(size: 15, weight: .regular, design: .serif))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        
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
                                            .frame(width: max(0, geometry.size.width * CGFloat(progressPercentage / 100)), height: 12)
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
                            .padding(.horizontal, 16)
                        }
                        
                        // Day-by-day breakdown
                        DayByDaySection(
                            plan: plan,
                            planProgress: planProgress,
                            settingsStore: settingsStore
                        )
                        .padding(.horizontal, 16)
                        
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
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
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

// MARK: - Day By Day Section with Expandable Rows

struct DayByDaySection: View {
    let plan: ReadingPlan
    let planProgress: ReadingPlanProgress?
    @ObservedObject var settingsStore: SettingsStore
    
    // Track which days are expanded - start with current day expanded
    @State private var expandedDays: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse all button
            HStack {
                Text(settingsStore.appLanguage.localizedString("DailyReading"))
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Button(action: toggleAll) {
                    HStack(spacing: 4) {
                        Image(systemName: expandedDays.count == plan.days.count ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                            .font(.caption)
                        Text(expandedDays.count == plan.days.count ? 
                             (settingsStore.appLanguage == .chineseTraditional ? "收起全部" : 
                              settingsStore.appLanguage == .chineseSimplified ? "收起全部" : "Collapse All") :
                             (settingsStore.appLanguage == .chineseTraditional ? "展開全部" : 
                              settingsStore.appLanguage == .chineseSimplified ? "展开全部" : "Expand All"))
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(plan.days) { day in
                    ExpandableDayRow(
                        day: day,
                        isCompleted: planProgress?.completedDays.contains(day.dayNumber) ?? false,
                        isCurrentDay: planProgress?.currentDay == day.dayNumber - 1,
                        isExpanded: expandedDays.contains(day.dayNumber),
                        settingsStore: settingsStore,
                        onToggle: { toggleDay(day.dayNumber) }
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .onAppear {
            // Auto-expand current day
            if let currentDay = planProgress?.currentDay {
                expandedDays.insert(currentDay + 1)
            }
        }
    }
    
    private func toggleDay(_ dayNumber: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedDays.contains(dayNumber) {
                expandedDays.remove(dayNumber)
            } else {
                expandedDays.insert(dayNumber)
            }
        }
    }
    
    private func toggleAll() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedDays.count == plan.days.count {
                expandedDays.removeAll()
            } else {
                expandedDays = Set(plan.days.map { $0.dayNumber })
            }
        }
    }
}

// MARK: - Expandable Day Row Component

struct ExpandableDayRow: View {
    let day: ReadingPlanDay
    let isCompleted: Bool
    let isCurrentDay: Bool
    let isExpanded: Bool
    @ObservedObject var settingsStore: SettingsStore
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row - always visible
            Button(action: onToggle) {
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
                    
                    // Reading info - compact version
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedReference)
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(isCompleted ? AppTheme.primaryText.opacity(0.6) : AppTheme.primaryText)
                        
                        if let description = day.description {
                            Text(description)
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(AppTheme.accentColor)
                                .lineLimit(isExpanded ? nil : 1)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/collapse indicator or current day indicator
                    if day.chapterDescription != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    
                    if isCurrentDay && !isCompleted {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.title3)
                    }
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content - chapter description
            if isExpanded, let chapterDescription = day.chapterDescription {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(AppTheme.secondaryText.opacity(0.2))
                        .padding(.horizontal, 12)
                    
                    Text(chapterDescription)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(4)
                        .padding(.horizontal, 56) // Align with text above (12 + 32 + 12)
                        .padding(.vertical, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
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

// MARK: - Legacy Day Row Component (kept for compatibility)

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

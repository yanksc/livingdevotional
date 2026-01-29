// ReadingPlanWidget - Lock screen inline widget showing reading plan progress
//
// Supports: accessoryInline

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PlanEntry: TimelineEntry {
    let date: Date
    let planTitle: String?
    let currentDay: Int?
    let totalDays: Int?
    let todayReading: String?
    let streak: Int
    
    static var placeholder: PlanEntry {
        PlanEntry(
            date: Date(),
            planTitle: "Gospel of John",
            currentDay: 3,
            totalDays: 7,
            todayReading: "John 3",
            streak: 7
        )
    }
    
    /// Display text for inline widget
    var displayText: String {
        if let title = planTitle, let day = currentDay, let total = totalDays {
            // Truncate title if needed
            let shortTitle = title.count > 15 ? String(title.prefix(12)) + "..." : title
            return "Day \(day)/\(total) • \(shortTitle)"
        } else if streak > 0 {
            return "🔥 \(streak) day streak"
        } else {
            return "Living Path"
        }
    }
}

// MARK: - Timeline Provider

struct PlanProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlanEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PlanEntry) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = PlanEntry(
            date: Date(),
            planTitle: data.activePlanTitle,
            currentDay: data.activePlanDay,
            totalDays: data.activePlanTotal,
            todayReading: data.activePlanTodayReading,
            streak: data.currentStreak
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = PlanEntry(
            date: Date(),
            planTitle: data.activePlanTitle,
            currentDay: data.activePlanDay,
            totalDays: data.activePlanTotal,
            todayReading: data.activePlanTodayReading,
            streak: data.currentStreak
        )
        
        // Refresh at midnight or after 1 hour
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let oneHourLater = Date().addingTimeInterval(3600)
        let refreshDate = min(midnight, oneHourLater)
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct ReadingPlanWidget: Widget {
    let kind: String = "ReadingPlanWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlanProvider()) { entry in
            PlanWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reading Plan")
        .description("Track your reading plan progress")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Entry View

struct PlanWidgetEntryView: View {
    let entry: PlanEntry
    
    var body: some View {
        InlinePlanView(entry: entry)
    }
}

// MARK: - Inline View

struct InlinePlanView: View {
    let entry: PlanEntry
    
    var body: some View {
        HStack(spacing: 4) {
            if entry.planTitle != nil {
                Image(systemName: "book.fill")
            } else if entry.streak > 0 {
                Image(systemName: "flame.fill")
            }
            Text(entry.displayText)
        }
        .widgetURL(planURL)
    }
    
    private var planURL: URL? {
        if let planId = entry.planTitle {
            // URL encode the plan title for the deep link
            let encoded = planId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? planId
            return URL(string: "livingpath://widget/plan/\(encoded)")
        }
        return URL(string: "livingpath://widget/home")
    }
}

// MARK: - Previews

#Preview("Inline with Plan", as: .accessoryInline) {
    ReadingPlanWidget()
} timeline: {
    PlanEntry.placeholder
}

#Preview("Inline with Streak", as: .accessoryInline) {
    ReadingPlanWidget()
} timeline: {
    PlanEntry(
        date: Date(),
        planTitle: nil,
        currentDay: nil,
        totalDays: nil,
        todayReading: nil,
        streak: 14
    )
}

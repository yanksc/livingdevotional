// StreakWidget - Lock screen circular widget showing streak count
//
// Supports: accessoryCircular

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let taskStreak: Int
    let hasReadToday: Bool
    let hasPrayedToday: Bool
    
    static var placeholder: StreakEntry {
        StreakEntry(
            date: Date(),
            streak: 7,
            taskStreak: 5,
            hasReadToday: true,
            hasPrayedToday: false
        )
    }
}

// MARK: - Timeline Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = StreakEntry(
            date: Date(),
            streak: data.currentStreak,
            taskStreak: data.taskCompletionStreak,
            hasReadToday: data.hasReadToday,
            hasPrayedToday: data.hasPrayedToday
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = StreakEntry(
            date: Date(),
            streak: data.currentStreak,
            taskStreak: data.taskCompletionStreak,
            hasReadToday: data.hasReadToday,
            hasPrayedToday: data.hasPrayedToday
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

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Track your daily devotional streak")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Entry View

struct StreakWidgetEntryView: View {
    let entry: StreakEntry
    
    var body: some View {
        CircularStreakView(entry: entry)
    }
}

// MARK: - Circular View

struct CircularStreakView: View {
    let entry: StreakEntry
    
    var body: some View {
        ZStack {
            // Progress ring showing daily tasks (2 tasks: read + pray)
            let tasksCompleted = (entry.hasReadToday ? 1 : 0) + (entry.hasPrayedToday ? 1 : 0)
            let progress = Double(tasksCompleted) / 2.0
            
            AccessoryWidgetBackground()
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(.green)
                .rotationEffect(.degrees(-90))
                .padding(2)
            
            // Center content
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                
                Text("\(entry.streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
            }
        }
        .widgetURL(URL(string: "livingpath://widget/home"))
    }
}

// MARK: - Alternative Gauge Style (iOS 16+)

struct GaugeStreakView: View {
    let entry: StreakEntry
    
    var body: some View {
        let tasksCompleted = (entry.hasReadToday ? 1 : 0) + (entry.hasPrayedToday ? 1 : 0)
        
        Gauge(value: Double(tasksCompleted), in: 0...2) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entry.streak)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.orange)
        .widgetURL(URL(string: "livingpath://widget/home"))
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakEntry.placeholder
    StreakEntry(
        date: Date(),
        streak: 14,
        taskStreak: 10,
        hasReadToday: true,
        hasPrayedToday: true
    )
}

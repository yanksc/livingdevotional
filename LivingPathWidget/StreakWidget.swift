// StreakWidget - Lock screen circular widget showing streak count
//
// Supports: accessoryCircular

import WidgetKit
import SwiftUI

// MARK: - Custom Cross Shape

struct ThinCrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let strokeWidth: CGFloat = 1.5
        
        // Vertical beam (full height)
        let vLeft = rect.midX - strokeWidth / 2
        path.addRect(CGRect(x: vLeft, y: rect.minY, 
                           width: strokeWidth, height: rect.height))
        
        // Horizontal beam (positioned ~30% from top, shorter width)
        let hTop = rect.height * 0.3 - strokeWidth / 2
        let hWidth = rect.width * 0.7
        let hLeft = rect.midX - hWidth / 2
        path.addRect(CGRect(x: hLeft, y: hTop, 
                           width: hWidth, height: strokeWidth))
        
        return path
    }
}

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
        
        let timeline = Timeline(entries: [entry], policy: .after(WidgetTimelineHelper.nextRefreshDate()))
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
                ThinCrossShape()
                    .fill(Color.widgetSageGreen)
                    .frame(width: 10, height: 14)
                
                Text("\(entry.streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
            }
        }
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

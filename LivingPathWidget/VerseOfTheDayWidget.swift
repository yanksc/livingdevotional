// VerseOfTheDayWidget - Main widget showing verse of the day
//
// Supports: systemSmall, systemMedium, systemLarge, accessoryRectangular

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct VerseEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    
    static var placeholder: VerseEntry {
        VerseEntry(date: Date(), data: .empty)
    }
}

// MARK: - Timeline Provider

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = VerseEntry(date: Date(), data: data)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let data = SharedDataManager.shared.loadWidgetData()
        let entry = VerseEntry(date: Date(), data: data)
        
        let timeline = Timeline(entries: [entry], policy: .after(WidgetTimelineHelper.nextRefreshDate()))
        completion(timeline)
    }
}

// MARK: - Widget Definition

struct VerseOfTheDayWidget: Widget {
    let kind: String = "VerseOfTheDayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider()) { entry in
            VerseWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [.widgetWarmCream, .widgetCardBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Verse of the Day")
        .description("Daily inspiration from Scripture")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
    }
}

// MARK: - Entry View (Routes to appropriate size)

struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: VerseEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallVerseView(data: entry.data)
        case .systemMedium:
            MediumVerseView(data: entry.data)
        case .systemLarge:
            LargeVerseView(data: entry.data)
        case .accessoryRectangular:
            RectangularVerseView(data: entry.data)
        default:
            SmallVerseView(data: entry.data)
        }
    }
}

// MARK: - Small Widget View

struct SmallVerseView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Verse text - primary focus, allow wrapping
            Text(data.verseText)
                .font(WidgetStyles.verseFont(size: 12))
                .foregroundColor(.primary.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            // Footer: subtle reference + streak
            HStack(alignment: .bottom) {
                Text("— \(data.localizedReference)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.widgetWarmSand.opacity(0.8))
                
                Spacer()
                
                // Subtle streak badge
                HStack(spacing: 2) {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 9))
                    Text("\(data.currentStreak)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.widgetSageGreen)
            }
        }
        .padding(8)
        .widgetURL(URL(string: "livingpath://widget/verse"))
    }
}

// MARK: - Medium Widget View

struct MediumVerseView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Verse text - primary focus, allow wrapping
            Text(data.verseText)
                .font(WidgetStyles.verseFont(size: 14))
                .foregroundColor(.primary.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            
            Spacer(minLength: 6)
            
            // Footer: subtle reference + streak
            HStack(alignment: .bottom) {
                Text("— \(data.localizedReference)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.widgetWarmSand.opacity(0.85))
                
                Spacer()
                
                // Subtle streak
                HStack(spacing: 3) {
                    Image(systemName: "cross.fill")
                        .font(.system(size: 10))
                    Text("\(data.currentStreak)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.widgetSageGreen)
            }
        }
        .padding(10)
        .widgetURL(URL(string: "livingpath://widget/verse"))
    }
}

// MARK: - Large Widget View

struct LargeVerseView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Full verse text - primary focus
            Text(data.verseText)
                .font(WidgetStyles.verseFont(size: 17))
                .foregroundColor(.primary.opacity(0.85))
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            
            // Subtle reference
            Text("— \(data.localizedReference)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.widgetWarmSand.opacity(0.85))
            
            Spacer(minLength: 8)
            
            // Reading plan progress (if active)
            if let planTitle = data.activePlanTitle,
               let localizedDay = data.localizedDay() {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "book.closed.fill")
                            .font(.caption)
                            .foregroundColor(.widgetSageGreen)
                        Text(planTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary.opacity(0.8))
                        Spacer()
                        Text(localizedDay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.widgetSoftBeige)
                                .frame(height: 5)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.widgetSageGreen)
                                .frame(width: geometry.size.width * data.activePlanProgress, height: 5)
                        }
                    }
                    .frame(height: 5)
                }
            }
            
            // Footer: Today's progress + streak
            HStack(spacing: 12) {
                progressItem(
                    icon: "book.fill",
                    label: data.localizedRead(),
                    completed: data.hasReadToday
                )
                progressItem(
                    icon: "hands.sparkles.fill",
                    label: data.localizedPray(),
                    completed: data.hasPrayedToday
                )
                
                Spacer()
                
                // Subtle streak
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                    Text("\(data.currentStreak)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.widgetSageGreen)
            }
        }
        .padding(12)
        .widgetURL(URL(string: "livingpath://widget/verse"))
    }
    
    private func progressItem(icon: String, label: String, completed: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundColor(completed ? .widgetSageGreen : .secondary)
            Text(label)
                .font(.caption)
                .foregroundColor(completed ? .primary : .secondary)
        }
    }
}

// MARK: - Lock Screen Rectangular View

struct RectangularVerseView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Verse text (truncated for lock screen)
            Text(data.verseText)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
            
            // Reference
            Text(data.localizedReference)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "livingpath://widget/verse"))
    }
}

// MARK: - Preview Data

extension WidgetData {
    static var preview: WidgetData {
        WidgetData(
            verseText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            verseReference: "John 3:16",
            verseBook: "John",
            verseChapter: 3,
            verseNumber: 16,
            verseReason: nil,
            currentStreak: 9,
            taskCompletionStreak: 5,
            hasReadToday: true,
            hasPrayedToday: false,
            chaptersReadToday: 2,
            activePlanId: "gospel-of-john",
            activePlanTitle: "Gospel of John",
            activePlanProgress: 0.43,
            activePlanDay: 3,
            activePlanTotal: 7,
            activePlanTodayReading: "John 3",
            lastUpdated: Date(),
            primaryLanguageCode: "bsb"
        )
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    VerseOfTheDayWidget()
} timeline: {
    VerseEntry(date: Date(), data: .preview)
}

#Preview("Medium", as: .systemMedium) {
    VerseOfTheDayWidget()
} timeline: {
    VerseEntry(date: Date(), data: .preview)
}

#Preview("Large", as: .systemLarge) {
    VerseOfTheDayWidget()
} timeline: {
    VerseEntry(date: Date(), data: .preview)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    VerseOfTheDayWidget()
} timeline: {
    VerseEntry(date: Date(), data: .preview)
}

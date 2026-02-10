// WidgetTimelineHelper.swift
// Shared timeline refresh date calculation for all widget providers

import Foundation

enum WidgetTimelineHelper {
    
    /// Calculate the next refresh date for widget timelines.
    /// Refreshes at midnight (for a new day) or after 1 hour, whichever comes first.
    static func nextRefreshDate() -> Date {
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let oneHourLater = Date().addingTimeInterval(3600)
        return min(midnight, oneHourLater)
    }
}

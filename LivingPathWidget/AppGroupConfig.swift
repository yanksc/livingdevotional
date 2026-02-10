// AppGroupConfig - App Group configuration for widget data sharing
//
// NOTE: This file is duplicated in livingdevotional/Shared/ and LivingPathWidget/
// Both copies MUST be kept in sync. Future improvement: use dual target membership
// in Xcode to share a single file between both targets.

import Foundation

/// Shared App Group configuration for main app and widget extension
struct AppGroupConfig {
    /// The App Group identifier - must match in both targets
    /// Based on bundle ID: com.ykh.livingdevotional
    static let appGroupIdentifier = "group.com.ykh.livingdevotional"
    
    /// Shared UserDefaults for widget data exchange
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Keys for shared data
    struct Keys {
        static let widgetData = "widgetData"
        static let lastSyncDate = "lastWidgetSyncDate"
    }
}

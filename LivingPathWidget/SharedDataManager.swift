// SharedDataManager - Reads widget data from shared App Group
//
// IMPORTANT: This file depends on shared code from the main app.
// In Xcode, ensure these files have Target Membership for BOTH targets:
//   - livingdevotional/Shared/AppGroupConfig.swift
//   - livingdevotional/Shared/WidgetData.swift
//
// To add Target Membership:
// 1. Select the file in Xcode's Project Navigator
// 2. In the File Inspector (right panel), check both:
//    - livingdevotional (main app)
//    - LivingPathWidgetExtension (widget)

import Foundation

/// Reads widget data from shared UserDefaults
/// This is a thin wrapper that the widget extension uses to load data
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private init() {}
    
    func loadWidgetData() -> WidgetData {
        guard let sharedDefaults = AppGroupConfig.sharedUserDefaults,
              let data = sharedDefaults.data(forKey: AppGroupConfig.Keys.widgetData),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .empty
        }
        return widgetData
    }
    
    func lastSyncDate() -> Date? {
        AppGroupConfig.sharedUserDefaults?.object(forKey: AppGroupConfig.Keys.lastSyncDate) as? Date
    }
}

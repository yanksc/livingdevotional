//
//  LivingPathWidgetBundle.swift
//  livingpathwidget
//
//  Created by Yenkai Huang on 1/28/26.
//

import WidgetKit
import SwiftUI

@main
struct LivingPathWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Verse of the Day widget - main widget with all sizes
        VerseOfTheDayWidget()
        
        // Streak widget - for lock screen circular
        StreakWidget()
        
        // Reading Plan Progress widget - for lock screen inline
        ReadingPlanWidget()
    }
}

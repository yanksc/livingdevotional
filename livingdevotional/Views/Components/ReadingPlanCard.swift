// ReadingPlanCard - Compact card component for reading plans

import SwiftUI

struct ReadingPlanCard: View {
    let plan: ReadingPlan
    let progress: ReadingPlanProgress?
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    var progressPercentage: Double {
        guard let progress = progress, !progress.completedDays.isEmpty, plan.duration > 0 else { return 0 }
        let percentage = Double(progress.completedDays.count) / Double(plan.duration) * 100
        return min(100, max(0, percentage))
    }
    
    /// Get background filename for this plan
    private var backgroundFilename: String {
        backgroundManager.backgroundForPlan(planId: plan.id)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image from bg_serene folder
            SereneBackgroundImage(filename: backgroundFilename)
                .frame(width: 160, height: 180)
                .clipped()
            
            // Gradient overlay for text readability (bottom to top)
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content overlay at bottom
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(plan.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Duration badge
                Text("\(plan.duration) \(settingsStore.appLanguage.localizedString("days"))")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                // Progress bar (if started)
                if let progress = progress, progress.isStarted {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 4)
                                
                                // Progress
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: max(0, geometry.size.width * CGFloat(progressPercentage / 100)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 160, height: 180)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    if let plan = ReadingPlanStore.shared.plans.first {
        HStack {
            ReadingPlanCard(
                plan: plan,
                progress: nil
            )
            
            ReadingPlanCard(
                plan: plan,
                progress: ReadingPlanProgress(planId: "test")
            )
        }
        .padding()
    }
}

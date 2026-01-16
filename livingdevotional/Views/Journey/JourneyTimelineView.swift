// JourneyTimelineView.swift
// Displays a vertical timeline of user milestones

import SwiftUI

struct JourneyTimelineView: View {
    let milestones: [JourneyMilestone]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                HStack(alignment: .top, spacing: 16) {
                    // Timeline line and icon
                    VStack(spacing: 0) {
                        Image(systemName: milestone.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.accentColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        // Line connector (hide for last item)
                        if index < milestones.count - 1 {
                            Rectangle()
                                .fill(AppTheme.accentColor.opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 40)
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(milestone.date))
                            .font(.caption2)
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.top, 8)
                        
                        Text(milestone.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text(milestone.description)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(3)
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

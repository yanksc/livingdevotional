// HomeView - Main home screen
// Placeholder for future home page implementation

import SwiftUI

struct HomeView: View {
    @Environment(\.services) var services
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Verse of the day
                    verseOfTheDaySection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent reading
                    recentReadingSection
                }
                .padding()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - View Components
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.primaryText)
            Text("Start your daily devotional journey")
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var verseOfTheDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verse of the Day")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            // TODO: Load verse of the day
            Text("Coming soon...")
                .foregroundColor(AppTheme.secondaryText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: 12) {
                quickActionButton(title: "Read Bible", icon: "book.fill") {
                    // Navigation handled by MainTabView
                }
                quickActionButton(title: "Search", icon: "magnifyingglass") {
                    // TODO: Open search
                }
            }
        }
    }
    
    private var recentReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Reading")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)
            
            // TODO: Load recent reading progress
            Text("No recent reading")
                .foregroundColor(AppTheme.secondaryText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
        }
    }
    
    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGradient)
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}


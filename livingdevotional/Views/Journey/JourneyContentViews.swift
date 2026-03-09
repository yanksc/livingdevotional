// JourneyContentViews.swift
// Content views for the Journey feature: path status, highlights, next step

import SwiftUI

// MARK: - Path Status Card View (Merged with encouragement and summary)

struct PathStatusCardView: View {
    let pathStatus: PathStatus
    var onTap: (() -> Void)? = nil
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title — centered
            Text(pathStatus.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Subtitle — centered
            Text(pathStatus.subtitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 4)
            
            // Analysis description — left aligned, line-limited to hint at more content
            Text(pathStatus.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.leading)
                .lineSpacing(7)
                .lineLimit(8)
                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Expand hint
            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "閱讀更多" : "Read more")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.75)
        .background(
            ZStack {
                SereneBackgroundImage(
                    filename: backgroundManager.journeyBackground,
                    targetSize: CGSize(width: 700, height: 900)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.30),
                        Color.black.opacity(0.55)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipped()
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Analysis Full Screen View

struct AnalysisFullScreenView: View {
    let pathStatus: PathStatus
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settingsStore = SettingsStore.shared
    @ObservedObject private var backgroundManager = SereneBackgroundManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image — same as card
                SereneBackgroundImage(
                    filename: backgroundManager.journeyBackground,
                    targetSize: geometry.size
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                
                // Gradient overlay — same as card
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.30),
                        Color.black.opacity(0.55)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Top spacer to clear the close button
                        Spacer().frame(height: 56)
                        
                        Text(pathStatus.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 2)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(pathStatus.subtitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 4)
                        
                        Text(pathStatus.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(7)
                            .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer().frame(height: 48)
                    }
                    .padding(.horizontal, 24)
                }
                
                // Close button — pinned top-right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Path Highlights View (Collapsible)

struct PathHighlightsView: View {
    let highlights: [PathHighlight]
    @ObservedObject private var settingsStore = SettingsStore.shared
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - tappable to expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "路徑亮點" : "Path Highlights")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.cardGradient)
                .cornerRadius(isExpanded ? 12 : 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(highlights) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Text(highlight.emoji)
                                .font(.title3)
                            
                            Text(highlight.fact)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(2)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.sectionBackground.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(AppTheme.cardGradient)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Recommended Reading View

struct RecommendedReadingView: View {
    let reading: RecommendedReading
    @ObservedObject private var settingsStore = SettingsStore.shared
    @EnvironmentObject var router: AppRouter
    @State private var showNavigationError = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "book.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsStore.appLanguage == .chineseTraditional ? "推薦閱讀" : "Recommended Reading")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.secondaryText)
                        .textCase(.uppercase)
                    
                    // Localized book name + chapter
                    let localizedBook = BibleData.localizedBookName(reading.book, language: settingsStore.primaryLanguage)
                    Text("\(localizedBook) \(reading.chapter)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryText)
                }
                
                Spacer()
            }
            
            // Reason
            Text(reading.reason)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Two buttons
            HStack(spacing: 12) {
                // Read button
                Button(action: {
                    guard let book = BibleData.book(named: reading.book) else {
                        showNavigationError = true
                        return
                    }
                    router.navigateToReading(book: book, chapter: reading.chapter)
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text(settingsStore.appLanguage == .chineseTraditional ? "閱讀" : "Read")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Get Reading Plan button
                Button(action: {
                    router.selectedTab = 0
                    router.currentRoute = .explore
                }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text(settingsStore.appLanguage == .chineseTraditional ? "獲取計劃" : "Get Plan")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.cardGradient)
                    .foregroundColor(AppTheme.primaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardGradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .alert("Unable to Navigate", isPresented: $showNavigationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Could not find the book '\(reading.book)'. Please try again.")
        }
    }
}

// SereneGradientBackground.swift
// Elegant animated serene gradient background with multi-layer design

import SwiftUI

struct SereneGradientBackground: View {
    @State private var breathingPhase = false
    @State private var floatingPhase1 = false
    @State private var floatingPhase2 = false
    
    // App-aligned colors from AppTheme
    private let warmCream = Color(red: 0.980, green: 0.969, blue: 0.949)      // #FAF7F2 - Warm Cream
    private let softBeige = Color(red: 0.910, green: 0.835, blue: 0.718)      // #E8D5B7 - Soft Beige
    private let sageGreen = Color(red: 0.659, green: 0.773, blue: 0.722)     // #A8C5B8 - Sage Green
    private let warmSand = Color(red: 0.831, green: 0.647, blue: 0.455)      // #D4A574 - Warm Sand
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base warm gradient layer - static for serene stability
                LinearGradient(
                    colors: [
                        warmCream,
                        softBeige.opacity(0.8),
                        warmCream.opacity(0.95),
                        softBeige.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Breathing overlay - subtle luminosity pulse for gentle movement
                Color.white
                    .opacity(breathingPhase ? 0.04 : 0.0)
                
                // Floating orb 1 - soft sage green accent (larger, slower)
                floatingOrb(
                    color: sageGreen,
                    size: geometry.size.width * 0.85,
                    offsetX: floatingPhase1 ? geometry.size.width * 0.15 : -geometry.size.width * 0.1,
                    offsetY: floatingPhase1 ? -geometry.size.height * 0.1 : geometry.size.height * 0.15,
                    opacity: 0.12
                )
                
                // Floating orb 2 - warm sand glow (medium, medium speed)
                floatingOrb(
                    color: warmSand,
                    size: geometry.size.width * 0.65,
                    offsetX: floatingPhase2 ? -geometry.size.width * 0.12 : geometry.size.width * 0.18,
                    offsetY: floatingPhase2 ? geometry.size.height * 0.2 : -geometry.size.height * 0.08,
                    opacity: 0.08
                )
                
                // Subtle center vignette overlay for depth and focus
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.02),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: geometry.size.width * 0.3,
                    endRadius: geometry.size.width * 0.8
                )
                
                // Soft top-to-bottom overlay for additional depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Breathing animation - 8 second cycle for gentle luminosity pulse
            withAnimation(
                Animation.easeInOut(duration: 8.0)
                    .repeatForever(autoreverses: true)
            ) {
                breathingPhase = true
            }
            
            // Floating orb 1 - 25 second cycle (slowest, most ethereal)
            withAnimation(
                Animation.easeInOut(duration: 25.0)
                    .repeatForever(autoreverses: true)
            ) {
                floatingPhase1 = true
            }
            
            // Floating orb 2 - 18 second cycle (slightly faster for variation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(
                    Animation.easeInOut(duration: 18.0)
                        .repeatForever(autoreverses: true)
                ) {
                    floatingPhase2 = true
                }
            }
        }
    }
    
    // Helper function to create floating orb effect
    private func floatingOrb(
        color: Color,
        size: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        opacity: Double
    ) -> some View {
        RadialGradient(
            colors: [
                color.opacity(opacity),
                color.opacity(opacity * 0.6),
                Color.clear
            ],
            center: .center,
            startRadius: size * 0.2,
            endRadius: size * 0.5
        )
        .frame(width: size, height: size)
        .offset(x: offsetX, y: offsetY)
        .blur(radius: 20)
    }
}

// MARK: - Serene Prayer Background

/// Fullscreen serene background image with elegant edge boundaries for prayer views
/// Uses images from bg_serene folder with polished design details
struct SerenePrayerBackground: View {
    /// Opacity of the dark overlay for text readability (default: 0.4)
    var overlayOpacity: Double = 0.4
    
    /// Width of the edge boundary gradients in points (default: 28)
    var edgeBoundaryWidth: CGFloat = 28
    
    /// Opacity of the edge boundary gradients (default: 0.3)
    var edgeBoundaryOpacity: Double = 0.3
    
    /// Whether to show subtle inner vignette (default: true)
    var showVignette: Bool = true
    
    /// Randomly selected background image filename
    @State private var backgroundImageName: String = SereneBackgroundManager.shared.randomBackground()
    
    /// Image load state for fade-in animation
    @State private var imageLoaded: Bool = false
    
    init(
        overlayOpacity: Double = 0.4,
        edgeBoundaryWidth: CGFloat = 28,
        edgeBoundaryOpacity: Double = 0.3,
        showVignette: Bool = true
    ) {
        self.overlayOpacity = overlayOpacity
        self.edgeBoundaryWidth = edgeBoundaryWidth
        self.edgeBoundaryOpacity = edgeBoundaryOpacity
        self.showVignette = showVignette
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Fullscreen serene background image
                ZStack {
                    // Always show fallback gradient first (immediate)
                    LinearGradient(
                        colors: [
                            Color(red: 0.980, green: 0.969, blue: 0.949), // Warm Cream
                            Color(red: 0.910, green: 0.835, blue: 0.718)   // Soft Beige
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Overlay the actual image when loaded
                    if !backgroundImageName.isEmpty && imageLoaded {
                        SereneBackgroundImage(
                            filename: backgroundImageName,
                            targetSize: CGSize(
                                width: geometry.size.width * UIScreen.main.scale,
                                height: geometry.size.height * UIScreen.main.scale
                            )
                        )
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .transition(.opacity)
                    }
                }
                
                // Layer 2: Dark overlay for text readability
                Color.black.opacity(overlayOpacity)
                    .ignoresSafeArea()
                
                // Layer 3: Left/right edge boundary gradients
                HStack(spacing: 0) {
                    // Left boundary - soft fade from dark to clear
                    LinearGradient(
                        colors: [
                            Color.black.opacity(edgeBoundaryOpacity),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: edgeBoundaryWidth)
                    
                    Spacer()
                    
                    // Right boundary - soft fade from clear to dark
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(edgeBoundaryOpacity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: edgeBoundaryWidth)
                }
                .ignoresSafeArea()
                
                // Layer 4: Subtle inner vignette for depth and focus
                if showVignette {
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: geometry.size.width * 0.25,
                        endRadius: geometry.size.width * 0.9
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Always show fallback gradient immediately (no delay)
            // Then load and show image when ready
            if !backgroundImageName.isEmpty {
                // Check if image is already cached
                if SereneImageCache.shared.image(for: backgroundImageName) != nil {
                    // Image is cached, show immediately with smooth transition
                    withAnimation(.easeIn(duration: 0.3)) {
                        imageLoaded = true
                    }
                } else {
                    // Preload image asynchronously, show when ready
                    let targetSize = CGSize(
                        width: UIScreen.main.bounds.width * UIScreen.main.scale,
                        height: UIScreen.main.bounds.height * UIScreen.main.scale
                    )
                    Task {
                        _ = await SereneImageCache.shared.loadImageAsync(
                            filename: backgroundImageName,
                            targetSize: targetSize
                        )
                        // Small delay to ensure image is rendered before showing
                        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                        await MainActor.run {
                            withAnimation(.easeIn(duration: 0.4)) {
                                imageLoaded = true
                            }
                        }
                    }
                }
            }
        }
    }
}

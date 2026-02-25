// SplashView - Serene splash screen with calm emerging animation

import SwiftUI
import UIKit

struct SplashView: View {
    @State private var imageOpacity: Double = 0.0
    @State private var breathingPhase = false
    @Binding var isPresented: Bool
    
    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    var body: some View {
        ZStack {
            // Full-screen splash background image
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .opacity(imageOpacity)
                .accessibilityLabel("Living Path – your spiritual journey")
            
            // Optional: Very subtle luminosity overlay with slow breathing pulse
            if !reduceMotion {
                Color.white
                    .opacity(breathingPhase ? 0.02 : 0.0)
                    .ignoresSafeArea()
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        let fadeDuration = reduceMotion ? 0.5 : 1.8
        
        withAnimation(.easeIn(duration: fadeDuration)) {
            imageOpacity = 1.0
        }
        
        if !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                withAnimation(
                    Animation.easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true)
                ) {
                    breathingPhase = true
                }
            }
        }
        
        // Auto-dismiss after 2.5 seconds (no fade out)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isPresented = false
        }
    }
}

// MARK: - Full Screen Splash Modifier

struct SplashScreenModifier: ViewModifier {
    @State private var showSplash = true
    
    func body(content: Content) -> some View {
        ZStack {
            // Use conditional rendering so content only mounts after splash dismisses
            // This ensures TypewriterText.onAppear fires at the right time
            if !showSplash {
                content
            }
            
            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

extension View {
    func splashScreen() -> some View {
        modifier(SplashScreenModifier())
    }
}

#Preview {
    SplashView(isPresented: .constant(true))
}

// SplashView - Beautiful splash screen with animations

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AppTheme.primaryGradient
                .ignoresSafeArea()
                .opacity(isAnimating ? 1.0 : 0.9)
            
            // Secondary gradient overlay for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon/Logo
                ZStack {
                    // Glowing circle behind icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.6 : 0.3)
                    
                    // Book icon with animation
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                }
                .padding(.bottom, 20)
                
                // App Name
                VStack(spacing: 8) {
                    Text("Living")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    Text("Devotional")
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .opacity(opacity)
                
                // Tagline
                Text("Your daily journey with God's Word")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(opacity)
                    .padding(.top, 8)
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .opacity(opacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Initial scale animation
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Rotation animation
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            rotation = 5
        }
        
        // Pulsing animation
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0.0
                scale = 1.2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresented = false
            }
        }
    }
}

// MARK: - Full Screen Splash Modifier

struct SplashScreenModifier: ViewModifier {
    @State private var showSplash = true
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(showSplash ? 0 : 1)
            
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


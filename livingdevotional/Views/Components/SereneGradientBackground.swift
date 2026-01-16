// SereneGradientBackground.swift
// Animated serene gradient background for prayer experience

import SwiftUI

struct SereneGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base serene gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),      // Soft blue-white
                    Color(red: 0.98, green: 0.95, blue: 0.98),      // Soft lavender
                    Color(red: 1.0, green: 0.98, blue: 0.95),        // Soft peach
                    Color(red: 0.97, green: 0.98, blue: 0.99)        // Soft blue-gray
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            
            // Overlay gradient for depth
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear,
                    Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 8.0)
                    .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

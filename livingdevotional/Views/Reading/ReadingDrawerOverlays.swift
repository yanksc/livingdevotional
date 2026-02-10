// ReadingDrawerOverlays.swift
// Slide-out drawer overlays for the Reading view: related verses, chapter context, chapter summary

import SwiftUI

// MARK: - Slide-Out Drawer

/// A reusable slide-out drawer that slides in from the right edge
struct SlideOutDrawer<Content: View>: View {
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = UIScreen.main.bounds.width
    let content: () -> Content
    
    var body: some View {
        if isPresented {
            ZStack {
                // Dimming backdrop
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                            offset = UIScreen.main.bounds.width
                        }
                    }
                    .transition(.opacity)
                
                // Drawer content
                HStack {
                    Spacer()
                    content()
                        .frame(maxWidth: min(UIScreen.main.bounds.width * 0.9, 500), maxHeight: .infinity)
                        .offset(x: offset)
                }
            }
            .zIndex(1000)
            .onAppear {
                offset = UIScreen.main.bounds.width
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                }
            }
        }
    }
    
    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
            offset = UIScreen.main.bounds.width
        }
    }
}

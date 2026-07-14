// PrayerResultView.swift
// Prayer result display views including typewriter animation and amen button

import SwiftUI

// MARK: - Prayer Result View

struct PrayerResultView: View {
    let verse: DailyVerse
    let prayer: String
    var onDismiss: () -> Void
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    // Control Amen button visibility
    @State private var showAmenButton = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Verse display - at the top with elegant rounded transparent background
                    VStack(spacing: 10) {
                        Text(verse.text(for: settingsStore.primaryLanguage))
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                        
                        if settingsStore.showSecondaryLanguage && settingsStore.secondaryLanguage != .none {
                            Text(verse.text(for: settingsStore.secondaryLanguage))
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .italic()
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
                        }
                        
                        Text("\(BibleData.localizedBookName(verse.book, language: settingsStore.primaryLanguage)) \(verse.chapter):\(verse.verseNumber)")
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    
                    // Prayer text - below verse, left-aligned, animated
                    VStack(alignment: .leading, spacing: 0) {
                        PrayerTypewriterText(
                            text: prayer,
                            speed: 0.075,
                            font: .system(size: 18, weight: .regular, design: .serif),
                            onComplete: {
                                withAnimation(.easeIn(duration: 1.0)) {
                                    showAmenButton = true
                                }
                            }
                        )
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)
                        .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // Amen Button - fades in when prayer completes
                    VStack(spacing: 12) {
                        AmenButton(onComplete: onDismiss)
                        
                        Text(settingsStore.appLanguage.localizedString("AmenHoldHint"))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .opacity(showAmenButton ? 1.0 : 0.0)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Typewriter Text Animation

struct PrayerTypewriterText: View {
    let text: String
    let speed: Double
    let font: Font
    var onComplete: (() -> Void)? = nil
    
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var hasCompleted: Bool = false
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        guard currentIndex < text.count else {
            if !hasCompleted {
                hasCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
            }
            return
        }
        
        let nextIndex = min(currentIndex + 1, text.count)
        let index = text.index(text.startIndex, offsetBy: nextIndex)
        displayedText = String(text[..<index])
        currentIndex = nextIndex
        
        if currentIndex < text.count {
            let char = text[text.index(text.startIndex, offsetBy: currentIndex - 1)]
            let delay: Double
            if char.isWhitespace {
                delay = speed * 1.5
            } else if char.isPunctuation {
                delay = speed * 2.5
            } else {
                delay = speed
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                startTyping()
            }
        } else {
            if !hasCompleted {
                hasCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
            }
        }
    }
}

// MARK: - Amen Button

struct AmenButton: View {
    var onComplete: () -> Void
    var onIncompletePress: (() -> Void)? = nil
    @ObservedObject private var settingsStore = SettingsStore.shared

    @State private var isHolding = false
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var didComplete = false
    
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private let holdDuration: Double = 3.0
    private let buttonSize: CGFloat = 80
    private let progressRingWidth: CGFloat = 6
    
    var body: some View {
        ZStack {
            // Outer progress ring
            if isHolding {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: progressRingWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
                    .animation(.linear(duration: 0.05), value: progress)
            }
            
            // Button background
            Circle()
                .fill(
                    Color.white.opacity(0.15)
                )
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: Color.black.opacity(0.2), radius: isHolding ? 10 : 5)
                .scaleEffect(isHolding ? 1.05 : 1.0)
            
            // Button text
            Text(settingsStore.appLanguage.localizedString("Amen"))
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .scaleEffect(isHolding ? 1.1 : 1.0)
        }
        .frame(width: buttonSize + progressRingWidth * 2, height: buttonSize + progressRingWidth * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        startHolding()
                    }
                }
                .onEnded { _ in
                    stopHolding()
                }
        )
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func startHolding() {
        isHolding = true
        progress = 0.0
        
        hapticLight.prepare()
        hapticLight.impactOccurred()
        
        let startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            progress = min(elapsed / holdDuration, 1.0)
            
            if progress >= 0.5 && progress < 0.52 {
                hapticMedium.prepare()
                hapticMedium.impactOccurred()
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                completeAmen()
            }
        }
    }
    
    private func stopHolding() {
        isHolding = false
        timer?.invalidate()
        timer = nil

        withAnimation(.easeOut(duration: 0.3)) {
            progress = 0.0
        }

        // Released before the full hold completed — report a tap/incomplete press
        if !didComplete {
            onIncompletePress?()
        }
    }

    private func completeAmen() {
        didComplete = true
        notificationGenerator.notificationOccurred(.success)
        
        withAnimation(.easeOut(duration: 0.5)) {
            progress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete()
        }
    }
}

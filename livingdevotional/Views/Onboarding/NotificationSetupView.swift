// NotificationSetupView - Step 11: Notification permission & time setup
// Users set two daily reminder times and grant notification permission.
// Morning time defaults to the current time (users tend to return at the same time).
// Evening time defaults to 8:30 PM.

import SwiftUI
import UserNotifications

struct NotificationSetupView: View {
    @ObservedObject var state: OnboardingState
    
    @State private var morningTime: Date = NotificationSetupView.smartMorningDefault()
    @State private var eveningTime: Date = NotificationSetupView.defaultEveningTime()
    @State private var showIcon = false
    @State private var showHeading = false
    @State private var showPickers = false
    @State private var showActions = false
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Bell icon
            iconView
                .padding(.bottom, 20)
            
            // Heading
            headingView
                .padding(.bottom, 8)
            
            // Subtitle
            subtitleView
                .padding(.bottom, 28)
            
            // Time picker cards
            timePickersView
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .opacity(showPickers ? 1 : 0)
                .offset(y: showPickers ? 0 : 15)
            
            // Action buttons
            actionsView
                .padding(.horizontal, 36)
                .opacity(showActions ? 1 : 0)
                .offset(y: showActions ? 0 : 10)
            
            Spacer()
            
            // Bottom navigation
            HStack {
                OnboardingBackButton(state: state)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            startRevealSequence()
        }
    }
    
    // MARK: - Icon
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentColor.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.accentColor)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), value: showIcon)
        }
        .scaleEffect(showIcon ? 1.0 : 0.6)
        .opacity(showIcon ? 1 : 0)
        .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Heading
    
    private var headingView: some View {
        Text(headingLocalized)
            .font(.system(size: OnboardingDesign.promptFontSize, weight: .regular, design: .serif))
            .foregroundColor(AppTheme.onboardingText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .opacity(showHeading ? 1 : 0)
            .offset(y: showHeading ? 0 : 10)
    }
    
    private var headingLocalized: String {
        if state.isChinese { return "保持在你的道路上" }
        if state.isSpanish { return "Mantente en tu camino" }
        return "Stay on Your Path"
    }
    
    // MARK: - Subtitle
    
    private var subtitleView: some View {
        Text(subtitleLocalized)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(AppTheme.secondaryText)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 40)
            .opacity(showHeading ? 1 : 0)
            .offset(y: showHeading ? 0 : 10)
    }
    
    private var subtitleLocalized: String {
        if state.isChinese { return "每天兩次溫柔的提醒，\n陪伴你親近神的話語" }
        if state.isSpanish { return "Dos recordatorios diarios\npara nutrir tu camino de fe" }
        return "Two gentle daily reminders\nto nurture your walk with God"
    }
    
    // MARK: - Time Pickers
    
    private var timePickersView: some View {
        VStack(spacing: 14) {
            timePickerCard(
                icon: "sun.and.horizon.fill",
                label: morningLabel,
                time: $morningTime
            )
            
            timePickerCard(
                icon: "moon.stars.fill",
                label: eveningLabel,
                time: $eveningTime
            )
        }
    }
    
    private var morningLabel: String {
        if state.isChinese { return "晨間靈修" }
        if state.isSpanish { return "Devocional matutino" }
        return "Morning Devotional"
    }
    
    private var eveningLabel: String {
        if state.isChinese { return "晚間禱告" }
        if state.isSpanish { return "Oración vespertina" }
        return "Evening Prayer"
    }
    
    private func timePickerCard(icon: String, label: String, time: Binding<Date>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 32)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.onboardingText)
            
            Spacer()
            
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(AppTheme.accentColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.accentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Actions
    
    private var actionsView: some View {
        VStack(spacing: 12) {
            Button(action: enableReminders) {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16))
                        Text(enableLocalized)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.buttonGradient)
                .cornerRadius(12)
                .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isRequesting)
            
            Button(action: skipNotifications) {
                Text(skipLocalized)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var enableLocalized: String {
        if state.isChinese { return "開啟提醒" }
        if state.isSpanish { return "Activar recordatorios" }
        return "Enable Reminders"
    }
    
    private var skipLocalized: String {
        if state.isChinese { return "之後再說" }
        if state.isSpanish { return "Quizás más tarde" }
        return "Maybe Later"
    }
    
    // MARK: - Actions
    
    private func enableReminders() {
        isRequesting = true
        let settingsStore = SettingsStore.shared
        
        // Save chosen times
        settingsStore.morningTime = morningTime
        settingsStore.eveningTime = eveningTime
        
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            
            await MainActor.run {
                isRequesting = false
                
                if granted {
                    settingsStore.notificationsEnabled = true
                    UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
                    NotificationManager.shared.scheduleAllNotifications()
                } else {
                    // Permission denied by user — respect their choice
                    settingsStore.notificationsEnabled = false
                    UserDefaults.standard.set(true, forKey: "hasRequestedNotificationPermission")
                }
                
                withAnimation {
                    state.goNext()
                }
            }
        }
    }
    
    private func skipNotifications() {
        SettingsStore.shared.notificationsEnabled = false
        withAnimation {
            state.goNext()
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startRevealSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                showIcon = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                showHeading = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showPickers = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                showActions = true
            }
        }
    }
    
    // MARK: - Smart Defaults
    
    /// Morning default: current time rounded to the nearest 5 minutes.
    /// The user is on their phone right now, so tomorrow at the same time is a natural reminder.
    static func smartMorningDefault() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let roundedMinute = (minute / 5) * 5
        
        var components = DateComponents()
        components.hour = hour
        components.minute = roundedMinute
        return calendar.date(from: components) ?? now
    }
    
    /// Evening default: 8:30 PM (matches the existing SettingsStore default).
    static func defaultEveningTime() -> Date {
        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }
}

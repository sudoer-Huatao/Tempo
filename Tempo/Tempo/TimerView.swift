import SwiftUI
import UserNotifications

struct TimerView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("themeColor") private var themeColor = "blue"
    @State private var pulsate = false
    @State private var glow = false
    @State private var showModeTransition = false
    @State private var timerPulse = false
    @State private var ringPulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode header with transition animation
            modeHeader
                .padding(.top, 40)
                .padding(.bottom, 30)
            
            // Timer circle with enhanced animations
            timerCircle
                .padding(.bottom, 40)
            
            // Control buttons with animations
            controlButtons
                .padding(.horizontal, 30)
            
            Spacer()
            
            // Session counter
            sessionCounter
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
        )
        .onChange(of: timerManager.mode) { _ in
            playModeTransitionAnimation()
        }
        .onChange(of: timerManager.state) { newState in
            if newState == .running {
                startTimerAnimations()
            } else {
                stopTimerAnimations()
            }
        }
        .onAppear {
            requestNotificationPermission()
            if timerManager.state == .running {
                startTimerAnimations()
            }
        }
    }
    
    private var modeHeader: some View {
        VStack(spacing: 8) {
            Text(timerManager.mode.rawValue.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeColor.color.opacity(0.7))
                .tracking(1.5)
                .scaleEffect(showModeTransition ? 1.2 : 1)
                .opacity(showModeTransition ? 0 : 1)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showModeTransition)
            
            Text(timeString(from: timerManager.timeRemaining))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
                .scaleEffect(pulsate ? 1.05 : 1)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                        .delay(0.2),
                    value: pulsate
                )
                .onAppear {
                    pulsate = timerManager.state == .running
                }
                .onChange(of: timerManager.state) { newState in
                    pulsate = newState == .running
                }
        }
    }
    
    private var timerCircle: some View {
        ZStack {
            // Outer glow effect when timer is running
            if timerManager.state == .running {
                Circle()
                    .fill(themeColor.color.opacity(0.15))
                    .frame(width: 320, height: 320)
                    .scaleEffect(timerPulse ? 1.05 : 1)
                    .opacity(timerPulse ? 1 : 0.7)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: timerPulse
                    )
            }
            
            // Background rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        themeColor.color.opacity(0.1),
                        style: StrokeStyle(lineWidth: 2, dash: [2, 4])
                    )
                    .frame(width: 280 + CGFloat(i * 20), height: 280 + CGFloat(i * 20))
                    .opacity(0.3)
            }
            
            // Pulsing progress ring background
            Circle()
                .stroke(
                    themeColor.color.opacity(0.2),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .scaleEffect(ringPulse ? 1.02 : 1)
                .opacity(ringPulse ? 0.8 : 0.5)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: ringPulse
                )
            
            // Main progress ring
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            themeColor.color,
                            themeColor.color.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: themeColor.color.opacity(glow ? 0.5 : 0.2),
                    radius: glow ? 20 : 10,
                    x: 0,
                    y: 0
                )
                .animation(.spring(response: 1, dampingFraction: 0.6), value: timerProgress)
            
            // Animated dashes for running timer
            if timerManager.state == .running {
                Circle()
                    .trim(from: 0, to: 0.1)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeColor.color.opacity(0.8),
                                themeColor.color.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [2, 8])
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90 + timerDashRotation))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: timerDashRotation
                    )
            }
            
            // Center content
            VStack(spacing: 12) {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text(timeString(from: timerManager.timeRemaining))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5), value: timerManager.timeRemaining)
                    .scaleEffect(timerManager.state == .running ? 1.02 : 1)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: timerManager.state == .running
                    )
            }
        }
        .onAppear { glow = true }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Stop button
            ControlButton(
                title: "Stop",
                icon: "stop.fill",
                color: .gray,
                action: { timerManager.stop() },
                isDisabled: timerManager.state == .stopped
            )
            
            // Main control button
            ControlButton(
                title: timerManager.state == .running ? "Pause" : "Start",
                icon: timerManager.state == .running ? "pause.fill" : "play.fill",
                color: timerManager.state == .running ? .orange : themeColor.color,
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        if timerManager.state == .running {
                            timerManager.pause()
                        } else {
                            timerManager.start()
                        }
                    }
                }
            )
            .scaleEffect(timerManager.state == .running ? 1.05 : 1)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.5),
                value: timerManager.state
            )
            
            // Skip button
            ControlButton(
                title: "Skip",
                icon: "forward.fill",
                color: .green,
                action: { timerManager.skip() }
            )
        }
    }
    
    private var sessionCounter: some View {
        HStack(spacing: 20) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < (timerManager.completedSessions % 4) ?
                          themeColor.color :
                          Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .scaleEffect(index == (timerManager.completedSessions % 4) ? 1.2 : 1)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.5),
                        value: timerManager.completedSessions
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // Helper for rotating dash animation
    private var timerDashRotation: Double {
        let totalTime: TimeInterval
        switch timerManager.mode {
        case .focus: totalTime = 25 * 60
        case .shortBreak: totalTime = 5 * 60
        case .longBreak: totalTime = 15 * 60
        }
        let progress = timerProgress
        return progress * 360
    }
    
    private var timerProgress: CGFloat {
        let totalTime: TimeInterval
        switch timerManager.mode {
        case .focus: totalTime = 25 * 60
        case .shortBreak: totalTime = 5 * 60
        case .longBreak: totalTime = 15 * 60
        }
        return 1 - CGFloat(timerManager.timeRemaining / totalTime)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func playModeTransitionAnimation() {
        showModeTransition = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5)) {
                showModeTransition = false
            }
        }
    }
    
    private func startTimerAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            timerPulse = true
            ringPulse = true
        }
    }
    
    private func stopTimerAnimations() {
        withAnimation(.easeInOut(duration: 0.5)) {
            timerPulse = false
            ringPulse = false
        }
    }
}

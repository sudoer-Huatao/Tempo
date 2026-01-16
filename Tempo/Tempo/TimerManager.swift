import SwiftUI
import Combine
import AudioToolbox
import UserNotifications

class TimerManager: ObservableObject {
    enum TimerState {
        case stopped, running, paused
    }
    
    enum TimerMode: String, CaseIterable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
    }
    
    @Published var timeRemaining: TimeInterval
    @Published var state: TimerState = .stopped
    @Published var mode: TimerMode = .focus
    @Published var completedSessions: Int = 0
    
    // Store historical data
    @AppStorage("totalFocusTime") var totalFocusTime: Double = 0
    @AppStorage("totalSessions") var totalSessions: Int = 0
    @AppStorage("todaySessions") var todaySessions: Int = 0
    @AppStorage("lastSessionDate") var lastSessionDate: String = ""
    @AppStorage("weeklyData") var weeklyDataJSON: String = "[]"
    
    // Settings (with defaults)
    @AppStorage("focusDuration") private var focusDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    
    private var timer: Timer?
    private var startTime: Date?
    private var completedMode: TimerMode = .focus
    
    // Computed properties for durations
    private var focusTime: TimeInterval {
        TimeInterval(focusDuration * 60)
    }
    
    private var shortBreakTime: TimeInterval {
        TimeInterval(shortBreakDuration * 60)
    }
    
    private var longBreakTime: TimeInterval {
        TimeInterval(longBreakDuration * 60)
    }
    
    init() {
        // Initialize with default value first, then update with actual duration
        timeRemaining = 25 * 60 // Default value
        checkAndResetDailyCounter()
        loadWeeklyData()
        // Now that self is fully initialized, we can set the correct time
        resetTimer()
    }
    
    func start() {
        guard state != .running else { return }
        
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timerCompleted()
            }
        }
        state = .running
    }
    
    func pause() {
        timer?.invalidate()
        state = .paused
    }
    
    func stop() {
        timer?.invalidate()
        state = .stopped
        resetTimer()
    }
    
    func skip() {
        let previousMode = mode
        switchMode()
        sendNotification(forCompletedMode: previousMode)
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        let completedMode = mode
        switchMode()
        sendNotification(forCompletedMode: completedMode)
    }
    
    private func switchMode() {
        timer?.invalidate()
        
        completedMode = mode
        
        if mode == .focus {
            completedSessions += 1
            totalSessions += 1
            todaySessions += 1
            
            if let startTime = startTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                totalFocusTime += elapsedTime
                addToWeeklyData(time: elapsedTime)
            }
            
            updateLastSessionDate()
            
            if completedSessions % 4 == 0 {
                mode = .longBreak
                timeRemaining = longBreakTime
            } else {
                mode = .shortBreak
                timeRemaining = shortBreakTime
            }
        } else {
            mode = .focus
            timeRemaining = focusTime
        }
        
        state = .stopped
        playNotificationSound()
    }
    
    private func resetTimer() {
        // Reset to current duration based on mode
        switch mode {
        case .focus:
            timeRemaining = focusTime
        case .shortBreak:
            timeRemaining = shortBreakTime
        case .longBreak:
            timeRemaining = longBreakTime
        }
    }
    
    // Helper to reset timer when settings change
    func updateTimerDuration() {
        // If timer is not running, just reset it
        if state == .stopped {
            resetTimer()
        } else {
            // If timer is running, we need to calculate remaining time based on new duration
            let elapsedTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
            let totalTime: TimeInterval
            
            switch mode {
            case .focus:
                totalTime = focusTime
            case .shortBreak:
                totalTime = shortBreakTime
            case .longBreak:
                totalTime = longBreakTime
            }
            
            // Calculate new remaining time based on elapsed time and new total
            let newRemaining = max(totalTime - elapsedTime, 0)
            timeRemaining = newRemaining
        }
    }
    
    private func checkAndResetDailyCounter() {
        let today = getTodayString()
        if lastSessionDate != today {
            todaySessions = 0
        }
    }
    
    private func updateLastSessionDate() {
        lastSessionDate = getTodayString()
    }
    
    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Reset Method
    func resetAllData() {
            // Stop timer if running
            stop()
            
            // Reset published properties
            completedSessions = 0
            mode = .focus
            
            // Reset AppStorage values
            totalFocusTime = 0
            totalSessions = 0
            todaySessions = 0
            lastSessionDate = ""
            weeklyDataJSON = "[]"
            
            // Reset timer to default
            resetTimer()
            
            // Reset the start time
            startTime = nil
            
            // Force UI update
            objectWillChange.send()
    }
    
    // MARK: - Weekly Data Management
    struct DailyStat: Codable, Identifiable {
        var id: String { date }
        let date: String
        var sessions: Int
        var minutes: Double
        
        var dayOfWeek: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let dateObj = formatter.date(from: date) else { return "" }
            formatter.dateFormat = "EEE"
            return formatter.string(from: dateObj)
        }
    }
    
    private func loadWeeklyData() {
        guard let data = weeklyDataJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) else {
            weeklyDataJSON = "[]"
            return
        }
        let last7Days = getLast7Days()
        let filtered = decoded.filter { last7Days.contains($0.date) }
        if let encoded = try? JSONEncoder().encode(filtered) {
            weeklyDataJSON = encoded.base64EncodedString()
        }
    }
    
    private func getLast7Days() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return formatter.string(from: date)
        }.reversed()
    }
    
    private func addToWeeklyData(time: TimeInterval) {
        let today = getTodayString()
        let minutes = time / 60
        
        var weeklyData: [DailyStat] = []
        
        if let data = Data(base64Encoded: weeklyDataJSON),
           let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) {
            weeklyData = decoded
        }
        
        if let index = weeklyData.firstIndex(where: { $0.date == today }) {
            weeklyData[index].sessions += 1
            weeklyData[index].minutes += minutes
        } else {
            weeklyData.append(DailyStat(date: today, sessions: 1, minutes: minutes))
        }
        
        let last7Days = getLast7Days()
        weeklyData = weeklyData.filter { last7Days.contains($0.date) }
        
        if let encoded = try? JSONEncoder().encode(weeklyData) {
            weeklyDataJSON = encoded.base64EncodedString()
        }
    }
    
    func getWeeklyData() -> [DailyStat] {
        guard let data = Data(base64Encoded: weeklyDataJSON),
           let decoded = try? JSONDecoder().decode([DailyStat].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func playNotificationSound() {
        AudioServicesPlaySystemSound(1036)
    }
    
    private func sendNotification(forCompletedMode: TimerMode) {
        let content = UNMutableNotificationContent()
        
        switch forCompletedMode {
        case .focus:
            content.title = "Focus Session Complete! 🎯"
            content.body = "Great work! Time for a well-deserved break."
            
        case .shortBreak:
            content.title = "Break Complete! ☕️"
            content.body = "Refreshed and ready? Time for another focus session!"
            
        case .longBreak:
            content.title = "Long Break Complete! 🌟"
            content.body = "You've earned it! Ready for your next focus session?"
        }
        
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

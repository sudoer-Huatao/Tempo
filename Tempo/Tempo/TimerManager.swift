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
    
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var state: TimerState = .stopped
    @Published var mode: TimerMode = .focus
    @Published var completedSessions: Int = 0
    
    // Store historical data
    @AppStorage("totalFocusTime") var totalFocusTime: Double = 0
    @AppStorage("totalSessions") var totalSessions: Int = 0
    @AppStorage("todaySessions") var todaySessions: Int = 0
    @AppStorage("lastSessionDate") var lastSessionDate: String = ""
    @AppStorage("weeklyData") var weeklyDataJSON: String = "[]"
    
    private var timer: Timer?
    private let focusTime: TimeInterval = 25 * 60
    private let shortBreakTime: TimeInterval = 5 * 60
    private let longBreakTime: TimeInterval = 15 * 60
    private var startTime: Date?
    
    init() {
        resetTimer()
        checkAndResetDailyCounter()
        loadWeeklyData()
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
        switchMode()
    }
    
    private func switchMode() {
        timer?.invalidate()
        
        if mode == .focus {
            completedSessions += 1
            totalSessions += 1
            todaySessions += 1
            
            // Track completed focus session duration
            if let startTime = startTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                totalFocusTime += elapsedTime
                
                // Add to weekly data
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
        sendNotification()
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        switchMode()
    }
    
    private func resetTimer() {
        switch mode {
        case .focus:
            timeRemaining = focusTime
        case .shortBreak:
            timeRemaining = shortBreakTime
        case .longBreak:
            timeRemaining = longBreakTime
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
    
    // MARK: - Public Helper Methods
    func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
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
        // Ensure we only keep last 7 days
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
        
        // Keep only last 7 days
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
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        
        switch mode {
        case .focus:
            content.title = "Focus Session Complete!"
            content.body = "Time for a break. Stand up and stretch!"
        case .shortBreak, .longBreak:
            content.title = "Break Complete!"
            content.body = "Ready for your next focus session?"
        }
        
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var timerManager = TimerManager()
    @AppStorage("themeColor") private var themeColor = "red"
    @State private var selectedStat: Int = 0
    
    var weeklyData: [TimerManager.DailyStat] {
        timerManager.getWeeklyData()
    }
    
    var totalSessionsThisWeek: Int {
        weeklyData.reduce(0) { $0 + $1.sessions }
    }
    
    var totalMinutesThisWeek: Int {
        Int(weeklyData.reduce(0) { $0 + $1.minutes })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Statistics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Track your productivity journey")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Quick Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatCard(
                        title: "Today",
                        value: "\(timerManager.todaySessions)",
                        subtitle: "sessions",
                        icon: "flame.fill",
                        color: themeColor.color,
                        animationDelay: 0.1
                    )
                    
                    StatCard(
                        title: "This Week",
                        value: "\(totalSessionsThisWeek)",
                        subtitle: "sessions",
                        icon: "calendar",
                        color: themeColor.color,
                        animationDelay: 0.2
                    )
                    
                    StatCard(
                        title: "Total Time",
                        value: "\(Int(timerManager.totalFocusTime / 3600))h",
                        subtitle: "focused",
                        icon: "clock.fill",
                        color: themeColor.color,
                        animationDelay: 0.3
                    )
                }
                .padding(.horizontal)
                
                // Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights")
                        .font(.headline)
                    
                    if !weeklyData.isEmpty {
                        if let bestDay = weeklyData.max(by: { $0.sessions < $1.sessions }) {
                            InsightCard(
                                title: "Best Day",
                                description: "\(bestDay.dayOfWeek) with \(bestDay.sessions) sessions",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                        }
                        
                        let averageSessions = weeklyData.isEmpty ? 0 : Double(totalSessionsThisWeek) / Double(weeklyData.count)
                        InsightCard(
                            title: "Daily Average",
                            description: String(format: "%.1f sessions per day", averageSessions),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                        
                        // Calculate streak
                        let streak = calculateCurrentStreak()
                        InsightCard(
                            title: "Current Streak",
                            description: "\(streak) day\(streak == 1 ? "" : "s") in a row",
                            icon: "bolt.fill",
                            color: .orange
                        )
                    } else {
                        InsightCard(
                            title: "No Data Yet",
                            description: "Complete some focus sessions to see insights",
                            icon: "chart.bar.doc.horizontal",
                            color: .gray
                        )
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            // Refresh data when view appears
            let _ = timerManager.getWeeklyData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .timerDataReset)) { _ in
            // When reset notification is received, create a new TimerManager instance
            // This forces the StatsView to reload with fresh data
            // Note: In SwiftUI, we can't directly replace the StateObject,
            // but the TimerManager will reset itself when it receives the notification
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        // Sort dates in descending order
        let dates = weeklyData
            .compactMap { dateString -> Date? in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: dateString.date)
            }
            .sorted(by: >)
        
        var streak = 0
        var currentDate = today
        
        // Check consecutive days
        for date in dates {
            if calendar.isDate(date, inSameDayAs: currentDate) ||
               calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }
        
        return streak
    }
}

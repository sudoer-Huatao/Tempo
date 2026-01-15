import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var timerManager = TimerManager()
    @AppStorage("themeColor") private var themeColor = "blue"
    @State private var selectedStat: Int = 0
    
    var weeklyData: [TimerManager.DailyStat] {
        timerManager.getWeeklyData()
    }
    
    var todayData: TimerManager.DailyStat? {
        weeklyData.first { $0.date == timerManager.getTodayString() }
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
                
                // Weekly Chart
                if !weeklyData.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Weekly Overview")
                                .font(.headline)
                            Spacer()
                            Picker("", selection: $selectedStat) {
                                Text("Sessions").tag(0)
                                Text("Minutes").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                        
                        Chart(weeklyData) { data in
                            BarMark(
                                x: .value("Day", data.dayOfWeek),
                                y: .value("Value", selectedStat == 0 ? Double(data.sessions) : data.minutes)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [themeColor.color, themeColor.color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(6)
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                    .padding()
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                } else {
                    EmptyChartView(color: themeColor.color)
                }
                
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

struct EmptyChartView: View {
    let color: Color
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(color.opacity(0.3))
                .scaleEffect(animate ? 1.1 : 1)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
                .onAppear { animate = true }
            
            Text("No data yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Complete focus sessions to see your weekly progress")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
}

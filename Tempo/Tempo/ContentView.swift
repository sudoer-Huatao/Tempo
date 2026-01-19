import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @AppStorage("selectedTab") private var selectedTab = 0
    @State private var sidebarVisible = true
    
    var body: some View {
        NavigationView {
            if sidebarVisible {
                SidebarView(selectedTab: $selectedTab, sidebarVisible: $sidebarVisible)
                    .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
                    .transition(.move(edge: .leading))
            }
            
            mainContentView
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: sidebarVisible ? "sidebar.left" : "sidebar.right")
                }
            }
        }
        .navigationTitle("Tempo")
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .timerDataReset)) { _ in
            // When reset notification is received, reset the TimerManager
            timerManager.resetAllData()
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            Color(.windowBackgroundColor)
                .ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case 0:
                    TimerView(timerManager: timerManager)
                case 1:
                    StatsView()
                case 2:
                    SettingsView() // No parameter needed
                default:
                    TimerView(timerManager: timerManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sidebarVisible.toggle()
        }
    }
}

// Extension for notification name
extension Notification.Name {
    static let timerDataReset = Notification.Name("timerDataReset")
}

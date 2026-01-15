import SwiftUI

struct SettingsView: View {
    @AppStorage("focusDuration") private var focusDuration = 25
    @AppStorage("shortBreakDuration") private var shortBreakDuration = 5
    @AppStorage("longBreakDuration") private var longBreakDuration = 15
    @AppStorage("autoStartBreaks") private var autoStartBreaks = true
    @AppStorage("autoStartFocus") private var autoStartFocus = false
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSounds") private var enableSounds = true
    @AppStorage("themeColor") private var themeColor = "red"
    
    let themeColors = [
        ("red", "Red", Color.pink),
        ("blue", "Blue", Color.blue),
        ("green", "Green", Color.green),
        ("orange", "Orange", Color.orange),
        ("purple", "Purple", Color.purple),
    ]
    
    @State private var showingResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Customize your Tempo experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Timer Settings
                SettingsSection(title: "Timer Settings", icon: "timer") {
                    DurationSlider(
                        value: $focusDuration,
                        label: "Focus Duration",
                        icon: "brain.head.profile",
                        range: 5...60,
                        suffix: "min"
                    )
                    
                    DurationSlider(
                        value: $shortBreakDuration,
                        label: "Short Break",
                        icon: "cup.and.saucer",
                        range: 1...15,
                        suffix: "min"
                    )
                    
                    DurationSlider(
                        value: $longBreakDuration,
                        label: "Long Break",
                        icon: "bed.double.fill",
                        range: 5...30,
                        suffix: "min"
                    )
                }
                
                // Behavior
                SettingsSection(title: "Behavior", icon: "arrow.triangle.2.circlepath") {
                    ToggleRow(
                        icon: "play.circle.fill",
                        label: "Auto-start breaks",
                        isOn: $autoStartBreaks
                    )
                    
                    ToggleRow(
                        icon: "pause.circle.fill",
                        label: "Auto-start focus sessions",
                        isOn: $autoStartFocus
                    )
                }
                
                // Notifications & Sounds
                SettingsSection(title: "Notifications & Sounds", icon: "bell.badge.fill") {
                    ToggleRow(
                        icon: "bell.fill",
                        label: "Enable notifications",
                        isOn: $enableNotifications
                    )
                    
                    ToggleRow(
                        icon: "speaker.wave.2.fill",
                        label: "Enable sounds",
                        isOn: $enableSounds
                    )
                }
                
                // Appearance
                SettingsSection(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme Color")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(themeColors, id: \.0) { id, name, color in
                                ThemeColorButton(
                                    color: color,
                                    name: name,
                                    isSelected: themeColor == id
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeColor = id
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                // Reset & About
                SettingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(spacing: 16) {
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.red)
                                Text("Reset All Data")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tempo v1.0.0")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal)
        }
        .background(Color(.windowBackgroundColor))
        .alert("Reset All Data?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all your statistics and reset settings to defaults. This action cannot be undone.")
        }
    }
    
    private func resetAllData() {
        focusDuration = 25
        shortBreakDuration = 5
        longBreakDuration = 15
        autoStartBreaks = true
        autoStartFocus = false
        enableNotifications = true
        enableSounds = true
        themeColor = "red"
        
        // Clear app storage for stats
        UserDefaults.standard.removeObject(forKey: "totalFocusTime")
        UserDefaults.standard.removeObject(forKey: "totalSessions")
        UserDefaults.standard.removeObject(forKey: "todaySessions")
        UserDefaults.standard.removeObject(forKey: "lastSessionDate")
        UserDefaults.standard.removeObject(forKey: "weeklyData")
        
        // Force update the view
        let _ = TimerManager()
    }
}

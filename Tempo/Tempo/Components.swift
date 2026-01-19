import SwiftUI

// MARK: - Common UI Components

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let animationDelay: Double
    
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                    
                    Text(value)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
            }
            .padding(20)
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        .scaleEffect(appear ? 1 : 0.8)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                appear = true
            }
        }
    }
}

// MARK: - InsightCard Component
struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - ControlButton Component
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 70)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 20) {
                content
            }
            .padding(20)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        }
    }
}

struct DurationSlider: View {
    @Binding var value: Int
    let label: String
    let icon: String
    let range: ClosedRange<Int>
    let suffix: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text("\(value) \(suffix)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .monospacedDigit()
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(label)
                Spacer()
            }
        }
        .toggleStyle(SwitchToggleStyle())
    }
}

struct ThemeColorButton: View {
    let color: Color
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .shadow(color: color.opacity(isSelected ? 0.5 : 0.1), radius: isSelected ? 4 : 2)
                    .scaleEffect(isSelected ? 1.1 : 1)
                
                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Theme Color Extension
extension String {
    var color: Color {
        switch self {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .blue
        }
    }
}

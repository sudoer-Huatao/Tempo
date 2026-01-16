import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Int
    @Binding var sidebarVisible: Bool
    @Namespace private var namespace
    
    var body: some View {
        VStack(spacing: 0) {
            // App Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Tempo")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider()
            }
            
            // Navigation Items
            VStack(spacing: 8) {
                SidebarItem(
                    title: "Timer",
                    icon: "timer",
                    isSelected: selectedTab == 0,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = 0
                    }
                }
                
                SidebarItem(
                    title: "Statistics",
                    icon: "chart.bar.fill",
                    isSelected: selectedTab == 1,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = 1
                    }
                }
                
                SidebarItem(
                    title: "Settings",
                    icon: "gearshape.fill",
                    isSelected: selectedTab == 2,
                    namespace: namespace
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 20)
            
            Spacer()
            
            // Status indicator
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .opacity(0.6)
                    Text("v1.0.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        )
    }
}

struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20)
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .matchedGeometryEffect(id: "tab", in: namespace)
                }
            }
        )
        .contentShape(Rectangle())
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

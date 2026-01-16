import SwiftUI

@main
struct TempoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 600)
                .frame(maxWidth: 800, maxHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) { }
        }
    }
}

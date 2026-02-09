import SwiftUI

@main
struct FolderSizeVisualizerApp: App {
    @State var isDeveloperMode = false
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if isDeveloperMode {
                    ArtifactContentView(isDeveloperModeEnabled: $isDeveloperMode)
                } else {
                    ContentView(navigationStack: [], isDeveloperModeEnabled: $isDeveloperMode)
                }
            }
        }
    }
}

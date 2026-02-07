import SwiftUI

@main
struct FolderSizeVisualizerApp: App {
    var body: some Scene {
        WindowGroup {
            // New artifact-based developer intelligence view
            ArtifactContentView()
            
            // To use old folder-based view instead, uncomment:
             ContentView(navigationStack: [])
        }
    }
}

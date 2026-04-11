import SwiftUI

@main
struct FolderSizeVisualizerApp: App {
    @Stored(AppKeys.suppressGlobalDeletionWarning) private var suppressGlobalDeletionWarning: Bool
    @State private var showGlobalWarningBanner: Bool = true
    @State private var showGlobalWarningBannerCheck: Bool = false
    @State var isDeveloperMode = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                VStack {
                    if isDeveloperMode {
                        ArtifactContentView(isDeveloperModeEnabled: $isDeveloperMode)
                    } else {
                        ContentView(navigationStack: [], isDeveloperModeEnabled: $isDeveloperMode)
                    }
                }
                
                if showGlobalWarningBanner && !suppressGlobalDeletionWarning {
                    ZStack {
                        // Fondo con blur / glass effect
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                        
                        // Contenido centrado
                        VStack {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.largeTitle)
                                
                                Text("Warning: Deleting developer artifacts is at your own risk.")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                Text("Review details carefully. Some items may be essential to your workflows.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Button("Accept") {
                                        withAnimation {
                                            showGlobalWarningBanner = false
                                        }
                                    }
                                    Toggle("Don't show again", isOn: $showGlobalWarningBannerCheck)
                                        .onChange(of: showGlobalWarningBannerCheck) { _, newValue in
                                            suppressGlobalDeletionWarning = newValue
                                        }
//                                    Toggle("Don't show again", isOn: Binding(
//                                        get: { suppressGlobalDeletionWarning },
//                                        set: { suppressGlobalDeletionWarning = $0 }
//                                    ))
                                    .toggleStyle(.checkbox)
                                    .font(.caption)
                                }
                            }
                            .padding(24)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 20)
                        }
                        .padding()
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .onAppear {
                showGlobalWarningBanner = !suppressGlobalDeletionWarning
            }
        }
    }
}

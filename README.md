# Developer Disk Analyzer

<div align="center">

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Swift Tests](https://img.shields.io/badge/Swift%20Tests-Framework-orange)
![macOS](https://img.shields.io/badge/macOS-15.6+-000000?logo=apple)
![Xcode](https://img.shields.io/badge/Xcode-16.0+-007ACC?logo=xcode)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue)

</div>

<div align="center">
<strong>Built with ❤️ for developers who care about their disk space</strong>
</div>

---
<div align="center">
    
[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/default-orange.png)](https://buymeacoffee.com/andrespalah)

</div>


---

## 🎯 Overview

**Developer Disk Analyzer** is a sophisticated macOS application designed exclusively for developers. It transforms generic filesystem analysis into intelligent developer-tool artifact management, providing actionable insights into disk usage by developer tools and frameworks.

Unlike generic disk analyzers that show filesystem paths, this tool speaks the language of developers: **Xcode, Simulators, Docker, Node.js, and more** — not folders.

---

## ✨ Key Features

### 🛠️ Developer Tool Intelligence

| Tool | Detected Artifacts |
|------|-------------------|
| **Xcode** | DerivedData, Archives, DeviceSupport, DeviceLogs | 
| **iOS Simulators** | Devices, Runtimes, Caches | 
| **Android SDK** | SDK components, AVDs |
| **Node.js** | npm cache, Yarn cache |
| **Docker** | Images, containers, volumes |
| **Homebrew** | Download cache |
| **Python** | pip cache, Poetry cache |
| **Rust** | Cargo registry, Cargo git |

### 🎨 User Experience

- **Tool-Centric Navigation**: Browse by developer tool, not filesystem paths
- **Risk-Based Safety Badges**: Every artifact displays whether it's safe to delete
- **Rebuild Cost Estimates**: Understand the impact before any deletion
- **Real-Time Progress**: Live scan progress with throttled updates
- **Smart Actions**: "Clean Safe Artifacts" for batch cleanup

### 🏗️ Architecture

- **Actor-Based Concurrency**: Thread-safe, parallel file system scanning
- **Protocol-Oriented Design**: Easy to extend with new tools
- **Sendable Models**: Safe cross-actor data flow
- **MVVM Pattern**: Clean separation of concerns

---

## 📸 Screenshots

### Dashboard View
#### Normal mode
<img width="1271" height="791" alt="Developer Mode" src="https://github.com/user-attachments/assets/e2af8226-2fb5-4d14-94d6-813ee3d77c5e" />

#### Developer mode
<img width="1271" height="953" alt="image" src="https://github.com/user-attachments/assets/9027eb4d-4f45-4464-a7c1-f3e8c1ac7838" />

### Artifact Detail View
#### Normal mode
<img width="444" height="846" alt="image" src="https://github.com/user-attachments/assets/0ea5d600-adf0-4fb3-a94d-f2957b6020a9" />

#### Developer mode
<img width="444" height="846" alt="image" src="https://github.com/user-attachments/assets/1cd128fd-8230-4cd3-a19f-5509c9852493" />

---

## 🚀 Installation

### System Requirements

- **macOS**: 15.6 (Sonoma) or later
- **Swift**: 6.0 or later
- **Xcode**: 16.0 or later
- **Memory**: 8GB RAM minimum

### Build from Source

```bash
# Clone the repository
git clone https://github.com/AD-Paladins/FolderSizeVisualizer.git
cd FolderSizeVisualizer

# Open in Xcode
open FolderSizeVisualizer.xcodeproj

# Build and run
⌘ + R
```

### Build via Command Line

```bash
cd FolderSizeVisualizer

# Clean build
xcodebuild clean build -project FolderSizeVisualizer.xcodeproj

# Run tests
xcodebuild test -project FolderSizeVisualizer.xcodeproj -scheme FolderSizeVisualizerTests
```

---

## 📖 Usage Guide

### Quick Start

1. **Launch the application**
2. **Click "Scan System"** in the sidebar to begin analysis
3. **Review the Dashboard** showing tool footprints sorted by size
4. **Select a tool** from the sidebar to see detailed artifact breakdown
5. **Clean safe artifacts** using the green "Clean Safe Artifacts" button

### Navigation Structure

```
┌─────────────────────────────────────────────────────────┐
│  Folder Size Visualizer                                 │
├──────────────┬──────────────────┬───────────────────────┤
│  Sidebar     │  Content Area    │  Detail Pane          │
│  ────────────┼──────────────────┼───────────────────────│
│  Scan System │  Dashboard       │  Artifact Detail      │
│              │ ──────────────── │  ───────────────────  │
│  Xcode       │  • Tool Cards    │  • What is this?      │
│  iOS         │  • Quick Actions │  • Size info          │
│  Android     │                  │  • Safety status      │
│  Docker      │                  │  • Rebuild cost       │
│  Node.js     │                  │  • Underlying paths   │
│  ...         │                  │                       │
└──────────────┴──────────────────┴───────────────────────┘
```

### Workflow Examples

#### Safe Batch Cleanup

```swift
// In the UI:
1. Select "Xcode" from sidebar
2. See "Clean Safe Artifacts" button with size
3. Click button → Confirmation dialog appears
4. Confirm → All safe artifacts deleted
5. View results with success/failure count
```

#### Individual Artifact Review

```swift
// For careful management:
1. Click any artifact card
2. Read the detailed explanation
3. Check safety badge and rebuild cost
4. Decide whether to keep or delete
```

---

## 🏗️ Architecture Overview

### Project Structure

```
FolderSizeVisualizer/
├── Models/
│   ├── DeveloperArtifact.swift      # Core artifact model
│   └── FolderEntry.swift            # Legacy folder model
├── Services/
│   ├── ArtifactScanner.swift        # Scanning orchestration
│   ├── FolderScanner.swift          # Legacy scanner
│   └── ArtifactDetectors/
│       ├── XcodeArtifactDetector.swift
│       ├── SimulatorArtifactDetector.swift
│       ├── AndroidArtifactDetector.swift
│       ├── NodeJSArtifactDetector.swift
│       ├── DockerArtifactDetector.swift
│       ├── HomebrewArtifactDetector.swift
│       ├── PythonArtifactDetector.swift
│       └── RustArtifactDetector.swift
├── ViewModels/
│   ├── ArtifactScanViewModel.swift  # Main ViewModel
│   └── ScanViewModel.swift          # Legacy ViewModel
├── Views/
│   ├── ArtifactContentView.swift    # Main 3-column layout
│   ├── ContentView.swift            # Legacy view
│   ├── ArtifactViews/
│   │   ├── DashboardView.swift
│   │   ├── ArtifactSidebarView.swift
│   │   ├── ToolDetailView.swift
│   │   └── ToolDetailView.swift
│   └── MainView/
│       ├── ResultsListView.swift
│       └── SidebarView.swift
├── UIComponents/
│   └── PieChartView.swift           # Visualizations
└── Extensions/
    └── URL+Extensions.swift
```

### Concurrency Model

```swift
// Actor-based isolation for file operations
actor FileSystemHelper {
    func directorySize(at url: URL) async -> Int64
    func deleteFiles(at urls: [URL]) async throws -> [URL]
}

// Parallel detector execution
actor XcodeArtifactDetector {
    func detect(progress: @escaping (Double, String) async -> Void) async -> [DeveloperArtifact]
}

// UI state management
@Observable @MainActor
class ArtifactScanViewModel {
    var isScanning = false
    var progress = 0.0
    var currentTool = "Scanning Xcode..."
    var selectedTool: DeveloperTool?
}
```

### Data Flow

```
┌──────────────────────────────────────────────────────────┐
│                    User Action                           │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                 ArtifactScanViewModel                    │
│                  (UI State Management)                   │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                  ArtifactScanService                     │
│                   (Orchestration)                        │
└──────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Xcode        │  │ Simulator    │  │ Android      │
│ Detector     │  │ Detector     │  │ Detector     │
└──────────────┘  └──────────────┘  └──────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                  FileSystemHelper                        │
│                   (File Operations)                      │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                    File System                           │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│              DeveloperArtifact Models                    │
│              (Typed, Sendable, Observable)               │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                SwiftUI Views                             │
│              (Reactive, Declarative)                     │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Configuration

### Security Permissions

This app **Doesn't require internet connection**.

The app requires the following permissions:

1. **Full Disk Access** - Required for scanning all developer directories
2. **File System Access** - Required for safe deletion operations

#### Granting Full Disk Access

```bash
# Via Settings
System Settings → Privacy & Security → Full Disk Access
→ Click + and add Folder Size Visualizer
```

---

## 🧪 Testing

### Unit Tests

```bash
xcodebuild test -project FolderSizeVisualizer.xcodeproj \
    -scheme FolderSizeVisualizerTests \
    -destination 'platform=macOS'
```

### Recommended Test Coverage

```swift
// Detector Tests
testXcodeDetector_findsDerivedData()
testSimulatorDetector_parsesSimctlOutput()
testNodeJSDetector_findsNpmCache()

// Service Tests
testArtifactScanService_scansAllTools()
testArtifactScanService_skipsUninstalledTools()
testArtifactScanService_reportsProgress()

// ViewModel Tests
testViewModel_startsAndCancelsScan()
testViewModel_deletesArtifactSafely()
testViewModel_batchDeletesSafeArtifacts()
```

---

## 🚧 Development

### Adding a New Tool Detector

1. **Add to `DeveloperTool` enum**
   ```swift
   case newTool
   ```

2. **Create detector actor**
   ```swift
   actor NewToolArtifactDetector: ArtifactDetector {
       var tool: DeveloperTool { .newTool }
       
       func detect(progress: @escaping (Double, String) async -> Void) async -> [DeveloperArtifact] {
           // Implementation
       }
   }
   ```

3. **Add to scan service**
   ```swift
   let detectors: [any ArtifactDetector] = [
       // ... existing detectors
       NewToolArtifactDetector(),
   ]
   ```

4. **UI automatically updates!** ✨

### AI-Assisted Development

This project uses custom slash commands for AI coding tools. See
[`docs/scripts/ai-commands-setup.md`](docs/scripts/ai-commands-setup.md) for setup instructions.

### Code Style

- **Swift Format**: Run `swift-format format --recursive .`
- **Linting**: Configure SwiftLint for consistency
- **Naming**: PascalCase for types, camelCase for properties

---

## 📄 Documentation

| Document | Description |
|----------|-------------|
| [`DESIGN_SPECIFICATION.md`](DESIGN_SPECIFICATION.md) | Figma-ready UI/UX specification |
| [`docs/scripts/ai-commands-setup.md`](docs/scripts/ai-commands-setup.md) | AI command installation for OpenCode / Claude Code |

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Areas of Interest

- 🔧 **Add new tool detectors** (Flutter, Unity, VS Code, etc.)
- 📊 **Enhanced visualization** (trend graphs, export features)
- 🔍 **Search and filter** functionality
- ⚙️ **Configuration options** (custom paths, scheduled scans)
- 🎨 **UI polish** (animations, transitions, dark mode improvements)

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write tests
5. Submit a pull request

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with **Swift** and **SwiftUI**
- Icons via **SF Symbols**
- Inspired by the need for better developer disk management tools
- Built using **Xcode 16.0+**

---

## 📞 Support

- **Documentation**: See the [DESIGN_SPECIFICATION.md](DESIGN_SPECIFICATION.md) for detailed UI/UX specs
- **Bug Reports**: [GitHub Issues](https://github.com/your-org/folder-size-visualizer/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/your-org/folder-size-visualizer/discussions)

---

## 🎯 Success Criteria

This tool succeeds when users can immediately answer:

| Question | Answer Location |
|----------|----------------|
| "Why is my disk full?" | Dashboard tool cards |
| "What is safe to delete?" | Safety badges on every artifact (I'm still not responsible on any possible way) |
| "How much space can I reclaim?" | "Safe to Delete" totals |
| "Which tools are the problem?" | Sorted by size in sidebar |
| "What happens if I delete this?" | Rebuild cost + risk per artifact |

---

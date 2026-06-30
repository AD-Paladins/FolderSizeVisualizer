# Module Breakdown

## Models

**Owns:** `DeveloperArtifact`, `ToolArtifactSummary`, `ArtifactRiskLevel`, `DeveloperTool`, legacy `FolderEntry`  
**Depends on:** Nothing (pure Swift)  
**Entry points:** Public model types with `Sendable`, `Codable`, `Identifiable` conformance  
**Status:** Active

## Services

**Owns:** `ArtifactScanService`, `FileSystemHelper`, `ToolIntelligenceService`, legacy `FolderScanner`  
**Depends on:** Models, Foundation, AppKit  
**Entry points:** `ArtifactDetector` protocol, `FileSystemHelper` actor  
**Status:** Active

### Detectors (sub-module)

**Owns:** `XcodeArtifactDetector`, `SimulatorArtifactDetector`, `AndroidArtifactDetector`, `NodeJSArtifactDetector`, `DockerArtifactDetector`, `HomebrewArtifactDetector`, `PythonArtifactDetector`, `RustArtifactDetector`, `VenvArtifactDetector`, `LLMArtifactDetector`  
**Depends on:** Services (FileSystemHelper)  
**Entry points:** `ArtifactDetector` protocol  
**Status:** Active

## ViewModels

**Owns:** `ArtifactScanViewModel`, legacy `ScanViewModel`  
**Depends on:** Models, Services  
**Entry points:** `@Observable` properties consumed by views  
**Status:** Active

## Views

**Owns:** `ArtifactContentView`, `ArtifactSidebarView`, `DashboardView`, `ToolDetailView`, `ArtifactDetailView`, `DetailSection`; legacy `ContentView`, `SidebarView`, `ResultsListView`, `FolderDetailView`  
**Depends on:** ViewModels, Models  
**Entry points:** SwiftUI `View` types  
**Status:** Active (artifact views), Legacy (folder views)

## UIComponents

**Owns:** `PieChartView`  
**Depends on:** Nothing (pure SwiftUI Shape)  
**Status:** Legacy (unused by current UI)

## Utilities

**Owns:** `FullDiskAccess`, `KeyValueStore` / `UserDefaultsStore` / `KeychainStore`, `Stored` / `SecureStored` property wrappers, `MarkdownText`  
**Depends on:** Security, AppKit, OSLog  
**Entry points:** Public API for persistence and permissions  
**Status:** Active

## Extensions

**Owns:** `URL+Extensions`, `String+Extensions`, `SystemLanguageModel` extensions  
**Depends on:** Foundation  
**Status:** Active

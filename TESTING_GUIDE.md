# Unit Testing Guide for FolderSizeVisualizer

## Overview

This app now includes comprehensive unit tests using Apple's Swift Testing framework. The test suite covers all major components with a focus on functional correctness, caching behavior, and edge cases.

## Test Coverage Summary

### 1. **FolderEntry Tests**
Tests for the `FolderEntry` model that represents a directory with its size information.

- ✅ **Name Computation** - Validates that the `name` property correctly returns:
  - The last path component for regular directories
  - The full path for root directory

- ✅ **Identifiability** - Verifies that each FolderEntry instance gets a unique `id` UUID

- ✅ **Hashability** - Confirms that FolderEntry conforms to Hashable and works correctly in Sets

### 2. **FolderScanner Tests** (Core Business Logic)

#### Basic Functionality
- ✅ **Aggregation & Sorting** - Validates that:
  - Directory sizes are correctly aggregated from all nested files
  - Results are sorted by size in descending order
  - Size calculations match the allocated file sizes

#### **Caching Behavior** (⭐ Critical Feature)
- ✅ **Cache Population** - First scan caches results
- ✅ **Cache Retrieval** - `getCachedResult()` returns correct cached data
- ✅ **Cache Miss** - Uncached URLs correctly return `nil`
- ✅ **Cache Speed** - Subsequent scans return instantly from cache
- ✅ **Cache Invalidation** - `clearCache()` removes all cached entries
- ✅ **Selective Refresh** - `refreshScan()` invalidates cache for specific URLs

#### **Progress Tracking**
- ✅ **Progress Callback** - Progress handler is called during scanning with:
  - Progress value (0.0 to 1.0+)
  - Current folder name being scanned

### 3. **ScanViewModel Tests** (UI State Management)

#### Scanning Operations
- ✅ **Scan Lifecycle** - Full scan operation:
  - Updates `isScanning` flag appropriately
  - Populates `folders` array
  - Calculates `totalSize` correctly
  - Maintains state flags after completion

- ✅ **Cancellation** - `cancelScan()` immediately stops scanning
- ✅ **Restart Handling** - Starting a new scan cancels any previous scan

#### **Result Limiting**
- ✅ **Limit Application** - `applyLimit()` respects `maxResults` when enabled
- ✅ **Limit Disabling** - Returns full results when `limitResults = false`
- ✅ **Integration** - Scan automatically applies limits to result set

#### **Cache Management**
- ✅ **Refresh** - `refreshScan()` clears cache and rescans directory
- ✅ **Reset** - `resetAll()` clears:
  - All cached data
  - Current scan state
  - UI properties (`folders`, `progress`, etc.)

#### **Progress UI Updates**
- ✅ **Progress Property Updates** - `progress` property updates during scan

### 4. **Edge Case Tests**

- ✅ **Empty Directory** - Handles directories with no subdirectories
- ✅ **Single Folder** - Correctly scans directory with one subdirectory
- ✅ **Total Size Calculation** - Correctly sums all folder sizes

## Running Tests

### Using Xcode
```bash
# Run all tests
⌘ U (Command+U)

# Or from terminal:
cd FolderSizeVisualizer
xcodebuild test -scheme FolderSizeVisualizer
```

### Viewing Results
Test results appear in:
- **Xcode UI**: Product → Test Results
- **Terminal**: Test summary in build output
- **Test Navigator**: ⌘ + 9

## Test Organization By Category

### Unit Tests (Functional)
- Model tests (FolderEntry)
- Business logic tests (FolderScanner)
- ViewModel state tests (ScanViewModel)

### Integration Tests
- Full scan workflows
- Cache interaction tests
- UI state binding tests

## Key Testing Patterns Used

### 1. **Temporary Directory Setup**
```swift
let (root, expected) = try makeTempDirectoryStructure()
defer { removeDirectory(root) }
```
Each test creates isolated temporary directories that are automatically cleaned up.

### 2. **Async/Await Testing**
Tests properly handle async operations using `async throws`, `await`, and `@MainActor` annotations.

### 3. **Progress Tracking Verification**
Progress handlers are validated with closure captures to ensure they're called at appropriate times.

### 4. **State Assertion Pattern**
Tests poll for state changes with timeouts to handle async operations:
```swift
while vm.isScanning && elapsed < timeout {
    try await Task.sleep(nanoseconds: 50_000_000)
}
#expect(vm.isScanning == false)
```

## Test Metrics

- **Total Test Functions**: 20+
- **Lines of Test Code**: 350+
- **Coverage Areas**: 
  - Models (1)
  - Services (6)
  - ViewModels (13)

## Future Testing Improvements

### Potential Additions
1. **Performance Tests** - Measure scan speed with varying file counts
2. **Error Handling** - Permission denied, deleted directories, symbolic links
3. **Memory Tests** - Verify cache doesn't grow unboundedly
4. **UI Tests** - Integration with SwiftUI components
5. **Concurrent Scanning** - Multiple simultaneous scans
6. **Large Directory Tests** - Real-world filesystem structures

### Mock Services (Optional)
Could mock `FileManager` for:
- Testing error conditions without filesystem risks
- Faster test execution
- Deterministic test behavior

## Testing Best Practices Used

✅ **Isolation** - Each test is independent with cleanup  
✅ **Clarity** - Descriptive test names indicate what's being tested  
✅ **Comprehensiveness** - Both happy path and edge cases covered  
✅ **Async Safety** - Proper use of Swift's async/await  
✅ **Actor Safety** - Respects MainActor isolation  
✅ **Performance** - Tests complete quickly using small datasets  

## Troubleshooting

### Tests Timeout
- Check if filesystem is busy
- Ensure temporary directory cleanup isn't blocked
- Reduce test data size if needed

### Main Actor Isolation Errors
Tests accessing `FolderEntry` properties use `@MainActor` annotation since the model is MainActor-isolated.

### Progress Handler Closure Issues
Ensure closure signature matches: `(Double, String) async -> Void`

## Next Steps

1. ✅ Run tests locally with `⌘ + U`
2. Review test output for coverage gaps
3. Consider adding performance benchmarks
4. Set up CI/CD to run tests on commits
5. Expand tests as new features are added

---

**Last Updated**: February 6, 2026  
**Testing Framework**: Apple Swift Testing  
**Minimum Swift Version**: 5.9+

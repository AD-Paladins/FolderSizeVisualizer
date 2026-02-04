
import SwiftUI
import Combine

struct FolderInfo: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let category: SizeCategory
}

enum SizeCategory: String, CaseIterable {
    case large = "Large"
    case medium = "Medium"
    case small = "Small"
}

class FolderScanner: ObservableObject {
    
    @Published var folders: [FolderInfo] = []
    @Published var error: String? = nil
    @Published var showPicker: Bool = false
    
    func scanDirectory(at url: URL) {
        folders = []
        error = nil
        showPicker = false
        let fileManager = FileManager.default
        guard let enumerator = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            error = "Invalid directory."
            return
        }
        for entry in enumerator {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: entry.path, isDirectory: &isDir), isDir.boolValue {
                let size = self.folderSize(at: entry)
                let category = self.classify(size: size)
                let info = FolderInfo(name: entry.lastPathComponent, size: size, category: category)
                folders.append(info)
            }
            folders.sort { $0.size > $1.size }
        }
    }

    func folderSize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var total: Int64 = 0
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    if resourceValues.isRegularFile == true, let fileSize = resourceValues.fileSize {
                        total += Int64(fileSize)
                    }
                } catch { continue }
            }
        }
        return total
    }

    func classify(size: Int64) -> SizeCategory {
        let gb: Int64 = 1024 * 1024 * 1024
        let mb: Int64 = 1024 * 1024
        if size >= gb {
            return .large
        } else if size >= 100 * mb {
            return .medium
        }
        return .small
    }
}

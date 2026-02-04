
import SwiftUI
import AppKit

struct FolderPicker: NSViewControllerRepresentable {
    var onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.begin { response in
                if response == .OK {
                    onPick(panel.urls.first)
                } else {
                    onPick(nil)
                }
            }
        }
        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    class Coordinator {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) {
            self.onPick = onPick
        }
    }
}

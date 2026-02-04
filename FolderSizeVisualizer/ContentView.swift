import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = FolderScanner()
    @State private var folderURL: URL? = nil
    @State private var showPickerTrigger = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Folder Size Visualizer")
                .font(.largeTitle)
                .padding(.top)
            if let error = scanner.error {
                Text(error)
                    .foregroundColor(.red)
            }
            if scanner.folders.isEmpty {
                Button(action: { showPickerTrigger = true }) {
                    Label("Select Folder", systemImage: "folder")
                        .font(.title2)
                        .padding(8)
                }
            } else {
                PieChartSection(folders: scanner.folders)
                    .frame(height: 260)
                BarChartView(folders: scanner.folders)
                    .frame(height: 300)
                Button("Reselect Folder") {
                    showPickerTrigger = true
                }
                .padding(.top)
            }
            // Hidden FolderPicker view, triggers when showPickerTrigger is true
            if showPickerTrigger {
                FolderPicker { url in
                    folderURL = url
                    if let url = url {
                        scanner.scanDirectory(at: url)
                    }
                    showPickerTrigger = false
                }
                .frame(width: 0, height: 0)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct PieChartSection: View {
    let folders: [FolderInfo]
    var body: some View {
        let total = folders.map { Double($0.size) }.reduce(0, +)
        let slices = makeSlices(folders: folders, total: total)
        PieChartView(slices: slices, total: total)
            .padding()
    }
    func makeSlices(folders: [FolderInfo], total: Double) -> [PieSlice] {
        var slices: [PieSlice] = []
        var start: Double = 0
        let colors: [Color] = [.pink, .orange, .green, .blue, .purple, .yellow, .mint, .teal]
        for (i, folder) in folders.enumerated() {
            let value = Double(folder.size)
            let angle = value / total * 360
            let slice = PieSlice(
                startAngle: .degrees(start),
                endAngle: .degrees(start + angle),
                color: colors[i % colors.count],
                label: folder.name,
                value: value
            )
            slices.append(slice)
            start += angle
        }
        return slices
    }
}

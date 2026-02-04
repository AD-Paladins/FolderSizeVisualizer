import SwiftUI

struct BarChartView: View {
    let folders: [FolderInfo]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Folder Sizes")
                .font(.headline)
                .padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(folders) { folder in
                        HStack(alignment: .center, spacing: 8) {
                            Text(folder.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 120, alignment: .leading)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color(for: folder.category))
                                .frame(width: barWidth(for: folder), height: 28)
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                            Text(formatSize(folder.size))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(gradient: Gradient(colors: [.secondary, .accentColor.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                .shadow(radius: 8)
        )
    }

    func barWidth(for folder: FolderInfo) -> CGFloat {
        let max = folders.map { $0.size }.max() ?? 1
        return CGFloat(folder.size) / CGFloat(max) * 250 + 24 // min width for visibility
    }

    func color(for category: SizeCategory) -> Color {
        switch category {
        case .large: return .pink
        case .medium: return .orange
        case .small: return .green
        }
    }

    func formatSize(_ size: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(size)
        var unit = 0
        while value > 1024 && unit < units.count - 1 {
            value /= 1024
            unit += 1
        }
        return String(format: "%.1f%@", value, units[unit])
    }
}

import SwiftUI

struct PieSlice: Identifiable {
    let id = UUID()
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let label: String
    let value: Double
}

struct PieChartView: View {
    let slices: [PieSlice]
    let total: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(slices) { slice in
                    PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle)
                        .fill(slice.color)
                        .overlay(
                            PieSliceShape(startAngle: slice.startAngle, endAngle: slice.endAngle)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                VStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(formatSize(total))
                        .font(.title)
                        .bold()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    func formatSize(_ size: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = size
        var unit = 0
        while value > 1024 && unit < units.count - 1 {
            value /= 1024
            unit += 1
        }
        return String(format: "%.1f%@", value, units[unit])
    }
}

struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview {
    let values: [(label: String, value: Double, color: Color)] = [
        ("Photos", 400, .blue),
        ("Apps", 300, .green),
        ("System", 200, .orange),
        ("Other", 100, .purple)
    ]
    let total = values.map { $0.value }.reduce(0, +)
    var start: Double = 0
    let slices: [PieSlice] = values.map { item in
        let end = start + (item.value / total) * 360
        let slice = PieSlice(
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            color: item.color,
            label: item.label,
            value: item.value
        )
        start = end
        return slice
    }
    return PieChartView(slices: slices, total: total)
}

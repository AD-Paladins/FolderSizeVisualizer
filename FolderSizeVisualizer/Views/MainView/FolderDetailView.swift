//
//  FolderDetailView.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: FolderEntry
    let totalSize: Int64
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue.gradient)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(folder.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(folder.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                }
                
                // Size Overview Card
                GroupBox {
                    VStack(spacing: 16) {
                        HStack {
                            Label("Total Size", systemImage: "internaldrive")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formattedSize)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Percentage of scan")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(percentageText)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.quaternary)
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(percentageGradient)
                                        .frame(width: geometry.size.width * percentage, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(4)
                }
                
                // Statistics Grid
                GroupBox("Statistics") {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            icon: "doc.fill",
                            label: "Size",
                            value: formattedSize,
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "chart.pie.fill",
                            label: "Share",
                            value: percentageText,
                            color: .purple
                        )
                        
                        StatCard(
                            icon: "number",
                            label: "Bytes",
                            value: bytesText,
                            color: .green
                        )
                        
                        StatCard(
                            icon: "scale.3d",
                            label: "Relative",
                            value: relativeSize,
                            color: .orange
                        )
                    }
                    .padding(4)
                }
                
                // Quick Actions
                GroupBox("Quick Actions") {
                    VStack(spacing: 12) {
                        Button {
                            NSWorkspace.shared.open(folder.url)
                        } label: {
                            HStack {
                                Label("Open in Finder", systemImage: "folder.badge.gearshape")
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([folder.url])
                        } label: {
                            HStack {
                                Label("Reveal in Finder", systemImage: "eye")
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                        
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(folder.url.path, forType: .string)
                        } label: {
                            HStack {
                                Label("Copy Path", systemImage: "doc.on.doc")
                                Spacer()
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(4)
                }
                
                // Information Section
                GroupBox("Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Full Path", value: folder.url.path)
                        Divider()
                        InfoRow(label: "Parent Directory", value: folder.url.deletingLastPathComponent().path)
                        Divider()
                        InfoRow(label: "Folder Name", value: folder.name)
                    }
                    .padding(4)
                }
                
                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - Computed Properties
    
    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: folder.size, countStyle: .file)
    }
    
    private var percentage: Double {
        guard totalSize > 0 else { return 0 }
        return Double(folder.size) / Double(totalSize)
    }
    
    private var percentageText: String {
        String(format: "%.2f%%", percentage * 100)
    }
    
    private var bytesText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: folder.size)) ?? "\(folder.size)"
    }
    
    private var relativeSize: String {
        let ratio = percentage
        switch ratio {
        case 0..<0.01: return "Tiny"
        case 0.01..<0.05: return "Small"
        case 0.05..<0.15: return "Medium"
        case 0.15..<0.30: return "Large"
        case 0.30..<0.50: return "Very Large"
        default: return "Massive"
        }
    }
    
    private var percentageGradient: LinearGradient {
        let ratio = percentage
        let color: Color = ratio < 0.1 ? .green : ratio < 0.3 ? .orange : .red
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color.gradient)
                    .font(.title3)
                Spacer()
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview {
    FolderDetailView(
        folder: FolderEntry(
            url: URL(fileURLWithPath: "/Library"),
            size: 1_500_000_000
        ),
        totalSize: 10_000_000_000
    )
    .frame(width: 400, height: 600)
}

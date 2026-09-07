//
//  HomebrewReportView.swift
//  FolderSizeVisualizer
//
//  View showing the full list of Homebrew dependencies (formulas + casks).
//

import SwiftUI

struct HomebrewReportView: View {
    @Bindable var viewModel: ArtifactScanViewModel

    private var report: HomebrewDependencyReport? { viewModel.homebrewReport }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header + generate button
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "mug.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Homebrew Dependencies")
                                .font(.largeTitle)
                                .bold()
                            if let report {
                                Text("\(report.total) dependencies \(report.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            viewModel.generateHomebrewReport()
                        } label: {
                            Label(isGenerating ? "Generating…" : "Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isGenerating)
                    }
                }
                .padding()

                if isGenerating {
                    ProgressView("Querying Homebrew…")
                        .padding(.vertical)
                } else if report == nil {
                    ContentUnavailableView(
                        "No Report Available",
                        systemImage: "magnifyingglass",
                        description: Text("Generate a report to list all Homebrew dependencies installed on this Mac.")
                    )
                } else {
                    reportSection(title: "Formulas", systemImage: "cube.fill", count: report!.formulas.count, items: report!.formulaNames)
                    Divider()
                    reportSection(title: "Casks", systemImage: "app.fill", count: report!.casks.count, items: report!.caskNames)
                }
            }
            .padding()
        }
        .navigationTitle("Homebrew")
    }

    private var isGenerating: Bool { viewModel.isGeneratingHomebrewReport }

    private func reportSection(title: String, systemImage: String, count: Int, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("\(title) (\(count))", systemImage: systemImage)
                .font(.headline)

            if items.isEmpty {
                Text("None installed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 8) {
                    ForEach(items, id: \.self) { name in
                        Text(name)
                            .font(.subheadline)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomebrewReportView(viewModel: ArtifactScanViewModel())
    }
}

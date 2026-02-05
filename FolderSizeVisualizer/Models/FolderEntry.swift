//
//  FolderEntry.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/4/26.
//

import Foundation

struct FolderEntry: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64

    var name: String {
        url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
    }
}

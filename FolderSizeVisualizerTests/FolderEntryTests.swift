//
//  FolderEntryTests.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 2/6/26.
//

import Foundation
import Testing

@testable import FolderSizeVisualizer

@Suite("FolderEntry Unit Tests")
struct FolderEntryTests {
    @Test("FolderEntry name uses lastPathComponent when available")
    @MainActor
    func folderEntryNameUsesLastPathComponent() {
        let url = URL(fileURLWithPath: "/Users/test/Documents")
        let entry = FolderEntry(url: url, size: 0)
        #expect(entry.name == "Documents")
    }
    
    @Test("FolderEntry name falls back to full path when lastPathComponent is empty (root)")
    @MainActor
    func folderEntryNameFallsBackToPathForRoot() {
        let rootURL = URL(fileURLWithPath: "/")
        let entry = FolderEntry(url: rootURL, size: 0)
        // For root, lastPathComponent is "/" on macOS, so `name` should be "/".
        #expect(entry.name == "/")
    }
    
    @Test("FolderEntry is identifiable with unique ID")
    @MainActor
    func folderEntryIsIdentifiable() {
        let url1 = URL(fileURLWithPath: "/test/folder1")
        let url2 = URL(fileURLWithPath: "/test/folder2")
        
        let entry1 = FolderEntry(url: url1, size: 1024)
        let entry2 = FolderEntry(url: url1, size: 1024)

        // Different instances should have different IDs even with same data
        #expect(entry1.id != entry2.id)
    }

    @Test("FolderEntry is hashable")
    @MainActor
    func folderEntryIsHashable() {
        let url1 = URL(fileURLWithPath: "/test/folder1")
        let entry1 = FolderEntry(url: url1, size: 1024)
        let entry2 = FolderEntry(url: url1, size: 1024)

        // Can be added to sets
        let set = Set([entry1, entry2])
        // Different IDs means different entries in set
        #expect(set.count == 2)
    }
}

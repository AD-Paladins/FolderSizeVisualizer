//
//  String+Extensions.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 6/6/26.
//

import Foundation

extension String {
    func markdownToAttributed() -> AttributedString {
        do {
            return try AttributedString(markdown: self)
        } catch {
            return AttributedString(self)
        }
    }
}

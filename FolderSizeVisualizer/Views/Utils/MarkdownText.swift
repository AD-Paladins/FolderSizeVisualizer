//
//  MarkdownText.swift
//  FolderSizeVisualizer
//
//  Created by andres paladines on 6/6/26.
//

import SwiftUI

struct MarkdownText: View {
    let markdownString: String
    let lineLimit: Int
    init(markdownString: String,lineLimit: Int = 0) {
        self.markdownString = markdownString
        self.lineLimit = lineLimit
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(splitString, id: \.self) { line in
                Text(line.markdownToAttributed())
            }
        }
    }
    
    var splitString: [String] {
        let array = markdownString.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let positiveLineLimit = abs(lineLimit)
        if positiveLineLimit != 0, array.count > positiveLineLimit {
            var truncated = Array(array.prefix(positiveLineLimit))
            truncated[positiveLineLimit - 1] += " ..." // Append ellipsis to last line
            return truncated
        }
        return array
    }
}

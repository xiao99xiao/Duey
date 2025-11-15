//
//  RichTextEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI
import SwiftData

struct RichTextEditorView: View {
    @Bindable var task: Task
    @State private var editingText: AttributedString = AttributedString("")
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RichTextEditor(text: $editingText)
                .padding(12)
                .onAppear {
                    if !hasLoaded {
                        // Load from model when view appears
                        if let content = task.content {
                            editingText = AttributedString(content)
                        } else {
                            editingText = AttributedString("")
                        }
                        hasLoaded = true
                    }
                }
                .onChange(of: editingText) { oldValue, newValue in
                    // Save to model on every change
                    // Convert AttributedString to plain String for storage
                    task.content = String(newValue.characters)
                }
        }
    }
}

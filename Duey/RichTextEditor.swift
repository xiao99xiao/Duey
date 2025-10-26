//
//  RichTextEditor.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI

struct RichTextEditor: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @Environment(\.fontResolutionContext) var fontResolutionContext

    var body: some View {
        VStack(spacing: 0) {
            // Text Editor
            TextEditor(text: $text, selection: $selection)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)

            // Formatting Toolbar (appears when text is selected)
            if hasSelection {
                formattingToolbar
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: hasSelection)
    }

    // MARK: - Selection State

    private var hasSelection: Bool {
        guard case .ranges(let ranges) = selection.indices(in: text) else {
            return false
        }
        return !ranges.isEmpty
    }

    private var formattingToolbar: some View {
        HStack(spacing: 12) {
            // Bold
            Button(action: toggleBold) {
                Image(systemName: "bold")
                    .font(.system(size: 14, weight: isBold ? .bold : .regular))
                    .foregroundStyle(isBold ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Bold (⌘B)")

            Divider()
                .frame(height: 16)

            // Italic
            Button(action: toggleItalic) {
                Image(systemName: "italic")
                    .font(.system(size: 14, weight: isItalic ? .bold : .regular))
                    .foregroundStyle(isItalic ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Italic (⌘I)")

            Divider()
                .frame(height: 16)

            // Underline
            Button(action: toggleUnderline) {
                Image(systemName: "underline")
                    .font(.system(size: 14, weight: hasUnderline ? .bold : .regular))
                    .foregroundStyle(hasUnderline ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Underline (⌘U)")

            Divider()
                .frame(height: 16)

            // Strikethrough
            Button(action: toggleStrikethrough) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 14, weight: hasStrikethrough ? .bold : .regular))
                    .foregroundStyle(hasStrikethrough ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Strikethrough")

            Divider()
                .frame(height: 16)

            // Bulleted List
            Button(action: insertBulletPoint) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Bullet List")

            // Numbered List
            Button(action: insertNumberedPoint) {
                Image(systemName: "list.number")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Numbered List")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Formatting State

    private var isBold: Bool {
        let attributes = selection.typingAttributes(in: text)
        let currentFont = attributes.font ?? .default
        let resolved = currentFont.resolve(in: fontResolutionContext)
        return resolved.isBold
    }

    private var isItalic: Bool {
        let attributes = selection.typingAttributes(in: text)
        let currentFont = attributes.font ?? .default
        let resolved = currentFont.resolve(in: fontResolutionContext)
        return resolved.isItalic
    }

    private var hasUnderline: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.underlineStyle != nil
    }

    private var hasStrikethrough: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.strikethroughStyle != nil
    }

    // MARK: - Formatting Actions

    private func toggleBold() {
        text.transformAttributes(in: &selection) { container in
            let currentFont = container.font ?? .default
            let resolved = currentFont.resolve(in: fontResolutionContext)
            container.font = currentFont.bold(!resolved.isBold)
        }
    }

    private func toggleItalic() {
        text.transformAttributes(in: &selection) { container in
            let currentFont = container.font ?? .default
            let resolved = currentFont.resolve(in: fontResolutionContext)
            container.font = currentFont.italic(!resolved.isItalic)
        }
    }

    private func toggleUnderline() {
        text.transformAttributes(in: &selection) { container in
            if container.underlineStyle != nil {
                container.underlineStyle = nil
            } else {
                container.underlineStyle = .single
            }
        }
    }

    private func toggleStrikethrough() {
        text.transformAttributes(in: &selection) { container in
            if container.strikethroughStyle != nil {
                container.strikethroughStyle = nil
            } else {
                container.strikethroughStyle = .single
            }
        }
    }

    private func insertBulletPoint() {
        // Get the insertion point or first range
        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert bullet at cursor position
            var bullet = AttributedString("• ")
            let typingAttrs = selection.typingAttributes(in: text)
            bullet.setAttributes(typingAttrs)
            text.insert(bullet, at: point)

        case .ranges(let rangeSet):
            // Insert bullet at the start of the first range
            for range in rangeSet.ranges {
                var bullet = AttributedString("• ")
                let typingAttrs = selection.typingAttributes(in: text)
                bullet.setAttributes(typingAttrs)
                text.insert(bullet, at: range.lowerBound)
                break // Only insert at the first range
            }
        }
    }

    private func insertNumberedPoint() {
        // Get the insertion point or first range
        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert numbered point at cursor position
            var number = AttributedString("1. ")
            let typingAttrs = selection.typingAttributes(in: text)
            number.setAttributes(typingAttrs)
            text.insert(number, at: point)

        case .ranges(let rangeSet):
            // Insert numbered point at the start of the first range
            for range in rangeSet.ranges {
                var number = AttributedString("1. ")
                let typingAttrs = selection.typingAttributes(in: text)
                number.setAttributes(typingAttrs)
                text.insert(number, at: range.lowerBound)
                break // Only insert at the first range
            }
        }
    }
}

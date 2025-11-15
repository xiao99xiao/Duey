//
//  RichTextEditor.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI
internal import AppKit

struct RichTextEditor: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @Environment(\.fontResolutionContext) var fontResolutionContext
    @State private var showLinkPopover = false
    @State private var linkURL = ""
    @State private var linkText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            // Native Text Editor with built-in auto-list conversion
            NativeTextView(text: $text)
                .safeAreaInset(edge: .bottom) {
                    // Reserve space for floating toolbar when visible
                    if hasSelection {
                        Color.clear.frame(height: 70)
                    }
                }

            // Formatting Toolbar (appears when text is selected)
            if hasSelection {
                formattingToolbar
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 12)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 10).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                            removal: .offset(y: 8).combined(with: .opacity).combined(with: .scale(scale: 0.98))
                        )
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSelection)
        .onAppear {
            // Set up keyboard shortcut for link insertion
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Check for Command+K
                if event.keyCode == 40 && event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.option) {
                    if hasSelection {
                        prepareLink()
                        showLinkPopover = true
                        return nil // Event handled
                    }
                }
                return event
            }
        }
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

            Divider()
                .frame(height: 16)

            // Link
            Button(action: {
                prepareLink()
                showLinkPopover = true
            }) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: hasLink ? .bold : .regular))
                    .foregroundStyle(hasLink ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Insert Link (⌘K)")
            .popover(isPresented: $showLinkPopover) {
                linkPopoverContent
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var linkPopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insert Link")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Text:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Link text", text: $linkText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://example.com", text: $linkURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }

            HStack {
                Button("Cancel") {
                    showLinkPopover = false
                    linkURL = ""
                    linkText = ""
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Insert") {
                    insertLink()
                }
                .keyboardShortcut(.return)
                .disabled(linkURL.isEmpty)
            }
        }
        .padding()
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

    private var hasLink: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.link != nil
    }

    // MARK: - Formatting Actions

    private func prepareLink() {
        // Pre-fill link text with selected text
        if case .ranges(let ranges) = selection.indices(in: text), !ranges.isEmpty {
            for range in ranges.ranges {
                linkText = String(text[range].characters)
                // Check if selection already has a link
                if let existingLink = text[range].runs.first?.link {
                    linkURL = existingLink.absoluteString
                }
                break
            }
        }
    }

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

    private func insertLink() {
        guard let url = URL(string: linkURL) else { return }

        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert new link with provided text
            let displayText = linkText.isEmpty ? linkURL : linkText
            var linkString = AttributedString(displayText)
            let typingAttrs = selection.typingAttributes(in: text)
            linkString.setAttributes(typingAttrs)
            linkString.link = url
            text.insert(linkString, at: point)

        case .ranges(let rangeSet):
            // Apply link to selected text
            for range in rangeSet.ranges {
                text[range].link = url
                // If link text was provided, replace the selected text
                if !linkText.isEmpty {
                    var linkString = AttributedString(linkText)
                    let existingAttrs = text[range].runs.first?.attributes ?? AttributeContainer()
                    linkString.setAttributes(existingAttrs)
                    linkString.link = url
                    text.replaceSubrange(range, with: linkString)
                }
                break // Only apply to first range
            }
        }

        // Reset state
        showLinkPopover = false
        linkURL = ""
        linkText = ""
    }
}

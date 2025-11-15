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
    @StateObject private var textViewRef = TextViewRef()
    @Environment(\.fontResolutionContext) var fontResolutionContext
    @State private var showLinkPopover = false
    @State private var linkURL = ""
    @State private var linkText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            // Native Text Editor with built-in auto-list conversion
            NativeTextView(text: $text, textViewRef: textViewRef)
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
        textViewRef.hasSelection
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
        guard let textView = textViewRef.textView,
              let font = textView.typingAttributes[.font] as? NSFont else {
            return false
        }
        return font.fontDescriptor.symbolicTraits.contains(.bold)
    }

    private var isItalic: Bool {
        guard let textView = textViewRef.textView,
              let font = textView.typingAttributes[.font] as? NSFont else {
            return false
        }
        return font.fontDescriptor.symbolicTraits.contains(.italic)
    }

    private var hasUnderline: Bool {
        guard let textView = textViewRef.textView else { return false }
        return textView.typingAttributes[.underlineStyle] != nil
    }

    private var hasStrikethrough: Bool {
        guard let textView = textViewRef.textView else { return false }
        return textView.typingAttributes[.strikethroughStyle] != nil
    }

    private var hasLink: Bool {
        guard let textView = textViewRef.textView else { return false }
        return textView.typingAttributes[.link] != nil
    }

    // MARK: - Formatting Actions

    private func prepareLink() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        // Pre-fill link text with selected text
        linkText = (textStorage.string as NSString).substring(with: range)

        // Check if selection already has a link
        if let existingLink = textStorage.attribute(.link, at: range.location, effectiveRange: nil) as? URL {
            linkURL = existingLink.absoluteString
        }
    }

    private func toggleBold() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

            // Get current traits and toggle bold
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.bold) {
                traits.remove(.bold)
            } else {
                traits.insert(.bold)
            }

            // Create new font descriptor with updated traits, preserving size
            guard let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits),
                  let newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) else {
                return
            }

            textStorage.addAttribute(.font, value: newFont, range: subrange)
        }
        textStorage.endEditing()
    }

    private func toggleItalic() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

            // Get current traits and toggle italic
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.italic) {
                traits.remove(.italic)
            } else {
                traits.insert(.italic)
            }

            // Create new font descriptor with updated traits, preserving size
            guard let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits),
                  let newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) else {
                return
            }

            textStorage.addAttribute(.font, value: newFont, range: subrange)
        }
        textStorage.endEditing()
    }

    private func toggleUnderline() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textStorage.beginEditing()
        let hasUnderline = textStorage.attribute(.underlineStyle, at: range.location, effectiveRange: nil) != nil

        if hasUnderline {
            textStorage.removeAttribute(.underlineStyle, range: range)
        } else {
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        textStorage.endEditing()
    }

    private func toggleStrikethrough() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        textStorage.beginEditing()
        let hasStrikethrough = textStorage.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) != nil

        if hasStrikethrough {
            textStorage.removeAttribute(.strikethroughStyle, range: range)
        } else {
            textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        textStorage.endEditing()
    }

    private func insertBulletPoint() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        let bullet = NSAttributedString(string: "• ", attributes: textView.typingAttributes)

        textStorage.beginEditing()
        textStorage.insert(bullet, at: range.location)
        textStorage.endEditing()

        textView.setSelectedRange(NSRange(location: range.location + bullet.length, length: 0))
    }

    private func insertNumberedPoint() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        let number = NSAttributedString(string: "1. ", attributes: textView.typingAttributes)

        textStorage.beginEditing()
        textStorage.insert(number, at: range.location)
        textStorage.endEditing()

        textView.setSelectedRange(NSRange(location: range.location + number.length, length: 0))
    }

    private func insertLink() {
        guard let url = URL(string: linkURL),
              let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()

        textStorage.beginEditing()
        if range.length == 0 {
            // Insert new link with provided text
            let displayText = linkText.isEmpty ? linkURL : linkText
            var attrs = textView.typingAttributes
            attrs[.link] = url
            let linkString = NSAttributedString(string: displayText, attributes: attrs)

            textStorage.insert(linkString, at: range.location)
        } else {
            // Apply link to selected text
            textStorage.addAttribute(.link, value: url, range: range)

            // If link text was provided, replace the selected text
            if !linkText.isEmpty {
                let existingAttrs = textStorage.attributes(at: range.location, effectiveRange: nil)
                var attrs = existingAttrs
                attrs[.link] = url
                let linkString = NSAttributedString(string: linkText, attributes: attrs)
                textStorage.replaceCharacters(in: range, with: linkString)
            }
        }
        textStorage.endEditing()

        // Reset state
        showLinkPopover = false
        linkURL = ""
        linkText = ""
    }
}

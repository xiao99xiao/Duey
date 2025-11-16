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
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Native Text Editor with built-in auto-list conversion
                // ID prevents SwiftUI from recreating the view when toolbar animates
                NativeTextView(text: $text, textViewRef: textViewRef)
                    .id("text-editor")

                // Formatting Toolbar (appears when text is selected, positioned above or below selection)
                if hasSelection, textViewRef.selectionRect != .zero {
                    let toolbarHeight: CGFloat = 50
                    let spaceAbove = textViewRef.selectionRect.minY

                    // Position above if there's enough space, otherwise below
                    let shouldPositionAbove = spaceAbove >= toolbarHeight + 10
                    let yPosition = shouldPositionAbove
                        ? textViewRef.selectionRect.minY - 40
                        : textViewRef.selectionRect.maxY + 40

                    formattingToolbar
                        .padding(8)
                        .background(.regularMaterial)
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .fixedSize()
                        .position(
                            x: min(max(textViewRef.selectionRect.midX, 150), geometry.size.width - 150),
                            y: yPosition
                        )
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            )
                        )
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSelection)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: textViewRef.selectionRect)
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

            // Checkbox
            Button(action: insertCheckbox) {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Checkbox (⌘⇧L)")

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
            Text("Edit Link")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Text:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Link text", text: $linkText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        updateLink()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://example.com", text: $linkURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        updateLink()
                    }
            }

            Text("Leave URL empty to remove link")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") {
                    showLinkPopover = false
                    linkURL = ""
                    linkText = ""
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Update") {
                    updateLink()
                }
                .keyboardShortcut(.return)
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

        // Check current bold state at start of selection
        let isBold: Bool
        if let font = textStorage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
        } else {
            isBold = false
        }

        textStorage.beginEditing()

        if isBold {
            // Remove bold by converting each font
            textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                guard let currentFont = value as? NSFont else { return }
                let fontManager = NSFontManager.shared
                let newFont = fontManager.convert(currentFont, toNotHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: newFont, range: subrange)
            }
        } else {
            // Add bold using applyFontTraits
            textStorage.applyFontTraits(.boldFontMask, range: range)
        }

        textStorage.endEditing()
    }

    private func toggleItalic() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else { return }

        // Check current italic state at start of selection
        let isItalic: Bool
        if let font = textStorage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
        } else {
            isItalic = false
        }

        textStorage.beginEditing()

        if isItalic {
            // Remove italic by converting each font
            textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                guard let currentFont = value as? NSFont else { return }
                let fontManager = NSFontManager.shared
                let newFont = fontManager.convert(currentFont, toNotHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: newFont, range: subrange)
            }
        } else {
            // Add italic using applyFontTraits
            textStorage.applyFontTraits(.italicFontMask, range: range)
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

    private func insertCheckbox() {
        guard let textView = textViewRef.textView as? DueyTextView else { return }
        textView.insertCheckbox()
    }

    private func updateLink() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else { return }

        let range = textView.selectedRange()
        guard range.length > 0 else {
            // No selection, close popover
            showLinkPopover = false
            linkURL = ""
            linkText = ""
            return
        }

        textStorage.beginEditing()

        if linkURL.isEmpty {
            // Empty URL = remove link
            textStorage.removeAttribute(.link, range: range)
        } else if let url = URL(string: linkURL) {
            // Valid URL = add/update link
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

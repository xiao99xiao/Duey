//
//  NativeTextView.swift
//  Duey
//
//  NSViewRepresentable wrapper for DueyTextView
//

import SwiftUI
internal import AppKit

/// SwiftUI wrapper for DueyTextView with bidirectional text synchronization
struct NativeTextView: NSViewRepresentable {
    @Binding var text: AttributedString

    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Replace the default NSTextView with our custom DueyTextView
        if let defaultTextView = scrollView.documentView as? NSTextView {
            let textView = DueyTextView(frame: defaultTextView.frame)

            // Configure text view
            textView.isRichText = true
            textView.allowsUndo = true
            textView.font = .systemFont(ofSize: NSFont.systemFontSize)
            textView.textColor = .textColor
            textView.backgroundColor = .clear
            textView.drawsBackground = false
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false

            // Set text container properties
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.heightTracksTextView = false
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]

            // Set delegate
            textView.delegate = context.coordinator

            // Replace in scroll view
            scrollView.documentView = textView

            // Set initial text
            if let nsAttributedString = try? NSAttributedString(text, including: \.appKit) {
                textView.textStorage?.setAttributedString(nsAttributedString)
            }

            // Store reference in coordinator
            context.coordinator.textView = textView
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? DueyTextView else { return }

        // CRITICAL: Don't update NSTextView while user is editing
        // This prevents destroying formatting and breaking Return key
        guard !context.coordinator.isEditingText else { return }

        // Only update if text actually changed (external change, like loading a task)
        let currentAttributedString = textView.attributedString()
        if let newNSAttributedString = try? NSAttributedString(text, including: \.appKit),
           !currentAttributedString.isEqual(to: newNSAttributedString) {

            // Preserve current selection
            let savedRange = textView.selectedRange()

            // Update text
            textView.textStorage?.setAttributedString(newNSAttributedString)

            // Restore selection if valid
            if savedRange.location + savedRange.length <= textView.string.count {
                textView.setSelectedRange(savedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: AttributedString
        weak var textView: DueyTextView?

        // Track if user is actively editing (prevents updateNSView from interfering)
        var isEditingText = false

        init(text: Binding<AttributedString>) {
            self._text = text
            super.init()
        }

        // MARK: - Text Change Handling

        func textDidBeginEditing(_ notification: Notification) {
            isEditingText = true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Convert NSAttributedString to AttributedString
            let nsAttributedString = textView.attributedString()
            if let attributedString = try? AttributedString(nsAttributedString, including: \.appKit) {

                // Only update binding if text actually changed
                if attributedString != text {
                    text = attributedString
                }
            }
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditingText = false
        }
    }
}

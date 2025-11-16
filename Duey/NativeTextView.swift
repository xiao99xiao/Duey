//
//  NativeTextView.swift
//  Duey
//
//  NSViewRepresentable wrapper for DueyTextView
//

import SwiftUI
internal import AppKit
import Combine

/// Observable object that holds reference to NSTextView for formatting toolbar access
class TextViewRef: ObservableObject {
    weak var textView: NSTextView?
    @Published var hasSelection = false
    @Published var selectionRect: CGRect = .zero
}

// MARK: - NSAttributedString Extension

extension NSAttributedString {
    /// Checks if the attributed string contains attachments of a specific type
    func containsAttachments<T: NSTextAttachment>(ofType type: T.Type) -> Bool {
        var found = false
        enumerateAttribute(.attachment, in: NSRange(location: 0, length: length)) { value, range, stop in
            if value is T {
                found = true
                stop.pointee = true
            }
        }
        return found
    }
}

/// SwiftUI wrapper for DueyTextView with bidirectional text synchronization
struct NativeTextView: NSViewRepresentable {
    @Binding var text: AttributedString
    let textViewRef: TextViewRef

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
            textView.textColor = .labelColor  // Use labelColor for better dark mode support
            textView.backgroundColor = .clear
            textView.drawsBackground = false
            textView.usesAdaptiveColorMappingForDarkAppearance = true  // Enable adaptive colors
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

            // Store reference in coordinator and expose to SwiftUI
            context.coordinator.textView = textView
            textViewRef.textView = textView
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? DueyTextView else { return }

        // CRITICAL: Don't update NSTextView while user is editing
        // This prevents destroying formatting and breaking Return key
        guard !context.coordinator.isEditingText else { return }

        // Check if current text has CheckboxAttachments
        let currentAttributedString = textView.attributedString()
        let hasCheckboxes = currentAttributedString.containsAttachments(ofType: CheckboxAttachment.self)

        // CRITICAL: Don't replace text if it contains CheckboxAttachments
        // The AttributedString → NSAttributedString conversion loses custom attachment subclasses
        if hasCheckboxes {
            return
        }

        // Only update if text actually changed (external change, like loading a task)
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
        Coordinator(text: $text, textViewRef: textViewRef)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: AttributedString
        weak var textView: DueyTextView?
        let textViewRef: TextViewRef

        // Track if user is actively editing (prevents updateNSView from interfering)
        var isEditingText = false

        init(text: Binding<AttributedString>, textViewRef: TextViewRef) {
            self._text = text
            self.textViewRef = textViewRef
            super.init()

            // Listen for checkbox state changes to trigger auto-save
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(checkboxStateDidChange(_:)),
                name: .checkboxStateDidChange,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func checkboxStateDidChange(_ notification: Notification) {
            // When checkbox state changes, manually trigger text update
            guard let textView = textView else { return }

            // Force update the binding by reading current text
            let nsAttributedString = textView.attributedString()
            if let attributedString = try? AttributedString(nsAttributedString, including: \.appKit) {
                text = attributedString
            }
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

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let selectedRange = textView.selectedRange()
            let hasSelection = selectedRange.length > 0

            // Calculate selection rect if there's a selection
            var selectionRect = CGRect.zero
            if hasSelection,
               let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {

                // Convert character range to glyph range
                let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)

                // Get bounding rect for the glyph range
                var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

                // Add text container origin
                let containerOrigin = textView.textContainerOrigin
                rect.origin.x += containerOrigin.x
                rect.origin.y += containerOrigin.y

                // Convert to the scroll view's coordinate system (parent of textView)
                if let scrollView = textView.enclosingScrollView {
                    rect = textView.convert(rect, to: scrollView)
                }

                selectionRect = rect
            }

            // Update published properties
            // Defer to avoid "Publishing changes from within view updates"
            DispatchQueue.main.async {
                self.textViewRef.hasSelection = hasSelection
                self.textViewRef.selectionRect = selectionRect
            }
        }
    }
}

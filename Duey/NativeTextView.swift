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
        print("🏗️ makeNSView called - creating new NSScrollView and NSTextView")

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

        print("📝 updateNSView called")
        print("   isEditingText: \(context.coordinator.isEditingText)")

        // CRITICAL: Don't update NSTextView while user is editing
        // This prevents destroying formatting and breaking Return key
        guard !context.coordinator.isEditingText else {
            print("   ⏭️ Skipping - user is editing")
            return
        }

        // Check if current text has CheckboxAttachments
        let currentAttributedString = textView.attributedString()
        let currentHasCheckboxes = currentAttributedString.containsAttachments(ofType: CheckboxAttachment.self)

        print("   hasCheckboxes in current text: \(currentHasCheckboxes)")

        // Convert AttributedString → NSAttributedString
        guard let newNSAttributedString = try? NSAttributedString(text, including: \.appKit) else {
            print("   ⏭️ Skipping - conversion failed")
            return
        }

        print("   Converted to NSAttributedString, length: \(newNSAttributedString.length)")

        // Check for attachments before restoring
        newNSAttributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: newNSAttributedString.length)) { value, range, _ in
            if let attachment = value as? NSTextAttachment {
                print("   Found attachment before restore: \(type(of: attachment))")
            }
        }

        // CRITICAL: Restore CheckboxAttachments from generic NSTextAttachments
        // AttributedString → NSAttributedString conversion loses CheckboxAttachment subclass
        let mutableNewAttrString = NSMutableAttributedString(attributedString: newNSAttributedString)
        CheckboxAttachment.restoreCheckboxes(in: mutableNewAttrString)

        // Only update if text actually changed (external change, like loading a task)
        if !currentAttributedString.isEqual(to: mutableNewAttrString) {

            print("   🔄 Updating text - content changed")

            // Preserve current selection
            let savedRange = textView.selectedRange()

            // Update text
            textView.textStorage?.setAttributedString(mutableNewAttrString)

            // Refresh checkbox cache after loading new content
            if let dueyTextView = textView as? DueyTextView {
                dueyTextView.refreshCheckboxAttachmentCache()
            }

            // Restore selection if valid
            if savedRange.location + savedRange.length <= textView.string.count {
                textView.setSelectedRange(savedRange)
            }
        } else {
            print("   ⏭️ Skipping - text unchanged")
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

            print("🔄 textDidChange called")
            print("   nsAttributedString length: \(nsAttributedString.length)")

            let hasCheckboxes = nsAttributedString.containsAttachments(ofType: CheckboxAttachment.self)
            print("   has CheckboxAttachments: \(hasCheckboxes)")

            // Convert to AttributedString
            // NOTE: This will convert CheckboxAttachment → generic NSTextAttachment
            // But the checkbox JSON data in 'contents' will be preserved through RTF
            // CheckboxAttachment.restoreCheckboxes() will restore them when loading
            if let attributedString = try? AttributedString(nsAttributedString, including: \.appKit) {
                // Only update binding if text actually changed
                if attributedString != text {
                    print("   📤 Updating text binding (this will trigger updateNSView)")
                    text = attributedString
                } else {
                    print("   ⏭️ Text unchanged, not updating binding")
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

            print("🎯 textViewDidChangeSelection")
            print("   selectedRange: \(selectedRange)")
            print("   hasSelection: \(hasSelection)")

            // CRITICAL: Refresh checkbox cache on selection changes
            // This prevents NSTextAttachmentViewProvider weak reference bug
            if let dueyTextView = textView as? DueyTextView {
                dueyTextView.refreshCheckboxAttachmentCache()
            }

            // Calculate selection rect if there's a selection
            // CRITICAL: Use TextKit 2 APIs to avoid forcing TextKit 1 fallback mode
            var selectionRect = CGRect.zero
            if hasSelection,
               let textLayoutManager = textView.textLayoutManager,
               let textContentManager = textView.textContentStorage {

                // Convert NSRange to NSTextRange for TextKit 2
                let startLocation = textContentManager.location(textContentManager.documentRange.location, offsetBy: selectedRange.location)
                let endLocation = textContentManager.location(startLocation!, offsetBy: selectedRange.length)

                if let startLocation = startLocation,
                   let endLocation = endLocation,
                   let textRange = NSTextRange(location: startLocation, end: endLocation) {

                    // Enumerate layout fragments in the selection
                    textLayoutManager.enumerateTextLayoutFragments(from: textRange.location, options: [], using: { layoutFragment in
                        // Check if fragment intersects our selection
                        let fragmentRange = layoutFragment.rangeInElement
                        if fragmentRange.location.compare(textRange.endLocation) != .orderedDescending {
                            // Get the frame for this fragment
                            selectionRect = selectionRect.union(layoutFragment.layoutFragmentFrame)
                        }

                        // Stop if we've passed the end of selection
                        return fragmentRange.endLocation.compare(textRange.endLocation) == .orderedAscending
                    })

                    // Convert to the scroll view's coordinate system
                    if let scrollView = textView.enclosingScrollView {
                        selectionRect = textView.convert(selectionRect, to: scrollView)
                    }
                }
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

//
//  RTFNativeTextView.swift
//  Duey
//
//  NSViewRepresentable wrapper for DueyTextView that works directly with RTF Data
//  This bypasses AttributedString to preserve NSTextAttachment (checkboxes)
//

import SwiftUI
internal import AppKit

/// SwiftUI wrapper for DueyTextView with direct RTF save/load
struct RTFNativeTextView: NSViewRepresentable {
    @Binding var rtfData: Data?
    let textViewRef: TextViewRef

    func makeNSView(context: Context) -> NSScrollView {
        print("🏗️ RTFNativeTextView.makeNSView")

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
            textView.textColor = .labelColor
            textView.backgroundColor = .clear
            textView.drawsBackground = false
            textView.usesAdaptiveColorMappingForDarkAppearance = true
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

            // Load initial archived content
            if let archivedData = rtfData {
                print("   Loading archived NSAttributedString: \(archivedData.count) bytes")
                if let nsAttributedString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: archivedData) {
                    print("   Loaded NSAttributedString: \(nsAttributedString.length) chars")

                    textView.textStorage?.setAttributedString(nsAttributedString)
                    textView.refreshCheckboxAttachmentCache()
                } else {
                    print("   ❌ Failed to unarchive")
                }
            }

            // Store reference in coordinator and expose to SwiftUI
            context.coordinator.textView = textView
            textViewRef.textView = textView
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? DueyTextView else { return }

        print("📝 RTFNativeTextView.updateNSView")
        print("   isEditingText: \(context.coordinator.isEditingText)")
        print("   needsReload: \(context.coordinator.needsReload)")

        // Don't update NSTextView while user is editing
        guard !context.coordinator.isEditingText else {
            print("   ⏭️ Skipping - user is editing")
            return
        }

        // Only reload if external change detected
        guard context.coordinator.needsReload else {
            print("   ⏭️ Skipping - no reload needed")
            return
        }

        // Load archived content
        if let archivedData = rtfData {
            print("   Loading archived NSAttributedString: \(archivedData.count) bytes")
            if let nsAttributedString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: archivedData) {
                print("   Loaded NSAttributedString: \(nsAttributedString.length) chars")

                // Preserve current selection
                let savedRange = textView.selectedRange()

                // Update text
                textView.textStorage?.setAttributedString(nsAttributedString)
                textView.refreshCheckboxAttachmentCache()

                // Restore selection if valid
                if savedRange.location + savedRange.length <= textView.string.count {
                    textView.setSelectedRange(savedRange)
                }

                context.coordinator.needsReload = false
            } else {
                print("   ❌ Failed to unarchive")
            }
        } else {
            print("   Clearing text (no archived data)")
            textView.textStorage?.setAttributedString(NSAttributedString())
            context.coordinator.needsReload = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rtfData: $rtfData, textViewRef: textViewRef)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var rtfData: Data?
        weak var textView: DueyTextView?
        let textViewRef: TextViewRef

        // Track if user is actively editing
        var isEditingText = false

        // Track if we need to reload from external change
        var needsReload = false

        init(rtfData: Binding<Data?>, textViewRef: TextViewRef) {
            self._rtfData = rtfData
            self.textViewRef = textViewRef
            super.init()

            // Listen for checkbox state changes
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
            // Save to archive when checkbox state changes
            saveToArchive()
        }

        // MARK: - Text Change Handling

        func textDidBeginEditing(_ notification: Notification) {
            isEditingText = true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            print("🔄 textDidChange")

            // Save to archive
            saveToArchive()
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditingText = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let selectedRange = textView.selectedRange()
            let hasSelection = selectedRange.length > 0

            // Refresh checkbox cache on selection changes
            if let dueyTextView = textView as? DueyTextView {
                dueyTextView.refreshCheckboxAttachmentCache()
            }

            // Calculate selection rect using TextKit 2 APIs
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
            DispatchQueue.main.async {
                self.textViewRef.hasSelection = hasSelection
                self.textViewRef.selectionRect = selectionRect
            }
        }

        // MARK: - Archive Save

        private func saveToArchive() {
            guard let textView = textView,
                  let textStorage = textView.textStorage else { return }

            print("💾 Archiving NSAttributedString")
            print("   Length: \(textStorage.length)")
            print("   String: '\(textStorage.string)'")

            // Check for CheckboxAttachments
            var checkboxCount = 0
            textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length)) { value, range, _ in
                if let attachment = value as? CheckboxAttachment {
                    checkboxCount += 1
                    print("   Found CheckboxAttachment at range \(range): \(attachment.id), checked: \(attachment.isChecked)")
                }
            }

            // Create NSAttributedString copy for archiving
            let attrStringToSave = NSAttributedString(attributedString: textStorage)

            // Archive using NSKeyedArchiver
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: attrStringToSave, requiringSecureCoding: false) {
                print("   ✅ Archived: \(data.count) bytes, \(checkboxCount) checkboxes")

                // Test round-trip immediately
                if let testLoad = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
                    print("   🧪 Test load: \(testLoad.length) chars, string: '\(testLoad.string)'")
                    var restoredCheckboxes = 0
                    testLoad.enumerateAttribute(.attachment, in: NSRange(location: 0, length: testLoad.length)) { value, range, _ in
                        if let attachment = value as? CheckboxAttachment {
                            restoredCheckboxes += 1
                            print("   🧪 Found CheckboxAttachment at range \(range): \(attachment.id)")
                        }
                    }
                    print("   🧪 Restored \(restoredCheckboxes) checkboxes")
                }

                rtfData = data
            } else {
                print("   ❌ Archiving failed")
                rtfData = nil
            }
        }
    }
}

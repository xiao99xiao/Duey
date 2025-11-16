//
//  RichTextEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI
import SwiftData

struct RichTextEditorView: View {
    @Bindable var task: DueyTask
    @State private var editingText: AttributedString = AttributedString("")
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RichTextEditor(text: $editingText)
                .padding(12)
                .onAppear {
                    if !hasLoaded {
                        // Load from model - convert RTF to AttributedString
                        if let rtfData = task.richContent {
                            // Convert RTF Data → NSAttributedString
                            if let nsAttrString = try? NSAttributedString(
                                data: rtfData,
                                options: [.documentType: NSAttributedString.DocumentType.rtf],
                                documentAttributes: nil
                            ) {
                                // CRITICAL: Restore CheckboxAttachments from generic NSTextAttachments
                                // RTF round-trip loses the CheckboxAttachment subclass
                                let mutableAttrString = NSMutableAttributedString(attributedString: nsAttrString)
                                CheckboxAttachment.restoreCheckboxes(in: mutableAttrString)

                                // Convert NSAttributedString → SwiftUI AttributedString
                                editingText = (try? AttributedString(mutableAttrString, including: \.appKit)) ?? AttributedString("")
                            } else {
                                editingText = AttributedString("")
                            }
                        } else {
                            editingText = AttributedString("")
                        }
                        hasLoaded = true
                    }
                }
                .onChange(of: editingText) { oldValue, newValue in
                    // Save to model - convert AttributedString to RTF
                    // Convert SwiftUI AttributedString → NSAttributedString
                    if let nsAttrString = try? NSAttributedString(newValue, including: \.appKit) {
                        // Convert NSAttributedString → RTF Data
                        let range = NSRange(location: 0, length: nsAttrString.length)
                        task.richContent = try? nsAttrString.data(
                            from: range,
                            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                        )
                    } else {
                        task.richContent = nil
                    }
                }
        }
    }
}

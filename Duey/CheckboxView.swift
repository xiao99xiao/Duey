//
//  CheckboxView.swift
//  Duey
//
//  Interactive checkbox view for text attachments
//

internal import AppKit

/// Custom NSView containing an interactive checkbox button
class CheckboxView: NSView {

    // MARK: - Properties

    private let attachment: CheckboxAttachment
    private let checkboxButton: NSButton

    // MARK: - Initialization

    init(attachment: CheckboxAttachment) {
        self.attachment = attachment

        // Create checkbox button
        self.checkboxButton = NSButton(checkboxWithTitle: "", target: nil, action: nil)

        super.init(frame: .zero)

        setupView()
        updateCheckboxState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Configure checkbox button
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        checkboxButton.target = self
        checkboxButton.action = #selector(checkboxToggled)
        checkboxButton.setButtonType(.switch)
        checkboxButton.bezelStyle = .rounded
        checkboxButton.isBordered = false
        checkboxButton.imageScaling = .scaleProportionallyDown

        addSubview(checkboxButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkboxButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            checkboxButton.topAnchor.constraint(equalTo: topAnchor),
            checkboxButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Accessibility
        checkboxButton.setAccessibilityElement(true)
        checkboxButton.setAccessibilityRole(.checkBox)
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        let stateLabel = attachment.isChecked ? "checked" : "unchecked"
        let textLabel = attachment.text.isEmpty ? "checkbox" : attachment.text

        checkboxButton.setAccessibilityLabel("\(textLabel), \(stateLabel)")
        checkboxButton.setAccessibilityValue(attachment.isChecked ? "1" : "0")
    }

    // MARK: - State Management

    private func updateCheckboxState() {
        checkboxButton.state = attachment.isChecked ? .on : .off
    }

    @objc private func checkboxToggled() {
        // Update attachment state
        attachment.isChecked = (checkboxButton.state == .on)

        // Update accessibility
        updateAccessibilityLabel()

        // Animate the change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            checkboxButton.animator().alphaValue = 0.7
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                self.checkboxButton.animator().alphaValue = 1.0
            }
        }
    }

    // MARK: - Sizing

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 20, height: 18)
    }

    override func layout() {
        super.layout()
        updateCheckboxState()
        updateAccessibilityLabel()
    }
}

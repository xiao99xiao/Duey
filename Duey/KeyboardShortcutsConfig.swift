//
//  KeyboardShortcutsConfig.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

internal import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let smartTaskCapture = Self("smartTaskCapture", default: .init(.t, modifiers: [.command, .shift]))
}

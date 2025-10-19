//
//  PasteboardAnalyzer.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import Foundation
import AppKit
import Combine

class PasteboardAnalyzer: ObservableObject {
    private let pasteboard = NSPasteboard.general

    // Callback for when clipboard text should be analyzed
    var onTextAnalyzed: ((String) -> Void)?
    // Callback for when text is filtered out
    var onTextFiltered: ((String) -> Void)?

    @MainActor
    func analyzeClipboard() {
        // Get text content from pasteboard
        guard let string = pasteboard.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onTextFiltered?("No text content in clipboard")
            return
        }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic filtering - skip very short or very long text
        guard trimmed.count >= 10 && trimmed.count <= 1000 else {
            onTextFiltered?("Text too short (\(trimmed.count) chars) or too long (max 1000)")
            return
        }

        // Skip obvious non-task content
        if isObviouslyNotTask(trimmed) {
            onTextFiltered?("Text appears to be non-task content (URL, code, etc.)")
            return
        }

        print("PasteboardAnalyzer: Analyzing clipboard text: \(String(trimmed.prefix(50)))...")
        onTextAnalyzed?(trimmed)
    }

    private func isObviouslyNotTask(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Skip URLs
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return true
        }

        // Skip email addresses (single line)
        if text.contains("@") && !text.contains("\n") && text.count < 100 {
            return true
        }

        // Skip code-like content
        if text.contains("{") && text.contains("}") {
            return true
        }

        // Skip file paths
        if lowercased.hasPrefix("/") || lowercased.contains("\\") {
            return true
        }

        // Skip potential passwords or API keys
        if isLikelyPassword(text) || isLikelyAPIKey(text) {
            return true
        }

        // Skip credit card numbers
        if isLikelyCreditCard(text) {
            return true
        }

        // Skip phone numbers (standalone)
        if isLikelyPhoneNumber(text) {
            return true
        }

        // Skip purely numeric content
        if text.trimmingCharacters(in: .whitespacesAndNewlines).rangeOfCharacter(from: .letters) == nil {
            return true
        }

        return false
    }

    private func isLikelyPassword(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Single line, no spaces, contains mix of characters
        if !trimmed.contains(" ") && !trimmed.contains("\n") {
            let hasLetter = trimmed.rangeOfCharacter(from: .letters) != nil
            let hasNumber = trimmed.rangeOfCharacter(from: .decimalDigits) != nil
            let hasSpecial = trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil

            if hasLetter && hasNumber && hasSpecial && trimmed.count >= 8 {
                return true
            }
        }

        return false
    }

    private func isLikelyAPIKey(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Common API key patterns
        let apiKeyPatterns = [
            "^sk-[a-zA-Z0-9]{20,}$", // OpenAI format
            "^[a-zA-Z0-9]{32,}$",    // Common 32+ char keys
            "^Bearer [a-zA-Z0-9_-]+$", // Bearer tokens
        ]

        for pattern in apiKeyPatterns {
            if trimmed.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }

        return false
    }

    private func isLikelyCreditCard(_ text: String) -> Bool {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return numbers.count >= 13 && numbers.count <= 19
    }

    private func isLikelyPhoneNumber(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let phonePattern = "^[+]?[(]?[0-9\\s\\-\\(\\)]{10,}$"
        return trimmed.range(of: phonePattern, options: .regularExpression) != nil && trimmed.count < 50
    }

}
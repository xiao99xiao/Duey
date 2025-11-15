//
//  SmartTaskCapture.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import Combine
import WidgetKit

@MainActor
class SmartTaskCapture: ObservableObject {
    @Published var currentSuggestion: TaskExtractionResponse?
    @Published var currentOriginalText = ""
    @Published var isProcessing = false
    @Published var lastResultMessage = ""
    @Published var showResultMessage = false
    @Published var shouldShowWindow = false

    private let pasteboardAnalyzer = PasteboardAnalyzer()
    private let extractionService = TaskExtractionService()
    private var modelContext: ModelContext?
    private var appSettings: AppSettings?

    // Computed properties that access AppSettings
    var isEnabled: Bool {
        appSettings?.smartCaptureEnabled ?? false
    }

    var apiKey: String {
        appSettings?.smartCaptureAPIKey ?? ""
    }

    var confidenceThreshold: Double {
        appSettings?.smartCaptureConfidenceThreshold ?? 0.7
    }

    var outputLanguage: String {
        appSettings?.smartCaptureOutputLanguage ?? "auto"
    }

    var useRichContent: Bool {
        appSettings?.smartCaptureUseRichContent ?? true
    }

    func configure(modelContext: ModelContext, appSettings: AppSettings) {
        self.modelContext = modelContext
        self.appSettings = appSettings
        setupPasteboardAnalyzer()

        // Configure the extraction service with current API key
        if !apiKey.isEmpty {
            extractionService.setAPIKey(apiKey)
        }

        print("SmartTaskCapture: Configured")
    }

    func analyzeClipboard() {
        guard isEnabled else {
            showMessage("Smart Task Capture is disabled")
            return
        }

        guard !apiKey.isEmpty else {
            showMessage("OpenAI API key not configured")
            return
        }

        pasteboardAnalyzer.analyzeClipboard()
    }

    func analyzeText(_ text: String) {
        guard isEnabled else {
            showMessage("Smart Task Capture is disabled")
            return
        }

        guard !apiKey.isEmpty else {
            showMessage("OpenAI API key not configured")
            return
        }

        _Concurrency.Task { @MainActor in
            await processClipboardText(text)
        }
    }

    private func showMessage(_ message: String) {
        lastResultMessage = message
        showResultMessage = true

        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showResultMessage = false
        }
    }

    private func setupPasteboardAnalyzer() {
        pasteboardAnalyzer.onTextAnalyzed = { [weak self] text in
            _Concurrency.Task { @MainActor in
                await self?.processClipboardText(text)
            }
        }

        pasteboardAnalyzer.onTextFiltered = { [weak self] reason in
            _Concurrency.Task { @MainActor in
                self?.showMessage("Filtered: \(reason)")
            }
        }
    }

    private func processClipboardText(_ text: String) async {
        guard isEnabled, !apiKey.isEmpty else { return }
        guard !isProcessing else { return } // Prevent concurrent processing

        isProcessing = true
        defer { isProcessing = false }

        do {
            print("SmartTaskCapture: Analyzing text with AI...")
            let suggestion = try await extractionService.extractTask(
                from: text,
                outputLanguage: outputLanguage,
                useRichContent: useRichContent
            )

            // Check if it meets our confidence threshold
            guard suggestion.isTask && suggestion.confidence >= confidenceThreshold else {
                let confidencePercent = Int(suggestion.confidence * 100)
                let thresholdPercent = Int(confidenceThreshold * 100)
                showMessage("Not a task (confidence: \(confidencePercent)%, threshold: \(thresholdPercent)%)")
                return
            }


            print("SmartTaskCapture: Task detected with confidence \(Int(suggestion.confidence * 100))%")
            currentSuggestion = suggestion
            currentOriginalText = text
            shouldShowWindow = true

        } catch {
            showMessage("AI Analysis failed: \(error.localizedDescription)")
            print("SmartTaskCapture: Error analyzing text: \(error.localizedDescription)")
        }
    }

    func acceptSuggestion(title: String, content: String?, deadline: Date?) {
        guard let modelContext = modelContext else {
            print("SmartTaskCapture: No model context available")
            return
        }

        let newTask = Task(title: title, content: content, deadline: deadline, isCompleted: false)
        modelContext.insert(newTask)

        do {
            try modelContext.save()
            print("SmartTaskCapture: Task created successfully: '\(title)'")
            // Reload widget after creating task
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskList")
        } catch {
            print("SmartTaskCapture: Failed to save task: \(error.localizedDescription)")
        }

        clearCurrentSuggestion()
    }

    func declineSuggestion() {
        print("SmartTaskCapture: Suggestion declined")
        clearCurrentSuggestion()
    }

    private func clearCurrentSuggestion() {
        currentSuggestion = nil
        currentOriginalText = ""
        shouldShowWindow = false
    }


}

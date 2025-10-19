//
//  SmartTaskCapture.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class SmartTaskCapture: ObservableObject {
    @Published var isEnabled = false
    @Published var showSuggestionDialog = false
    @Published var currentSuggestion: TaskExtractionResponse?
    @Published var currentOriginalText = ""
    @Published var isProcessing = false
    @Published var lastResultMessage = ""
    @Published var showResultMessage = false

    private let pasteboardAnalyzer = PasteboardAnalyzer()
    private let extractionService = TaskExtractionService()
    private var modelContext: ModelContext?

    // User preferences
    @Published var apiKey = ""
    @Published var confidenceThreshold: Double = 0.7
    @Published var outputLanguage = "auto" // "auto" or language code like "en", "zh", "ja", etc.
    @Published var useRichContent = true // Use markdown formatting

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupPasteboardAnalyzer()
        loadSettings()
    }

    func setAPIKey(_ key: String) {
        apiKey = key
        extractionService.setAPIKey(key)
        saveSettings()
        print("SmartTaskCapture: API key updated")
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

            withAnimation(.easeInOut(duration: 0.3)) {
                showSuggestionDialog = true
            }

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

        let newTask = Task(title: title, content: content, deadline: deadline)
        modelContext.insert(newTask)

        do {
            try modelContext.save()
            print("SmartTaskCapture: Task created successfully: '\(title)'")
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
        showSuggestionDialog = false
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "SmartTaskCapture.isEnabled")
        apiKey = UserDefaults.standard.string(forKey: "SmartTaskCapture.apiKey") ?? ""
        confidenceThreshold = UserDefaults.standard.double(forKey: "SmartTaskCapture.confidenceThreshold")

        if confidenceThreshold == 0 {
            confidenceThreshold = 0.7 // Default value
        }

        outputLanguage = UserDefaults.standard.string(forKey: "SmartTaskCapture.outputLanguage") ?? "auto"
        useRichContent = UserDefaults.standard.bool(forKey: "SmartTaskCapture.useRichContent")
        if UserDefaults.standard.object(forKey: "SmartTaskCapture.useRichContent") == nil {
            useRichContent = true // Default to true if not set
        }


        if !apiKey.isEmpty {
            extractionService.setAPIKey(apiKey)
        }

        print("SmartTaskCapture: Settings loaded")
    }

    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "SmartTaskCapture.isEnabled")
        UserDefaults.standard.set(apiKey, forKey: "SmartTaskCapture.apiKey")
        UserDefaults.standard.set(confidenceThreshold, forKey: "SmartTaskCapture.confidenceThreshold")
        UserDefaults.standard.set(outputLanguage, forKey: "SmartTaskCapture.outputLanguage")
        UserDefaults.standard.set(useRichContent, forKey: "SmartTaskCapture.useRichContent")


        print("SmartTaskCapture: Settings saved")
    }

}

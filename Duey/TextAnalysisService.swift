//
//  TextAnalysisService.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import Cocoa
import SwiftData

@objc class TextAnalysisService: NSObject {

    static let shared = TextAnalysisService()

    private var modelContainer: ModelContainer?
    private var appSettings: AppSettings?
    private var smartTaskCapture: SmartTaskCapture?

    private override init() {
        super.init()
    }

    func configure(modelContainer: ModelContainer, appSettings: AppSettings, smartTaskCapture: SmartTaskCapture) {
        self.modelContainer = modelContainer
        self.appSettings = appSettings
        self.smartTaskCapture = smartTaskCapture

        // Register the service
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    @objc func convertToTodoTask(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        print("TextAnalysisService: Service called")

        guard let smartTaskCapture = smartTaskCapture else {
            print("TextAnalysisService: SmartTaskCapture not configured")
            error.pointee = NSString(string: "SmartTaskCapture not configured")
            return
        }

        guard let appSettings = appSettings, appSettings.smartCaptureEnabled else {
            print("TextAnalysisService: Smart Task Capture is disabled")
            error.pointee = NSString(string: "Smart Task Capture is disabled")
            return
        }

        guard !appSettings.smartCaptureAPIKey.isEmpty else {
            print("TextAnalysisService: API key not configured")
            error.pointee = NSString(string: "OpenAI API key not configured")
            return
        }

        // Get text from pasteboard
        guard let text = pasteboard.string(forType: NSPasteboard.PasteboardType.string), !text.isEmpty else {
            print("TextAnalysisService: No text found in pasteboard")
            error.pointee = NSString(string: "No text found")
            return
        }

        print("TextAnalysisService: Processing selected text: \(text)")

        // Bring app to front and process the text
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            smartTaskCapture.analyzeText(text)
        }
    }
}

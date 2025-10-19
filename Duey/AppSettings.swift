//
//  AppSettings.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import Combine
import ServiceManagement

@MainActor
class AppSettings: ObservableObject {

    // MARK: - Smart Task Capture Settings

    @AppStorage("SmartTaskCapture.isEnabled")
    var smartCaptureEnabled = false {
        didSet {
            objectWillChange.send()
        }
    }

    @AppStorage("SmartTaskCapture.apiKey")
    var smartCaptureAPIKey = "" {
        didSet {
            objectWillChange.send()
        }
    }

    @AppStorage("SmartTaskCapture.confidenceThreshold")
    var smartCaptureConfidenceThreshold = 0.7 {
        didSet {
            objectWillChange.send()
        }
    }

    @AppStorage("SmartTaskCapture.outputLanguage")
    var smartCaptureOutputLanguage = "auto" {
        didSet {
            objectWillChange.send()
        }
    }

    @AppStorage("SmartTaskCapture.useRichContent")
    var smartCaptureUseRichContent = true {
        didSet {
            objectWillChange.send()
        }
    }


    // MARK: - General Settings

    @AppStorage("showCompletedTasks")
    var showCompletedTasks = true {
        didSet {
            objectWillChange.send()
        }
    }

    @AppStorage("startAtLogin")
    var startAtLogin = false {
        didSet {
            objectWillChange.send()
            updateStartAtLogin()
        }
    }

    @AppStorage("showMenuBarIcon")
    var showMenuBarIcon = false {
        didSet {
            objectWillChange.send()
        }
    }


    // MARK: - Login Item Management

    private func updateStartAtLogin() {
        do {
            if startAtLogin {
                // Register as login item
                try SMAppService.mainApp.register()
                print("AppSettings: Successfully registered as login item")
            } else {
                // Unregister as login item
                try SMAppService.mainApp.unregister()
                print("AppSettings: Successfully unregistered as login item")
            }
        } catch {
            print("AppSettings: Failed to update login item status: \(error.localizedDescription)")
        }
    }
}

//
//  DueyApp.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData

@main
struct DueyApp: App {
    @StateObject private var smartTaskCapture = SmartTaskCapture()
    @StateObject private var appSettings = AppSettings()
    @Environment(\.openWindow) private var openWindow

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Task.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("CloudKit ModelContainer creation failed: \(error)")
            // Fallback to local-only configuration
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(smartTaskCapture)
                .environmentObject(appSettings)
                .onReceive(smartTaskCapture.$shouldShowWindow) { shouldShow in
                    if shouldShow, smartTaskCapture.currentSuggestion != nil {
                        openWindow(id: "task-suggestion")
                    }
                }
        }
        .modelContainer(sharedModelContainer)

        WindowGroup("Task Suggestion", id: "task-suggestion") {
            if let suggestion = smartTaskCapture.currentSuggestion {
                TaskSuggestionWindow(
                    suggestion: suggestion,
                    originalText: smartTaskCapture.currentOriginalText,
                    smartTaskCapture: smartTaskCapture
                )
                .environmentObject(appSettings)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .modelContainer(sharedModelContainer)

        Settings {
            SettingsView()
        }
    }
}

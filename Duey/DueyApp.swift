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

    var body: some Scene {
        mainWindow
        
        taskSuggestionWindow
        
        menuBarExtra
        
        Settings {
            SettingsView()
        }
    }
    
    @SceneBuilder
    private var mainWindow: some Scene {
        Window("Duey", id: "main") {
            MainContentView()
                .environmentObject(smartTaskCapture)
                .environmentObject(appSettings)
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 500, idealHeight: 700)
        }
        .modelContainer(for: Task.self)
        .defaultPosition(.center)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .createNewTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // Add text formatting commands (Bold, Italic, Underline, etc.)
            TextFormattingCommands()
        }
    }
    
    @SceneBuilder
    private var taskSuggestionWindow: some Scene {
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
        .modelContainer(for: Task.self)
    }
    
    @SceneBuilder
    private var menuBarExtra: some Scene {
        MenuBarExtra("Duey", systemImage: "checklist") {
            if appSettings.showMenuBarIcon {
                MenuBarView()
                    .environmentObject(appSettings)
                    .modelContainer(for: Task.self)
            } else {
                EmptyView()
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MainContentView: View {
    @EnvironmentObject private var smartTaskCapture: SmartTaskCapture
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        ContentView()
            .onReceive(smartTaskCapture.$shouldShowWindow) { shouldShow in
                if shouldShow, smartTaskCapture.currentSuggestion != nil {
                    openWindow(id: "task-suggestion")
                }
            }
    }
}

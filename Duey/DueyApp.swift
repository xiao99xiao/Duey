//
//  DueyApp.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import CoreData

@main
struct DueyApp: App {
    @StateObject private var smartTaskCapture = SmartTaskCapture()
    @StateObject private var appSettings = AppSettings()

    // Shared model container
    @MainActor
    static let sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([Task.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])

            // Initialize CloudKit schema to sync with server
            // This ensures the deprecated 'content' field is properly registered in CloudKit
            // IMPORTANT: Run this ONCE after model changes, then comment out
            #if DEBUG
            // TODO: Uncomment the line below, run the app once, then comment it out again
            // try? initializeCloudKitSchema(for: container)
            #endif

            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // Helper to initialize CloudKit schema for SwiftData
    @MainActor
    private static func initializeCloudKitSchema(for container: ModelContainer) throws {
        // Convert SwiftData model to Core Data NSManagedObjectModel
        guard let managedObjectModel = NSManagedObjectModel.makeManagedObjectModel(for: [Task.self]) else {
            print("Failed to create NSManagedObjectModel")
            return
        }

        // Get the configuration URL
        let config = ModelConfiguration(schema: Schema([Task.self]), isStoredInMemoryOnly: false)

        // Create persistent store description
        let storeDescription = NSPersistentStoreDescription(url: config.url)

        // Configure CloudKit options with the container identifier from entitlements
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.xiao99xiao.Duey")
        storeDescription.cloudKitContainerOptions = cloudKitOptions

        // Create a temporary CloudKit container
        let cloudKitContainer = NSPersistentCloudKitContainer(name: "Duey", managedObjectModel: managedObjectModel)
        cloudKitContainer.persistentStoreDescriptions = [storeDescription]

        // Load persistent stores
        cloudKitContainer.loadPersistentStores { _, error in
            if let error = error {
                print("Error loading persistent stores: \(error)")
                return
            }
        }

        // Initialize CloudKit schema - this syncs the model with CloudKit
        try cloudKitContainer.initializeCloudKitSchema()
        print("✅ CloudKit schema initialized successfully")
    }

    var body: some Scene {
        mainWindow

        taskSuggestionWindow

        diagnosticsWindow

        menuBarExtra

        Settings {
            SettingsView()
                .modelContainer(DueyApp.sharedModelContainer)
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
        .modelContainer(DueyApp.sharedModelContainer)
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
        .modelContainer(DueyApp.sharedModelContainer)
    }

    @SceneBuilder
    private var diagnosticsWindow: some Scene {
        Window("Database Diagnostics", id: "diagnostics") {
            DiagnosticsView(modelContext: DueyApp.sharedModelContainer.mainContext)
        }
        .modelContainer(DueyApp.sharedModelContainer)
        .defaultSize(width: 700, height: 650)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Database Diagnostics...") {
                    NotificationCenter.default.post(name: .openDiagnostics, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .option])
            }
        }
    }

    @SceneBuilder
    private var menuBarExtra: some Scene {
        MenuBarExtra("Duey", systemImage: "checklist") {
            if appSettings.showMenuBarIcon {
                MenuBarView()
                    .environmentObject(appSettings)
                    .modelContainer(DueyApp.sharedModelContainer)
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
            .onReceive(NotificationCenter.default.publisher(for: .openDiagnostics)) { _ in
                openWindow(id: "diagnostics")
            }
    }
}

extension Notification.Name {
    static let openDiagnostics = Notification.Name("openDiagnostics")
}

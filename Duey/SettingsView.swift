//
//  SettingsView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import KeyboardShortcuts
import SwiftData

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            GeneralSettingsTab(appSettings: appSettings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag("general")

            SmartTaskCaptureSettingsTab(appSettings: appSettings)
                .tabItem {
                    Label("Smart Capture", systemImage: "brain.head.profile")
                }
                .tag("smart_capture")

            DiagnosticsView(modelContext: modelContext)
                .tabItem {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
                .tag("diagnostics")

            TroubleshootingTab(modelContext: modelContext)
                .tabItem {
                    Label("Troubleshooting", systemImage: "wrench.and.screwdriver")
                }
                .tag("troubleshooting")
        }
        .frame(width: 700, height: 650)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Show completed tasks", isOn: $appSettings.showCompletedTasks)
                    .help("Display completed tasks in the sidebar")
            }

            Section("Menu Bar") {
                Toggle("Show menu bar icon", isOn: $appSettings.showMenuBarIcon)
                    .help("Display Duey icon in the menu bar for quick access")

                if appSettings.showMenuBarIcon {
                    Text("Click the menu bar icon to toggle the main window")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Startup") {
                Toggle("Start Duey at login", isOn: $appSettings.startAtLogin)
                    .help("Automatically launch Duey when you log in to your Mac")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.blue)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-List Formatting")
                                .font(.headline)
                            Text("Automatic conversion while typing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Type '- ' or '* ' then space to create bullet lists", systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("Type '1. ' then space to create numbered lists", systemImage: "list.number")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("Press Enter to continue lists automatically", systemImage: "return")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Label("Press Tab to indent, Shift+Tab to outdent", systemImage: "increase.indent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Use the formatting toolbar when text is selected for additional options")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            } header: {
                Text("Rich Text Editor")
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}

struct SmartTaskCaptureSettingsTab: View {
    @ObservedObject var appSettings: AppSettings

    @State private var showingAPIKeyHelp = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(.blue)
                            .font(.title2)

                        Text("Smart Task Capture")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Text("Press \(KeyboardShortcuts.getShortcut(for: .smartTaskCapture)?.description ?? "⌘⇧T") to analyze clipboard content for potential tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Enable Feature") {
                Toggle("Enable Smart Task Capture", isOn: $appSettings.smartCaptureEnabled)
                    .onChange(of: appSettings.smartCaptureEnabled) { _, newValue in
                        if newValue && !appSettings.smartCaptureAPIKey.isEmpty {
                            // Configure the service when enabled
                            configureService()
                        }
                    }

                if appSettings.smartCaptureEnabled {
                    Label("Press \(KeyboardShortcuts.getShortcut(for: .smartTaskCapture)?.description ?? "⌘⇧T") to analyze clipboard content", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Feature is disabled", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("API Configuration") {
                HStack {
                    Text("OpenAI API Key:")

                    Button(action: { showingAPIKeyHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("How to get an API key")
                }

                SecureField("Enter your OpenAI API key", text: $appSettings.smartCaptureAPIKey)
                    .onChange(of: appSettings.smartCaptureAPIKey) { _, _ in
                        if appSettings.smartCaptureEnabled {
                            configureService()
                        }
                    }

                if appSettings.smartCaptureAPIKey.isEmpty {
                    Text("An OpenAI API key is required for AI task detection")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("API key configured ✓")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if showingAPIKeyHelp {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To get an OpenAI API key:")
                            .font(.caption)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Visit platform.openai.com")
                            Text("2. Sign up or log in to your account")
                            Text("3. Go to API Keys section")
                            Text("4. Create a new API key")
                            Text("5. Copy and paste it here")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Section("Detection Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence Threshold: \(Int(appSettings.smartCaptureConfidenceThreshold * 100))%")
                            .font(.subheadline)

                        Spacer()

                        Text(sensitivityLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $appSettings.smartCaptureConfidenceThreshold,
                        in: 0.3...0.9,
                        step: 0.1
                    ) {
                        Text("Confidence")
                    } minimumValueLabel: {
                        Text("More")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("Less")
                            .font(.caption)
                    }

                    Text("Higher values = fewer suggestions, but more accurate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Output Format") {
                HStack {
                    Text("Language:")
                        .font(.subheadline)

                    Spacer()

                    Picker("Language", selection: $appSettings.smartCaptureOutputLanguage) {
                        Text("Same as input").tag("auto")
                        Divider()
                        Text("English").tag("en")
                        Text("Chinese (Simplified)").tag("zh")
                        Text("Chinese (Traditional)").tag("zh-TW")
                        Text("Japanese").tag("ja")
                        Text("Korean").tag("ko")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Spanish").tag("es")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)
                }

                Toggle("Use Markdown Formatting", isOn: $appSettings.smartCaptureUseRichContent)
                    .font(.subheadline)

                Text("Markdown adds headers, lists, and emphasis for better readability")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Global Hotkey") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Task Capture Hotkey")
                        .font(.subheadline)

                    KeyboardShortcuts.Recorder(for: .smartTaskCapture)

                    Text("Global keyboard shortcut to analyze clipboard content from any application")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        }
        .formStyle(.grouped)
        .padding(20)
    }

    private var sensitivityLabel: String {
        switch appSettings.smartCaptureConfidenceThreshold {
        case 0.3..<0.5:
            return "High Sensitivity"
        case 0.5..<0.7:
            return "Medium Sensitivity"
        case 0.7..<0.9:
            return "Low Sensitivity"
        default:
            return "Very Low Sensitivity"
        }
    }

    private func configureService() {
        // This will be called when settings change
        // The SmartTaskCapture service will need to be updated to observe @AppStorage
        NotificationCenter.default.post(name: .smartTaskCaptureSettingsChanged, object: nil)
    }
}

struct TroubleshootingTab: View {
    let modelContext: ModelContext

    @State private var isCleaningDuplicates = false
    @State private var cleanupMessage: String?
    @State private var showingResetConfirmation = false
    @State private var resetMessage: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundStyle(.orange)
                            .font(.title2)

                        Text("Troubleshooting")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Text("Tools to fix common issues")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Duplicate Tasks") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("If you see duplicate tasks, use this tool to clean them up.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: cleanupDuplicates) {
                        HStack {
                            if isCleaningDuplicates {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                            }
                            Text("Remove Duplicate Tasks")
                        }
                    }
                    .disabled(isCleaningDuplicates)
                    .buttonStyle(.borderedProminent)

                    if let message = cleanupMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.top, 4)
                    }
                }
            }

            Section("Reset Database") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text("Danger Zone")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }

                    Text("Permanently delete ALL tasks and reset the database to a clean state. This action syncs to iCloud and CANNOT be undone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Reset Database") {
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .alert("Reset Database?", isPresented: $showingResetConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete Everything", role: .destructive) {
                            resetDatabase()
                        }
                    } message: {
                        Text("This will permanently delete ALL tasks from this device and iCloud. This action cannot be undone.\n\nAre you absolutely sure?")
                    }

                    if let message = resetMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("Error") ? .red : .green)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }

    private func cleanupDuplicates() {
        isCleaningDuplicates = true
        cleanupMessage = nil

        _Concurrency.Task { @MainActor in
            do {
                try DuplicateCleanup.removeDuplicates(modelContext: modelContext)
                cleanupMessage = "✓ Duplicate cleanup completed"
            } catch {
                cleanupMessage = "Error: \(error.localizedDescription)"
            }
            isCleaningDuplicates = false

            // Clear message after 5 seconds
            try? await _Concurrency.Task.sleep(for: .seconds(5))
            cleanupMessage = nil
        }
    }

    private func resetDatabase() {
        resetMessage = nil

        _Concurrency.Task { @MainActor in
            do {
                // Delete all Task objects
                // This will automatically sync to CloudKit/iCloud
                try modelContext.delete(model: Task.self)

                // Save the changes
                try modelContext.save()

                resetMessage = "✓ Database reset successfully. All tasks deleted."
                print("Database reset: All tasks deleted and synced to CloudKit")

                // Clear message after 10 seconds
                try? await _Concurrency.Task.sleep(for: .seconds(10))
                resetMessage = nil

            } catch {
                resetMessage = "Error: \(error.localizedDescription)"
                print("Database reset error: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let smartTaskCaptureSettingsChanged = Notification.Name("smartTaskCaptureSettingsChanged")
}


#Preview {
    SettingsView()
        .modelContainer(for: Task.self, inMemory: true)
}

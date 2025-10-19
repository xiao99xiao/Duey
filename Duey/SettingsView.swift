//
//  SettingsView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings()

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
        }
        .frame(width: 500, height: 400)
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

extension Notification.Name {
    static let smartTaskCaptureSettingsChanged = Notification.Name("smartTaskCaptureSettingsChanged")
}


#Preview {
    SettingsView()
}
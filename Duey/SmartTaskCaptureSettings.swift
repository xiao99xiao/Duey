//
//  SmartTaskCaptureSettings.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI

struct SmartTaskCaptureSettings: View {
    @ObservedObject var smartCapture: SmartTaskCapture
    @State private var showingAPIKeyHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                        .font(.title2)

                    Text("Smart Task Capture")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Text("Press ⌘⇧T to analyze clipboard content for potential tasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Main Toggle
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Smart Task Capture", isOn: $smartCapture.isEnabled)
                    .font(.headline)
                    .onChange(of: smartCapture.isEnabled) { _, _ in
                        // Save settings when toggled
                    }

                if smartCapture.isEnabled {
                    Label("Press ⌘⇧T to analyze clipboard content", systemImage: "keyboard")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Feature is disabled", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Global keyboard shortcut works from any application")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // API Key Configuration
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("OpenAI API Key")
                        .font(.headline)

                    Button(action: { showingAPIKeyHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("How to get an API key")
                }

                SecureField("Enter your OpenAI API key", text: Binding(
                    get: { smartCapture.apiKey },
                    set: { smartCapture.setAPIKey($0) }
                ))
                .textFieldStyle(.roundedBorder)

                if smartCapture.apiKey.isEmpty {
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

            // Sensitivity Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Detection Sensitivity")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence Threshold: \(Int(smartCapture.confidenceThreshold * 100))%")
                            .font(.subheadline)

                        Spacer()

                        Text(sensitivityLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $smartCapture.confidenceThreshold,
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

            // Language and Content Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Output Format")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Language:")
                            .font(.subheadline)

                        Spacer()

                        Picker("Language", selection: $smartCapture.outputLanguage) {
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

                    Toggle("Use Markdown Formatting", isOn: $smartCapture.useRichContent)
                        .font(.subheadline)

                    Text("Markdown adds headers, lists, and emphasis for better readability")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }


            Spacer()

            // Test Button
            VStack(alignment: .leading, spacing: 12) {
                Text("Testing")
                    .font(.headline)

                Button(action: {
                    smartCapture.analyzeClipboard()
                }) {
                    HStack {
                        Image(systemName: "clipboard.fill")
                        Text("Test Analyze Clipboard")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!smartCapture.isEnabled || smartCapture.apiKey.isEmpty)

                Text("Copy some text first, then click this button to test")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Status Information
            if smartCapture.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing clipboard content...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Result Message
            if smartCapture.showResultMessage {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text(smartCapture.lastResultMessage)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private var sensitivityLabel: String {
        switch smartCapture.confidenceThreshold {
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
}

#Preview {
    SmartTaskCaptureSettings(smartCapture: SmartTaskCapture())
}
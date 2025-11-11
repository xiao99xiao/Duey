//
//  DiagnosticsView.swift
//  Duey
//
//  Comprehensive diagnostics and data export tool
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DiagnosticsView: View {
    let modelContext: ModelContext

    @State private var tasks: [Task] = []
    @State private var isExporting = false
    @State private var exportedFilePath: String?
    @State private var errorMessage: String?
    @State private var isRefreshing = false
    @State private var exportDocument: JSONExportDocument?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                // CloudKit Status
                cloudKitStatusSection

                // Tasks Overview
                tasksOverviewSection

                // Export Section
                exportSection

                // All Tasks List
                allTasksSection
            }
            .padding(20)
        }
        .frame(minWidth: 700, minHeight: 600)
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: generateExportFilename()
        ) { result in
            handleExportResult(result)
        }
        .onAppear {
            refreshData()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "stethoscope")
                    .foregroundStyle(.blue)
                    .font(.system(size: 32))

                VStack(alignment: .leading) {
                    Text("Database Diagnostics")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("View all data and export for backup")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: refreshData) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Data")
                }
            }
            .disabled(isRefreshing)
            .buttonStyle(.bordered)
        }
    }

    private var cloudKitStatusSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Storage Configuration", systemImage: "icloud")
                    .font(.headline)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Storage Type:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("CloudKit (iCloud)")
                            .foregroundStyle(.blue)
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Sync Status:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Enabled ✓")
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    }

                    Text("All task data is stored in iCloud and syncs across your devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(8)
        }
    }

    private var tasksOverviewSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("Tasks Overview", systemImage: "list.bullet.clipboard")
                    .font(.headline)

                Divider()

                HStack(spacing: 40) {
                    VStack {
                        Text("\(tasks.count)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.blue)
                        Text("Total Tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text("\(tasks.filter { !$0.isCompleted }.count)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.orange)
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text("\(tasks.filter { $0.isCompleted }.count)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(8)
        }
    }

    private var exportSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Label("Export Data", systemImage: "square.and.arrow.up")
                    .font(.headline)

                Divider()

                Text("Export all tasks to a JSON file for backup (you'll choose where to save)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: exportData) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("Export All Tasks to JSON")
                    }
                }
                .disabled(tasks.isEmpty)
                .buttonStyle(.borderedProminent)

                if let filePath = exportedFilePath {
                    HStack {
                        Text("✓ Exported to:")
                            .foregroundStyle(.green)
                        Text(filePath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Button("Show in Finder") {
                        NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.link)
                }

                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding(8)
        }
    }

    private var allTasksSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Label("All Tasks (\(tasks.count))", systemImage: "list.bullet.rectangle")
                    .font(.headline)

                Divider()

                if tasks.isEmpty {
                    Text("No tasks found in database")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(tasks, id: \.id) { task in
                                TaskDiagnosticRow(task: task)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                }
            }
            .padding(8)
        }
    }

    private func refreshData() {
        isRefreshing = true

        _Concurrency.Task { @MainActor in
            do {
                // Fetch all tasks
                let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
                tasks = try modelContext.fetch(descriptor)

                print("Diagnostics: Found \(tasks.count) tasks in CloudKit")
            } catch {
                print("Diagnostics error: \(error)")
                errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
            }

            isRefreshing = false
        }
    }


    private func exportData() {
        // Clear previous state
        exportedFilePath = nil
        errorMessage = nil

        do {
            // Create export data
            let exportTasks = tasks.map { task -> ExportTask in
                ExportTask(
                    title: task.title,
                    contentData: task.contentData?.base64EncodedString(),
                    deadline: task.deadline,
                    isCompleted: task.isCompleted,
                    createdAt: task.createdAt,
                    completedAt: task.completedAt
                )
            }

            let exportData = ExportData(
                exportDate: Date(),
                version: "1.0",
                taskCount: exportTasks.count,
                tasks: exportTasks
            )

            // Create document and trigger export
            exportDocument = JSONExportDocument(exportData: exportData)
            isExporting = true

        } catch {
            errorMessage = error.localizedDescription
            print("Export error: \(error)")
        }
    }

    private func generateExportFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "Duey_Tasks_Export_\(dateString).json"
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            exportedFilePath = url.path
            print("Exported \(tasks.count) tasks to: \(url.path)")
        case .failure(let error):
            errorMessage = error.localizedDescription
            print("Export error: \(error)")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
        .font(.caption)
    }
}

struct TaskDiagnosticRow: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                    .font(.system(.body, weight: .medium))
                    .strikethrough(task.isCompleted)

                Spacer()

                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 12) {
                if let deadline = task.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Label(task.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if task.contentData != nil {
                    Label("\(task.contentData!.count) bytes", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Data Structures

struct ExportData: Codable {
    let exportDate: Date
    let version: String
    let taskCount: Int
    let tasks: [ExportTask]
}

struct ExportTask: Codable {
    let title: String
    let contentData: String?  // Base64 encoded
    let deadline: Date?
    let isCompleted: Bool
    let createdAt: Date
    let completedAt: Date?
}

// FileDocument for JSON export
struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var exportData: ExportData

    init(exportData: ExportData) {
        self.exportData = exportData
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        exportData = try decoder.decode(ExportData.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)
        return FileWrapper(regularFileWithContents: data)
    }
}

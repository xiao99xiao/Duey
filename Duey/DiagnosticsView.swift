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
    @State private var isImporting = false
    @State private var importMessage: String?

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
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
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
                Label("Import & Export Data", systemImage: "arrow.up.arrow.down")
                    .font(.headline)

                Divider()

                // Export Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Export all tasks to a JSON file for backup")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
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
                }

                Divider()

                // Import Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Import tasks from a previously exported JSON file")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(action: { isImporting = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Tasks from JSON")
                        }
                    }
                    .buttonStyle(.bordered)

                    if let message = importMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("Error") ? .red : .green)
                            .padding(.top, 4)
                    }
                }

                if let error = errorMessage {
                    Divider()
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

        // Create export data
        let exportTasks = tasks.map { task -> ExportTask in
            ExportTask(
                title: task.title,
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

    private func handleImportResult(_ result: Result<[URL], Error>) {
        importMessage = nil
        errorMessage = nil

        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else {
                errorMessage = "No file selected"
                return
            }

            importFromFile(fileURL)

        case .failure(let error):
            errorMessage = "Import failed: \(error.localizedDescription)"
            print("Import error: \(error)")
        }
    }

    private func importFromFile(_ fileURL: URL) {
        do {
            // Start accessing the security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                return
            }
            defer { fileURL.stopAccessingSecurityScopedResource() }

            // Read the JSON file
            let data = try Data(contentsOf: fileURL)

            // Decode the export data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exportData = try decoder.decode(ExportData.self, from: data)

            print("Importing \(exportData.taskCount) tasks from export dated \(exportData.exportDate)")

            // Track import results
            var importedCount = 0
            var skippedCount = 0

            // Import each task
            for exportTask in exportData.tasks {
                // Check for duplicates (by title and createdAt)
                let isDuplicate = tasks.contains { task in
                    task.title == exportTask.title &&
                    abs(task.createdAt.timeIntervalSince(exportTask.createdAt)) < 1.0
                }

                if isDuplicate {
                    skippedCount += 1
                    print("Skipping duplicate task: \(exportTask.title)")
                    continue
                }

                // Create new task
                let newTask = Task(
                    title: exportTask.title,
                    deadline: exportTask.deadline,
                    isCompleted: exportTask.isCompleted
                )

                // Restore timestamps
                newTask.createdAt = exportTask.createdAt
                newTask.completedAt = exportTask.completedAt

                modelContext.insert(newTask)
                importedCount += 1
            }

            // Save changes
            try modelContext.save()

            // Refresh the task list
            refreshData()

            // Show success message
            if skippedCount > 0 {
                importMessage = "✓ Imported \(importedCount) tasks, skipped \(skippedCount) duplicates"
            } else {
                importMessage = "✓ Successfully imported \(importedCount) tasks"
            }

            print("Import completed: \(importedCount) imported, \(skippedCount) skipped")

        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            print("Import error: \(error)")
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

                if let rtfData = task.contentRTF {
                    Label("\(ByteCountFormatter.string(fromByteCount: Int64(rtfData.count), countStyle: .file))", systemImage: "doc.richtext")
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

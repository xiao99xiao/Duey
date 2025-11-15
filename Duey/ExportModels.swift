//
//  ExportModels.swift
//  Duey
//
//  Data models for task export/import functionality
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

// MARK: - Data Structures

struct ExportData: Codable, Sendable {
    let exportDate: Date
    let version: String
    let taskCount: Int
    let tasks: [ExportTask]
}

struct ExportTask: Codable, Sendable {
    let title: String
    let content: String?  // Plain text content
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

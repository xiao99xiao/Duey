//
//  TaskMigrationPlan.swift
//  Duey
//
//  Migration plan for Task model schema changes
//

import Foundation
import SwiftData

enum TaskMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [TaskSchemaV1.self, TaskSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: TaskSchemaV1.self,
        toVersion: TaskSchemaV2.self,
        willMigrate: { context in
            print("🔄 Starting migration from V1 to V2...")

            // Fetch all V1 tasks
            let tasks = try context.fetch(FetchDescriptor<TaskSchemaV1>())
            print("📦 Found \(tasks.count) tasks to migrate")

            // The migration will automatically add the new contentData field
            // and set it to nil for all existing tasks
            // The content field will be preserved
        },
        didMigrate: { context in
            print("✅ Migration from V1 to V2 completed successfully")
        }
    )
}

// Schema V1: Original model
extension TaskSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskSchemaV1.self]
    }
}

// Schema V2: Current model with contentData
extension TaskSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TaskSchemaV2.self]
    }
}

// Type alias for current version
typealias Task = TaskSchemaV2

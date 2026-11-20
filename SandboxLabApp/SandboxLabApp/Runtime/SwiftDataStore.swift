import Foundation
import SwiftData
import SandboxLabCore

/// SwiftData mirror of Core's `ProbeRunRecord`. Stored as an `Int` because
/// errno values are small and this keeps the schema to plain supported types.
@Model
final class ProbeRunEntity {
    var id: UUID
    var probeID: String
    var categoryRaw: String
    var startedAt: Date
    var durationMs: Int
    var output: String
    var errorDomain: String?
    var errorCode: Int?
    var rawErrno: Int?
    var errorMessage: String?
    var deviceModel: String
    var osVersion: String
    var buildNumber: String

    init(record: ProbeRunRecord) {
        id = record.id
        probeID = record.probeID
        categoryRaw = record.categoryRaw
        startedAt = record.startedAt
        durationMs = record.durationMs
        output = record.output
        errorDomain = record.errorDomain
        errorCode = record.errorCode
        rawErrno = record.rawErrno.map(Int.init)
        errorMessage = record.errorMessage
        deviceModel = record.deviceModel
        osVersion = record.osVersion
        buildNumber = record.buildNumber
    }

    var record: ProbeRunRecord {
        ProbeRunRecord(
            id: id,
            probeID: probeID,
            categoryRaw: categoryRaw,
            startedAt: startedAt,
            durationMs: durationMs,
            output: output,
            errorDomain: errorDomain,
            errorCode: errorCode,
            rawErrno: rawErrno.flatMap { Int32(exactly: $0) },
            errorMessage: errorMessage,
            deviceModel: deviceModel,
            osVersion: osVersion,
            buildNumber: buildNumber
        )
    }
}

/// Persists raw observations locally. A fresh `ModelContext` is created per
/// operation so no context or model instance ever crosses an actor boundary;
/// only the sendable `ModelContainer` is retained.
actor SwiftDataStore: ProbeStoring {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func save(_ record: ProbeRunRecord) async throws {
        let context = ModelContext(container)
        context.insert(ProbeRunEntity(record: record))
        try context.save()
    }

    func all() async throws -> [ProbeRunRecord] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<ProbeRunEntity>(
            sortBy: [SortDescriptor<ProbeRunEntity>(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.record)
    }
}

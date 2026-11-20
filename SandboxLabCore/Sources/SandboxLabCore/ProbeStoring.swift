public protocol ProbeStoring: Sendable {
    func save(_ record: ProbeRunRecord) async throws
    func all() async throws -> [ProbeRunRecord]
    func deleteAll() async throws
}

public actor InMemoryProbeStore: ProbeStoring {
    private var records: [ProbeRunRecord] = []

    public init() {}

    public func save(_ record: ProbeRunRecord) async throws {
        records.append(record)
    }

    public func all() async throws -> [ProbeRunRecord] {
        records
    }

    public func deleteAll() async throws {
        records.removeAll()
    }
}

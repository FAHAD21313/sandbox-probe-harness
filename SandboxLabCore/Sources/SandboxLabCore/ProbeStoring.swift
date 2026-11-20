public protocol ProbeStoring: Sendable {
    func save(_ record: ProbeRunRecord) async throws
    func all() async throws -> [ProbeRunRecord]
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
}

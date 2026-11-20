public struct ProbeRegistry: Sendable {
    public init(_ probes: [any SecurityProbe]) {
        self.probes = probes
    }

    public let probes: [any SecurityProbe]

    public func contains(id: String) -> Bool {
        probes.contains { $0.id == id }
    }
}

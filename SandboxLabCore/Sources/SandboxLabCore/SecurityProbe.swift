public protocol SecurityProbe: Sendable {
    var id: String { get }
    var title: String { get }
    var category: ProbeCategory { get }
    func body() async throws -> String
}

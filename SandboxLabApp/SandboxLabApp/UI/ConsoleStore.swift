import Foundation

struct ConsoleLine: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let text: String
}

/// Collects live run observations. Isolated to the main actor so SwiftUI can
/// observe updates as soon as a run produces output.
@MainActor
final class ConsoleStore: ObservableObject {
    @Published private(set) var lines: [ConsoleLine] = []

    func log(_ text: String) {
        lines.append(ConsoleLine(id: UUID(), timestamp: Date(), text: text))
    }

    func clear() {
        lines.removeAll()
    }

    var plainText: String {
        lines.map(\.text).joined(separator: "\n")
    }
}

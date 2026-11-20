import SwiftUI
import SwiftData
import SandboxLabCore

@MainActor
@main
struct SandboxLabApp: App {
    private let container: ModelContainer
    private let store: SwiftDataStore
    private let device = DeviceInfo()
    private let runner = ProbeRunner()
    private let probes = AppProbeRegistry.probes

    @StateObject private var console = ConsoleStore()

    init() {
        do {
            container = try ModelContainer(for: ProbeRunEntity.self)
        } catch {
            fatalError("Could not configure the local observation store: \(error)")
        }
        store = SwiftDataStore(container: container)
    }

    var body: some Scene {
        WindowGroup {
            ProbeListView(
                probes: probes,
                device: device,
                runner: runner,
                store: store,
                console: console
            )
        }
        .modelContainer(container)
    }
}

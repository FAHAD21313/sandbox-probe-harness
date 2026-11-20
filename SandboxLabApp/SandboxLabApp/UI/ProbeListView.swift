import SwiftUI
import SandboxLabCore

struct ProbeListView: View {
    let probes: [any SecurityProbe]
    let device: any DeviceInfoProviding
    let runner: ProbeRunner
    let store: SwiftDataStore
    let console: ConsoleStore

    @State private var alertMessage: String?
    @State private var showingAlert = false

    private var groups: [ProbeGroup] {
        ProbeCategory.allCases.compactMap { category in
            let matches = probes.filter { $0.category == category }
            return matches.isEmpty ? nil : ProbeGroup(category: category, probes: matches)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section(group.category.displayName) {
                        ForEach(group.probes) { row in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(row.probe.title)
                                    Text(row.probe.id)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Run") { run(row.probe) }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sandbox Lab")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink("Log") {
                        LogListView(store: store)
                    }
                    NavigationLink("Console") {
                        ConsoleView(store: console)
                    }
                    NavigationLink("Settings") {
                        SettingsView(store: store)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Run All") { runAll() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    @MainActor
    private func run(_ probe: any SecurityProbe) {
        Task {
            let record = await execute(probe)
            await persist(record)
        }
    }

    @MainActor
    private func runAll() {
        Task {
            var records: [ProbeRunRecord] = []
            for probe in probes {
                records.append(await execute(probe))
            }
            for record in records {
                await persist(record)
            }
        }
    }

    /// Runs one probe and mirrors its raw observation into the live console.
    @MainActor
    private func execute(_ probe: any SecurityProbe) async -> ProbeRunRecord {
        await console.log("Running \(probe.id)...")
        let record = await runner.run(probe, device: device)
        for line in record.output.split(separator: "\n") {
            await console.log(String(line))
        }
        await console.log("Finished \(record.probeID) in \(record.durationMs) ms")
        return record
    }

    @MainActor
    private func persist(_ record: ProbeRunRecord) async {
        do {
            try await store.save(record)
        } catch {
            let message = error.localizedDescription
            await console.log(message)
            alertMessage = message
            showingAlert = true
        }
    }
}

private struct ProbeGroup: Identifiable {
    let category: ProbeCategory
    let probes: [ProbeRow]
    var id: ProbeCategory { category }

    init(category: ProbeCategory, probes: [any SecurityProbe]) {
        self.category = category
        self.probes = probes.map(ProbeRow.init)
    }
}

private struct ProbeRow: Identifiable {
    let probe: any SecurityProbe
    var id: String { probe.id }
}

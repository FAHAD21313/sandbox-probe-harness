import SwiftUI
import SandboxLabCore

struct ProbeListView: View {
    let probes: [any SecurityProbe]
    let device: any DeviceInfoProviding
    let runner: ProbeRunner
    let store: SwiftDataStore

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
                                Button("تشغيل") { run(row.probe) }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("مختبر الساندبوكس")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("السجل") {
                        LogListView(store: store)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("تشغيل الكل") { runAll() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .alert("خطأ", isPresented: $showingAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func run(_ probe: any SecurityProbe) {
        Task {
            let record = await runner.run(probe, device: device)
            await persist(record)
        }
    }

    private func runAll() {
        Task {
            let records = await runner.runAll(probes, device: device)
            for record in records {
                await persist(record)
            }
        }
    }

    private func persist(_ record: ProbeRunRecord) async {
        do {
            try await store.save(record)
        } catch {
            alertMessage = error.localizedDescription
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

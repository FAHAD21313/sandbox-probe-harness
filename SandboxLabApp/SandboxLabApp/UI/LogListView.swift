import SwiftUI
import SandboxLabCore

struct LogListView: View {
    let store: SwiftDataStore

    @State private var records: [ProbeRunRecord] = []
    @State private var alertMessage: String?
    @State private var showingAlert = false

    var body: some View {
        List {
            ForEach(records, id: \.id) { record in
                NavigationLink {
                    RunDetailView(record: record)
                } label: {
                    VStack(alignment: .leading) {
                        Text(record.probeID)
                        Text(record.startedAt.formatted(date: .abbreviated, time: .standard))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("السجل")
        .task { await load() }
        .alert("خطأ", isPresented: $showingAlert) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func load() async {
        do {
            let all = try await store.all()
            records = all.sorted { $0.startedAt > $1.startedAt }
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

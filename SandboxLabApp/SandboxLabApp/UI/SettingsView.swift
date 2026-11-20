import SwiftUI
import UIKit
import SandboxLabCore

struct SettingsView: View {
    let store: SwiftDataStore

    @State private var showingClearConfirmation = false
    @State private var alertMessage: String?
    @State private var showingAlert = false

    var body: some View {
        List {
            Button("Copy Logs") {
                Task { await copyLogs() }
            }
            Button("Clear All Logs", role: .destructive) {
                showingClearConfirmation = true
            }
        }
        .navigationTitle("Settings")
        .alert("Clear All Logs", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                Task { await clearAll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Delete all saved observations? This cannot be undone.")
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    @MainActor
    private func copyLogs() async {
        do {
            let records = try await store.all()
            UIPasteboard.general.string = records.map(Self.format).joined(separator: "\n\n")
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    @MainActor
    private func clearAll() async {
        do {
            try await store.deleteAll()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private static func format(_ record: ProbeRunRecord) -> String {
        var lines = [
            "Probe: \(record.probeID)",
            "Started: \(record.startedAt.formatted(date: .complete, time: .complete))",
            "Duration: \(record.durationMs) ms",
            "Device: \(record.deviceModel), iOS \(record.osVersion) (build \(record.buildNumber))",
            "Raw Output:",
            record.output
        ]
        if let domain = record.errorDomain { lines.append("Error domain: \(domain)") }
        if let code = record.errorCode { lines.append("Error code: \(code)") }
        if let errno = record.rawErrno { lines.append("errno: \(errno)") }
        if let message = record.errorMessage { lines.append("Error message: \(message)") }
        return lines.joined(separator: "\n")
    }
}

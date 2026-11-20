import SwiftUI
import SandboxLabCore

struct RunDetailView: View {
    let record: ProbeRunRecord

    var body: some View {
        List {
            Section("Raw Output") {
                Text(record.output.isEmpty ? "—" : record.output)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Error") {
                if let domain = record.errorDomain {
                    LabeledContent("domain", value: domain)
                }
                if let code = record.errorCode {
                    LabeledContent("code", value: String(code))
                }
                if let errno = record.rawErrno {
                    LabeledContent("errno", value: String(errno))
                }
                if let message = record.errorMessage {
                    LabeledContent("message", value: message)
                }
                if record.errorDomain == nil, record.errorCode == nil,
                   record.rawErrno == nil, record.errorMessage == nil {
                    Text("No error")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Timing & Device") {
                LabeledContent("Duration", value: "\(record.durationMs) ms")
                LabeledContent("Started", value: record.startedAt.formatted(date: .complete, time: .complete))
                LabeledContent("Device", value: record.deviceModel)
                LabeledContent("iOS Version", value: record.osVersion)
                LabeledContent("Build Number", value: record.buildNumber)
            }
        }
        .navigationTitle(record.probeID)
    }
}

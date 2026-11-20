import SwiftUI
import SandboxLabCore

struct RunDetailView: View {
    let record: ProbeRunRecord

    var body: some View {
        List {
            Section("النص الخام") {
                Text(record.output.isEmpty ? "—" : record.output)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
            }

            Section("الخطأ") {
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
                    Text("لا يوجد خطأ")
                        .foregroundStyle(.secondary)
                }
            }

            Section("الزمن والجهاز") {
                LabeledContent("المدة", value: "\(record.durationMs) ms")
                LabeledContent("البداية", value: record.startedAt.formatted(date: .complete, time: .complete))
                LabeledContent("الجهاز", value: record.deviceModel)
                LabeledContent("إصدار iOS", value: record.osVersion)
                LabeledContent("رقم البناء", value: record.buildNumber)
            }
        }
        .navigationTitle(record.probeID)
    }
}

import Foundation
import SandboxLabCore

struct CustomProbe: SecurityProbe {
    let id = "custom"
    let title = "اختبار مخصص"
    let category: ProbeCategory = .filesystem

    func body() async throws -> String {
        var observations: [String] = []

        // Path observation only — directory contents are never enumerated.
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let tmp = FileManager.default.temporaryDirectory
        observations.append("Documents: \(documents?.path ?? "<unavailable>")")
        observations.append("tmp: \(tmp.path)")
        observations.append("Bundle: \(Bundle.main.bundleURL.path)")

        // Harmless write probe: a UUID-named file with fixed content, removed afterwards.
        let fileURL = tmp.appendingPathComponent("sandbox-probe-\(UUID().uuidString).txt")
        do {
            try Data("sandbox probe\n".utf8).write(to: fileURL, options: .atomic)
            observations.append("write tmp: ok (\(fileURL.lastPathComponent))")
        } catch {
            throw Self.probeError(operation: "write tmp file", error: error)
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            observations.append("remove tmp: ok")
        } catch {
            throw Self.probeError(operation: "remove tmp file", error: error)
        }

        return observations.joined(separator: "\n")
    }

    private static func probeError(operation: String, error: Error) -> ProbeError {
        let nsError = error as NSError
        return ProbeError(
            domain: nsError.domain,
            code: nsError.code,
            errnoValue: posixErrno(from: nsError),
            message: "\(operation) failed: \(nsError.localizedDescription)"
        )
    }

    private static func posixErrno(from error: NSError) -> Int32? {
        let posixDomains = [NSPOSIXErrorDomain, "POSIX"]
        if posixDomains.contains(error.domain), let code = Int32(exactly: error.code) {
            return code
        }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           posixDomains.contains(underlying.domain),
           let code = Int32(exactly: underlying.code) {
            return code
        }
        return nil
    }
}

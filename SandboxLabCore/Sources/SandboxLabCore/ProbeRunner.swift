import Foundation

public struct ProbeRunner: Sendable {
    public init() {}

    public func run(
        _ probe: any SecurityProbe,
        device: any DeviceInfoProviding,
        now: @escaping () -> Date = Date.init
    ) async -> ProbeRunRecord {
        let startedAt = now()

        var output = ""
        var errorDomain: String?
        var errorCode: Int?
        var rawErrno: Int32?
        var errorMessage: String?

        do {
            output = try await probe.body()
        } catch let error as ProbeError {
            // A pure-Swift ProbeError must be mapped directly: NSError bridging
            // would drop its authored domain, code and raw errno.
            errorDomain = error.domain
            errorCode = error.code
            rawErrno = error.errnoValue
            errorMessage = error.message
        } catch {
            let details = error.probeDetails
            errorDomain = details.domain
            errorCode = details.code
            rawErrno = details.rawErrno
            errorMessage = details.message
        }

        // Round to nearest millisecond: Date/timeInterval binary representation
        // can make an exact 5 ms interval read back as 4.999995 ms on Linux.
        let durationMs = Int((now().timeIntervalSince(startedAt) * 1000).rounded())

        return ProbeRunRecord(
            id: UUID(),
            probeID: probe.id,
            categoryRaw: probe.category.rawValue,
            startedAt: startedAt,
            durationMs: durationMs,
            output: output,
            errorDomain: errorDomain,
            errorCode: errorCode,
            rawErrno: rawErrno,
            errorMessage: errorMessage,
            deviceModel: device.hardwareIdentifier,
            osVersion: device.osVersion,
            buildNumber: device.buildNumber
        )
    }

    /// Runs every probe in order and returns one raw record per probe.
    /// `run` captures errors internally, so a failing probe never aborts the batch.
    public func runAll(
        _ probes: [any SecurityProbe],
        device: any DeviceInfoProviding,
        now: @escaping () -> Date = Date.init
    ) async -> [ProbeRunRecord] {
        var records: [ProbeRunRecord] = []
        records.reserveCapacity(probes.count)
        for probe in probes {
            records.append(await run(probe, device: device, now: now))
        }
        return records
    }
}

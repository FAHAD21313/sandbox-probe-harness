import Foundation
import XCTest
import SandboxLabCore

struct StubProbe: SecurityProbe {
    let id: String
    let title: String
    let category: ProbeCategory
    let result: Result<String, Error>

    init(id: String = "stub", title: String = "Stub", category: ProbeCategory = .filesystem,
         result: Result<String, Error>) {
        self.id = id
        self.title = title
        self.category = category
        self.result = result
    }

    func body() async throws -> String { try result.get() }
}

private final class Clock {
    var dates: [Date]
    init(_ dates: [Date]) { self.dates = dates }
    func next() -> Date { dates.removeFirst() }
}

final class ProbeRunnerTests: XCTestCase {
    func testRunPreservesPOSIXErrno() async {
        let probe = StubProbe(result: .failure(
            NSError(domain: "POSIX", code: 13, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        ))
        let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
        XCTAssertEqual(record.errorDomain, "POSIX")
        XCTAssertEqual(record.errorCode, 13)
        XCTAssertEqual(record.rawErrno, 13)
        XCTAssertEqual(record.errorMessage, "Permission denied")
    }

    func testRunWithEmptyOutputStillProducesRecord() async {
        let probe = StubProbe(result: .success(""))
        let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
        XCTAssertEqual(record.output, "")
        XCTAssertEqual(record.probeID, "stub")
        XCTAssertNil(record.errorDomain)
    }

    func testRunUsesUnknownDeviceWhenProviderMissing() async {
        let probe = StubProbe(result: .success("ok"))
        let clock = Clock([Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 0.005)])
        let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { clock.next() })
        XCTAssertEqual(record.deviceModel, "unknown")
        XCTAssertEqual(record.durationMs, 5)
    }

    func testRunMapsThrownProbeErrorDirectly() async {
        let probe = StubProbe(result: .failure(
            ProbeError(domain: "SandboxLabCore.Custom", code: 99, errnoValue: 13, message: "direct errno")
        ))
        let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
        XCTAssertEqual(record.errorDomain, "SandboxLabCore.Custom")
        XCTAssertEqual(record.errorCode, 99)
        XCTAssertEqual(record.rawErrno, 13)
        XCTAssertEqual(record.errorMessage, "direct errno")
    }
}

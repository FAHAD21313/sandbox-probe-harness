import Foundation
import XCTest
import SandboxLabCore

final class ProbeRegistryTests: XCTestCase {
    func testRunAllContinuesAfterFailure() async {
        let good = StubProbe(result: .success("ok"))
        let bad = StubProbe(id: "bad", result: .failure(NSError(domain: "POSIX", code: 1)))
        let records = await ProbeRunner().runAll([bad, good], device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records.map(\.probeID), ["bad", "stub"])
    }

    func testRegistryAcceptsNewProbeWithoutRunnerChanges() {
        let registry = ProbeRegistry([StubProbe(result: .success(""))])
        XCTAssertTrue(registry.contains(id: "stub"))
        XCTAssertFalse(registry.contains(id: "missing"))
    }

    func testInMemoryStorePersistsRecords() async throws {
        let store = InMemoryProbeStore()
        let record = await ProbeRunner().run(StubProbe(result: .success("x")), device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
        try await store.save(record)
        let stored = try await store.all()
        XCTAssertEqual(stored, [record])
    }
}

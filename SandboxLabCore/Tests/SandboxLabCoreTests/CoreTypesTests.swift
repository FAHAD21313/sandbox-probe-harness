import Foundation
import XCTest
import SandboxLabCore

final class CoreTypesTests: XCTestCase {
    func testProbeCategoryHasSixCases() {
        XCTAssertEqual(ProbeCategory.allCases.count, 6)
        XCTAssertEqual(Set(ProbeCategory.allCases.map(\.rawValue)).count, 6)
    }

    func testPOSIXErrorExposesRawErrno() {
        let error = NSError(domain: "POSIX", code: 1, userInfo: [NSLocalizedDescriptionKey: "Operation not permitted"])
        let details = error.probeDetails
        XCTAssertEqual(details.domain, "POSIX")
        XCTAssertEqual(details.code, 1)
        XCTAssertEqual(details.rawErrno, 1)
        XCTAssertEqual(details.message, "Operation not permitted")
    }

    func testProbeErrorNeedsDirectMappingBecauseBridgingLosesRawErrno() {
        let error = ProbeError(domain: "SandboxLabCore.Custom", code: 99, errnoValue: 13, message: "direct errno")
        let bridged = error.probeDetails
        // `as NSError` bridging replaces the authored domain/code/errno, so ProbeRunner
        // must map a thrown ProbeError directly (see ProbeRunnerTests).
        XCTAssertNotEqual(bridged.domain, error.domain)
        XCTAssertNil(bridged.rawErrno)
        XCTAssertNotEqual(bridged.message, error.message)
    }
}

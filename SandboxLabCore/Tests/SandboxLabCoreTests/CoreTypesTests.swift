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
}

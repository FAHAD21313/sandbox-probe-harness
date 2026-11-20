import Foundation

public extension Error {
    var probeDetails: (domain: String, code: Int, rawErrno: Int32?, message: String) {
        let nsError = self as NSError
        let domain = nsError.domain
        let code = nsError.code
        // POSIX errors carry the raw errno value in NSError.code.
        let rawErrno = domain == "POSIX" ? Int32(exactly: code) : nil
        return (domain: domain, code: code, rawErrno: rawErrno, message: nsError.localizedDescription)
    }
}

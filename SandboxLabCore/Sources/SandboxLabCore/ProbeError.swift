public struct ProbeError: Error, Sendable {
    public let domain: String
    public let code: Int
    public let errnoValue: Int32?
    public let message: String

    public init(domain: String, code: Int, errnoValue: Int32? = nil, message: String) {
        self.domain = domain
        self.code = code
        self.errnoValue = errnoValue
        self.message = message
    }
}

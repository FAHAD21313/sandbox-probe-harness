import Foundation

public struct ProbeRunRecord: Equatable, Sendable {
    public let id: UUID
    public let probeID: String
    public let categoryRaw: String
    public let startedAt: Date
    public let durationMs: Int
    public let output: String
    public let errorDomain: String?
    public let errorCode: Int?
    public let rawErrno: Int32?
    public let errorMessage: String?
    public let deviceModel: String
    public let osVersion: String
    public let buildNumber: String

    public init(
        id: UUID,
        probeID: String,
        categoryRaw: String,
        startedAt: Date,
        durationMs: Int,
        output: String,
        errorDomain: String?,
        errorCode: Int?,
        rawErrno: Int32?,
        errorMessage: String?,
        deviceModel: String,
        osVersion: String,
        buildNumber: String
    ) {
        self.id = id
        self.probeID = probeID
        self.categoryRaw = categoryRaw
        self.startedAt = startedAt
        self.durationMs = durationMs
        self.output = output
        self.errorDomain = errorDomain
        self.errorCode = errorCode
        self.rawErrno = rawErrno
        self.errorMessage = errorMessage
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.buildNumber = buildNumber
    }
}

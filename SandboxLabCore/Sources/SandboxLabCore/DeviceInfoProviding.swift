public protocol DeviceInfoProviding: Sendable {
    var hardwareIdentifier: String { get }
    var osVersion: String { get }
    var buildNumber: String { get }
}

public struct UnknownDeviceInfo: DeviceInfoProviding {
    public init() {}

    public var hardwareIdentifier: String { "unknown" }
    public var osVersion: String { "unknown" }
    public var buildNumber: String { "unknown" }
}

import Foundation
import SandboxLabCore

#if canImport(UIKit)
import UIKit
import Darwin
#endif

/// Reads the clean-device identifiers required for interpreting raw observations.
/// Every value falls back to `UnknownDeviceInfo` rather than guessing.
struct DeviceInfo: DeviceInfoProviding {
    private static let fallback = UnknownDeviceInfo()

    var hardwareIdentifier: String {
        #if canImport(UIKit)
        var size = 0
        let name = "hw.machine"
        guard name.withCString({ sysctlbyname($0, nil, &size, nil, 0) }) == 0, size > 0 else {
            return Self.fallback.hardwareIdentifier
        }
        var buffer = [CChar](repeating: 0, count: size)
        let status = buffer.withUnsafeMutableBytes { rawBuffer in
            name.withCString { sysctlbyname($0, rawBuffer.baseAddress, &size, nil, 0) }
        }
        guard status == 0 else { return Self.fallback.hardwareIdentifier }
        return String(cString: buffer)
        #else
        return Self.fallback.hardwareIdentifier
        #endif
    }

    var osVersion: String {
        #if canImport(UIKit)
        UIDevice.current.systemVersion
        #else
        Self.fallback.osVersion
        #endif
    }

    var buildNumber: String {
        #if canImport(UIKit)
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? Self.fallback.buildNumber
        #else
        Self.fallback.buildNumber
        #endif
    }
}

import SandboxLabCore

enum AppProbeRegistry {
    /// The only line to touch when adding a probe: drop one new file in `Probes/`
    /// and add its initializer here. Runner and UI need no changes.
    static let probes: [any SecurityProbe] = [CustomProbe()]
}

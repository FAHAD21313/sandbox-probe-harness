public enum ProbeCategory: String, CaseIterable, Sendable {
    case filesystem
    case processes
    case memoryExecution
    case dylibLoading
    case network
    case entitlements

    public var displayName: String {
        switch self {
        case .filesystem: return "File System"
        case .processes: return "Processes & Boot"
        case .memoryExecution: return "Memory & Execution Protection"
        case .dylibLoading: return "Dylib Loading"
        case .network: return "Network & Ports"
        case .entitlements: return "Entitlements"
        }
    }
}

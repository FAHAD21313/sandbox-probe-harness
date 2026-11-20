public enum ProbeCategory: String, CaseIterable, Sendable {
    case filesystem
    case processes
    case memoryExecution
    case dylibLoading
    case network
    case entitlements

    public var displayName: String {
        switch self {
        case .filesystem: return "نظام الملفات"
        case .processes: return "العمليات والإقلاع"
        case .memoryExecution: return "الذاكرة وحماية التنفيذ"
        case .dylibLoading: return "تحميل المكتبات"
        case .network: return "الشبكة والمنافذ"
        case .entitlements: return "الصلاحيات"
        }
    }
}

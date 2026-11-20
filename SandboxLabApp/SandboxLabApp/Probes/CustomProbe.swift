import SandboxLabCore

struct CustomProbe: SecurityProbe {
    let id = "custom"
    let title = "اختبار مخصص"
    let category: ProbeCategory = .filesystem

    func body() async throws -> String {
        // ← ضع كود الاختبار هنا
        return ""
    }
}

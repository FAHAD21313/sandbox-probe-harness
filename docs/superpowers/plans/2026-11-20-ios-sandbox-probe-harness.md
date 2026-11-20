# iOS Sandbox Probe Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** بناء إطار تطبيق iOS يشغّل كوداً يكتبه المستخدم في ملف قالب فارغ، ويسجّل رصداً خاماً لسلوك الساندبوكس في SwiftData محلياً.

**Architecture:** حزمتان: `SandboxLabCore` كـ Swift Package بلغة Swift صرفة (قابل للاختبار على Linux بـ `swift test`) يحوي البروتوكول والمشغّل والتخزين المجرد؛ و`SandboxLabApp` كهدف iOS بواجهة SwiftUI وتخزين SwiftData، يعتمد على الحزمة ولا يحوي أي كود اختبار. المستخدم يضع كوده في `Probes/CustomProbe.swift` فقط.

**Tech Stack:** Swift 6.1، SwiftUI، SwiftData، XCTest، GitHub Actions (ubuntu + macOS runners)

**Spec:** `docs/superpowers/specs/2026-11-20-ios-sandbox-probe-harness-design.md`

## Global Constraints

- حد أدنى **iOS 17+**؛ واجهة **SwiftUI**؛ تخزين **SwiftData**.
- **لا كتابة كود اختبار**: `SandboxLabApp/SandboxLabApp/Probes/CustomProbe.swift` يبقى قالباً بجسد فارغ وعلامة إدراج.
- **رصد خام فقط**: لا درجة إجمالية، لا فرضية، لا نتيجة متوقعة، لا مطابقة.
- **معرّف الجهاز**: `sysctl hw.machine` (مثل `iPhone16,2`) + إصدار iOS + رقم البناء + **طابع زمني كامل لكل تشغيل**.
- **الخطأ**: `NSError.domain` و `code` و `errno` الخام إن وُجد، مع `localizedDescription` مقروءة.
- لا شبكة، لا أسرار، لا بيانات مستخدمين حقيقية، لا jailbreak/استغلال/تحايل، ولا حالات قد تُسقط التطبيق.
- إضافة حالة = ملف جديد في `Probes/` + سطر واحد في `AppProbeRegistry.swift`؛ **صفر تعديل** على Runner أو UI.
- البناء الرسمي عبر GitHub Actions؛ الحالات لا تعمل على CI وتُشغَّل يدوياً على جهاز حقيقي.
- التزام بعد كل مهمة (المستودع ليس git بعد؛ تهيئته في المهمة 1).

## Review Focus

- **حالة ترمي خطأ POSIX**: يجب حفظ `domain/code/errno` لا النص المترجم فقط → اختبارها في المهمة 2.
- **حالة تُعيد نصاً فارغاً**: يجب إنشاء سجل تشغيل على أي حال، وليس تجاهلها → اختبارها في المهمة 2.
- **غياب بيانات الجهاز على Linux**: يجب الرجوع إلى `unknown` بدل التحطم حتى تعمل اختبارات الحزمة → اختبارها في المهمة 2.
- **Run All مع حالة فاشلة**: يجب الاستمرار بالباقي وحفظ سجل لكل حالة → اختبارها في المهمة 3.
- **إضافة حالة جديدة**: يجب ألا تتطلب تعديل المشغّل أو الواجهة → اختبارها في المهمة 3.

## File Structure

```text
SandboxLabCore/
  Package.swift
  Sources/SandboxLabCore/
    SecurityProbe.swift        // البروتوكول: id, title, category, body()
    ProbeCategory.swift        // enum من 6 حالات + أسماء عرض عربية
    ProbeError.swift           // خطأ يحمل domain/code/errno/message
    Error+ProbeDetails.swift   // استخراج التفاصيل الخام من أي Error
    DeviceInfoProviding.swift  // بروتوكول + UnknownDeviceInfo
    ProbeRunRecord.swift       // DTO قابل للتخزين والمقارنة
    ProbeRunner.swift          // run/runAll + قياس الزمن والتفاصيل
    ProbeRegistry.swift        // حاوية [any SecurityProbe]
    ProbeStoring.swift         // بروتوكول التخزين + InMemoryProbeStore
  Tests/SandboxLabCoreTests/
    ProbeRunnerTests.swift
    ProbeRegistryTests.swift
SandboxLabApp/                 // مشروع Xcode، iOS 17+
  SandboxLabApp/
    App/SandboxLabApp.swift    // entrypoint + ModelContainer
    Registry/AppProbeRegistry.swift  // السطر الواحد للتسجيل
    Runtime/SwiftDataStore.swift     // implements ProbeStoring
    UI/ProbeListView.swift           // قائمة + Run / Run All
    UI/RunDetailView.swift           // النص والخطأ والزمن
    UI/LogListView.swift             // تصفح السجلات
    Probes/CustomProbe.swift         // القالب الفارغ — لا كود اختبار
.github/workflows/ci.yml
```

---

### Task 1: حزمة Core والأنواع الأساسية

**Files:**
- Create: `SandboxLabCore/Package.swift`
- Create: `SandboxLabCore/Sources/SandboxLabCore/{SecurityProbe,ProbeCategory,ProbeError,Error+ProbeDetails,ProbeRunRecord}.swift`
- Create: `SandboxLabCore/Tests/SandboxLabCoreTests/CoreTypesTests.swift`

**Interfaces:**
- Produces: `public protocol SecurityProbe: Sendable { var id: String { get } var title: String { get } var category: ProbeCategory { get } func body() async throws -> String }`
- Produces: `public enum ProbeCategory: String, CaseIterable, Sendable` بالحالات `filesystem, processes, memoryExecution, dylibLoading, network, entitlements` وخاصية `displayName: String` عربية.
- Produces: `public struct ProbeError: Error, Sendable` بخصائص `domain: String`, `code: Int`, `errnoValue: Int32?`, `message: String`.
- Produces: `public extension Error { var probeDetails: (domain: String, code: Int, rawErrno: Int32?, message: String) { get } }` — إذا كان `domain == "POSIX"` يُملأ `rawErrno` من `code`.
- Produces: `public struct ProbeRunRecord: Equatable, Sendable` بخصائص `id: UUID`, `probeID: String`, `categoryRaw: String`, `startedAt: Date`, `durationMs: Int`, `output: String`, `errorDomain: String?`, `errorCode: Int?`, `rawErrno: Int32?`, `errorMessage: String?`, `deviceModel: String`, `osVersion: String`, `buildNumber: String`.

- [ ] **Step 1: هيّئ git واحفظ الحالة الأساسية**

```bash
cd /home/s/Desktop/Rev
git init
git add AGENTS.md docs .opencode/skills
git commit -m "chore: initialize repo with instructions, spec and plan"
```

- [ ] **Step 2: اكتب اختبارات فاشلة للأنواع**

```swift
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
```

- [ ] **Step 3: شغّل الاختبارات وتأكد من الفشل**

Run: `cd SandboxLabCore && swift test`
Expected: FAIL — لا توجد وحدة `SandboxLabCore` بعد.

- [ ] **Step 4: أنشئ `Package.swift` بالضبط**

```swift
// swift-tools-version: 6.1
import PackageDescription
let package = Package(
    name: "SandboxLabCore",
    platforms: [.iOS(.v17)],
    products: [.library(name: "SandboxLabCore", targets: ["SandboxLabCore"])],
    targets: [
        .target(name: "SandboxLabCore"),
        .testTarget(name: "SandboxLabCoreTests", dependencies: ["SandboxLabCore"]),
    ]
)
```

- [ ] **Step 5: نفّذ الأنواع بالتوقيعات أعلاه**

لا كود اختبار داخل الحزمة؛ الأنواع بيانات فقط. `probeDetails` يقرأ `NSError` عبر `self as NSError` ثم يطبّق قاعدة POSIX المذكورة.

- [ ] **Step 6: شغّل الاختبارات وتأكد من النجاح**

Run: `cd SandboxLabCore && swift test`
Expected: PASS — اختباران.

- [ ] **Step 7: التزام**

```bash
git add SandboxLabCore
git commit -m "feat(core): add probe domain types"
```

---

### Task 2: المشغّل وبيانات الجهاز

**Files:**
- Create: `SandboxLabCore/Sources/SandboxLabCore/{DeviceInfoProviding,ProbeRunner}.swift`
- Modify: `SandboxLabCore/Tests/SandboxLabCoreTests/CoreTypesTests.swift`
- Create: `SandboxLabCore/Tests/SandboxLabCoreTests/ProbeRunnerTests.swift`

**Interfaces:**
- Consumes: `SecurityProbe`, `ProbeError`, `Error.probeDetails`, `ProbeRunRecord` من المهمة 1.
- Produces: `public protocol DeviceInfoProviding: Sendable { var hardwareIdentifier: String { get } var osVersion: String { get } var buildNumber: String { get } }` و`public struct UnknownDeviceInfo: DeviceInfoProviding` تُعيد `"unknown"` للخصائص الثلاث.
- Produces: `public struct ProbeRunner: Sendable { public init(); public func run(_ probe: any SecurityProbe, device: any DeviceInfoProviding, now: @escaping () -> Date = Date.init) async -> ProbeRunRecord }`.

- [ ] **Step 1: اكتب اختبارات فاشلة (Review Focus: errno، نص فارغ، غياب الجهاز)**

```swift
struct StubProbe: SecurityProbe {
    let id: String
    let title: String
    let category: ProbeCategory
    let result: Result<String, Error>
    init(id: String = "stub", title: String = "Stub", category: ProbeCategory = .filesystem,
         result: Result<String, Error>) {
        self.id = id; self.title = title; self.category = category; self.result = result
    }
    func body() async throws -> String { try result.get() }
}

final class Clock {
    var dates: [Date]
    init(_ dates: [Date]) { self.dates = dates }
    func next() -> Date { dates.removeFirst() }
}

func testRunPreservesPOSIXErrno() async {
    let probe = StubProbe(result: .failure(
        NSError(domain: "POSIX", code: 13, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
    ))
    let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
    XCTAssertEqual(record.errorDomain, "POSIX")
    XCTAssertEqual(record.errorCode, 13)
    XCTAssertEqual(record.rawErrno, 13)
    XCTAssertEqual(record.errorMessage, "Permission denied")
}

func testRunWithEmptyOutputStillProducesRecord() async {
    let probe = StubProbe(result: .success(""))
    let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
    XCTAssertEqual(record.output, "")
    XCTAssertEqual(record.probeID, "stub")
    XCTAssertNil(record.errorDomain)
}

func testRunUsesUnknownDeviceWhenProviderMissing() async {
    let probe = StubProbe(result: .success("ok"))
    var clock = Clock([Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 0.005)])
    let record = await ProbeRunner().run(probe, device: UnknownDeviceInfo(), now: { clock.next() })
    XCTAssertEqual(record.deviceModel, "unknown")
    XCTAssertEqual(record.durationMs, 5)
}
```

- [ ] **Step 2: شغّل الاختبارات وتأكد من الفشل**

Run: `cd SandboxLabCore && swift test --filter ProbeRunnerTests`
Expected: FAIL — `ProbeRunner` غير موجود.

- [ ] **Step 3: نفّذ `ProbeRunner.run`**

يأخذ `startedAt = now()`، ينفّذ `try await probe.body()` داخل `do/catch`، يحوّل الخطأ عبر `probeDetails`، ثم يحسب `durationMs = Int((now() - startedAt) * 1000)`، ويعيد `ProbeRunRecord` بمعرّف `UUID()` وجهاز من الـ provider. لا يرمي الخطأ أبداً؛ يُسجَّل كتفاصيل داخل `ProbeRunRecord`.

- [ ] **Step 4: شغّل الاختبارات وتأكد من النجاح**

Run: `cd SandboxLabCore && swift test --filter ProbeRunnerTests`
Expected: PASS — 3 اختبارات.

- [ ] **Step 5: التزام**

```bash
git add SandboxLabCore
git commit -m "feat(core): add probe runner with raw error capture"
```

---

### Task 3: السجل والتخزين وحالة التشغيل الجماعي

**Files:**
- Create: `SandboxLabCore/Sources/SandboxLabCore/{ProbeRegistry,ProbeStoring}.swift`
- Create: `SandboxLabCore/Tests/SandboxLabCoreTests/ProbeRegistryTests.swift`
- Modify: `SandboxLabCore/Sources/SandboxLabCore/ProbeRunner.swift` (أضف `runAll`)

**Interfaces:**
- Consumes: `ProbeRunner.run`, `ProbeRunRecord`، `SecurityProbe`.
- Produces: `public struct ProbeRegistry: Sendable { public init(_ probes: [any SecurityProbe]); public let probes: [any SecurityProbe]; public func contains(id: String) -> Bool }`
- Produces: `public protocol ProbeStoring: Sendable { func save(_ record: ProbeRunRecord) async throws; func all() async throws -> [ProbeRunRecord] }` و`public actor InMemoryProbeStore: ProbeStoring { public init(); public func save(_:) async throws; public func all() async throws -> [ProbeRunRecord] }`
- Produces: `ProbeRunner.runAll(_ probes: [any SecurityProbe], device: any DeviceInfoProviding, now: @escaping () -> Date = Date.init) async -> [ProbeRunRecord]`.

- [ ] **Step 1: اكتب اختبارات فاشلة (Review Focus: فشل ضمن Run All، إضافة حالة)**

```swift
func testRunAllContinuesAfterFailure() async {
    let good = StubProbe(result: .success("ok"))
    let bad = StubProbe(id: "bad", result: .failure(NSError(domain: "POSIX", code: 1)))
    let records = await ProbeRunner().runAll([bad, good], device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
    XCTAssertEqual(records.count, 2)
    XCTAssertEqual(records.map(\.probeID), ["bad", "stub"])
}

func testRegistryAcceptsNewProbeWithoutRunnerChanges() {
    let registry = ProbeRegistry([StubProbe(result: .success(""))])
    XCTAssertTrue(registry.contains(id: "stub"))
    XCTAssertFalse(registry.contains(id: "missing"))
}

func testInMemoryStorePersistsRecords() async throws {
    let store = InMemoryProbeStore()
    let record = await ProbeRunner().run(StubProbe(result: .success("x")), device: UnknownDeviceInfo(), now: { Date(timeIntervalSince1970: 0) })
    try await store.save(record)
    let stored = try await store.all()
    XCTAssertEqual(stored, [record])
}
```

- [ ] **Step 2: شغّل الاختبارات وتأكد من الفشل**

Run: `cd SandboxLabCore && swift test --filter ProbeRegistryTests`
Expected: FAIL — الأنواع غير موجودة.

- [ ] **Step 3: نفّذ الأنواع و `runAll`**

`runAll` ينادي `run` لكل حالة بالترتيب ويجمع النتائج؛ لا يرمي الخطأ أبداً لأن `run` يلتقطه داخلياً. `InMemoryProbeStore` يخزّن المصفوفة داخل actor.

- [ ] **Step 4: شغّل الاختبارات وتأكد من النجاح**

Run: `cd SandboxLabCore && swift test`
Expected: PASS — كل الاختبارات.

- [ ] **Step 5: التزام**

```bash
git add SandboxLabCore
git commit -m "feat(core): add registry, store and batch run"
```

---

### Task 4: تطبيق iOS والقالب الفارغ والواجهة

> هذه المهمة تحتاج macOS + Xcode. على البيئة Linux الحالية لا يمكن تشغيلها؛ تُبنى وتُتحقَّق على CI في المهمة 5 أو على جهاز المطوّر.

**Files:**
- Create: `SandboxLabApp/SandboxLabApp.xcodeproj/` (قالب iOS App، SwiftUI، iOS 17+، أضف حزمة `SandboxLabCore` كاعتماد محلي)
- Create: `SandboxLabApp/SandboxLabApp/App/SandboxLabApp.swift`
- Create: `SandboxLabApp/SandboxLabApp/Registry/AppProbeRegistry.swift`
- Create: `SandboxLabApp/SandboxLabApp/Runtime/{DeviceInfo,SwiftDataStore}.swift`
- Create: `SandboxLabApp/SandboxLabApp/UI/{ProbeListView,RunDetailView,LogListView}.swift`
- Create: `SandboxLabApp/SandboxLabApp/Probes/CustomProbe.swift`

**Interfaces:**
- Consumes: `SandboxLabCore` بالكامل من المهام 1-3.
- Produces: `enum AppProbeRegistry { static let probes: [any SecurityProbe] = [CustomProbe()] }` — السطر الوحيد الذي يُعدّل عند إضافة حالة.
- Produces: `struct DeviceInfo: DeviceInfoProviding` يقرأ `sysctl hw.machine` و`UIDevice.current.systemVersion` و`Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")`.
- Produces: `actor SwiftDataStore: ProbeStoring` يحفظ `ProbeRunRecord` في `@Model` بنفس الحقول، ويقرأها مرتبة بالتاريخ.
- Produces: `CustomProbe` مطابق للقالب في الوثيقة، بجسد `body()` فارغ و`return ""` — **لا كود اختبار**.

- [ ] **Step 1: أنشئ مشروع Xcode وأضف الحزمة المحلية**

الإعداد: Deployment Target = iOS 17، Product = SandboxLabApp، Add Package = `../SandboxLabCore`. تأكد أن الـ target يبني قبل أي واجهة.

- [ ] **Step 2: نفّذ `DeviceInfo` و `SwiftDataStore` و `AppProbeRegistry`**

《DeviceInfo》 يستخدم `sysctlbyname("hw.machine", ...)` داخل `#if canImport(UIKit)`؛ أي فشل يُعيد `"unknown"` عبر `UnknownDeviceInfo`. لا توجد أي قيمة حساسة أو شبكية.

- [ ] **Step 3: اكتب القالب الفارغ `Probes/CustomProbe.swift`**

```swift
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
```

- [ ] **Step 4: نفّذ الواجهة**

`ProbeListView` يعرض الحالات مجمّعة حسب `ProbeCategory.displayName` وزرَي «تشغيل» و«تشغيل الكل»؛ عند الضغط يستدعي `ProbeRunner` ثم `SwiftDataStore.save`. `RunDetailView` يعرض النص والخطأ الخام والزمن. `LogListView` يعرض `store.all()` مرتباً تنازلياً بالتاريخ.

- [ ] **Step 5: تحقق البناء على macOS**

Run: `xcodebuild -project SandboxLabApp/SandboxLabApp.xcodeproj -scheme SandboxLabApp -destination 'generic/platform=iOS' -quiet build`
Expected: BUILD SUCCEEDED. على Linux هذه الخطوة غير متاحة؛ الـ CI ينفّذها.

- [ ] **Step 6: التزام**

```bash
git add SandboxLabApp
git commit -m "feat(app): add iOS harness UI and empty probe template"
```

---

### Task 5: GitHub Actions

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `SandboxLabCore/Package.swift` و`SandboxLabApp/SandboxLabApp.xcodeproj`.
- Produces: workflow بـ jobين: `core` على `ubuntu-latest` ينفّذ `swift test` داخل `SandboxLabCore`، و`app` على `macos-14` ينفّذ أمر `xcodebuild` من المهمة 4.

- [ ] **Step 1: اكتب الـ workflow**

```yaml
name: CI
on: [push, pull_request]
jobs:
  core:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: SandboxLabCore
    steps:
      - uses: actions/checkout@v4
      - run: swift test
  app:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild -project SandboxLabApp/SandboxLabApp.xcodeproj -scheme SandboxLabApp -destination 'generic/platform=iOS' -quiet build
```

- [ ] **Step 2: تحقق محلياً من جزء Linux**

Run: `cd SandboxLabCore && swift test`
Expected: PASS.

- [ ] **Step 3: التزام**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add linux core tests and macos iOS build"
```

---

## Self-Review

- **تغطية المواصفات**: رصد خام ✓ (DTO)، قالب فارغ ✓ (المهمة 4)، زر Run/Run All ✓ (المهمة 4)، SwiftData ✓، جهاز/تاريخ/خطأ ✓ (المهمتان 1-2)، لا كود اختبار ✓، CI ✓، إضافة حالة بسطر واحد ✓.
- **الفجوات المعروفة**: تشغيل الحالات على جهاز حقيقي لا يمكن أتمتته؛ مُسلَّم صراحةً للمستخدم في المواصفة.
- **قرار المنفّذ**: فصل Core في Swift Package هو قرار هندسي من «ما يُترك للمنفّذ» في المواصفة، لتمكين TDD حقيقي على Linux.

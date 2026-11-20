# SandboxLab

مختبر أمني لرصد سلوك ساندبوكس iOS على iPhone غير مُخترق (بدون jailbreak).

## المتطلبات
- Swift 6.1 أو أحدث (Xcode 16.3+).
- أداة `xcodegen` لتوليد مشروع Xcode.

## البناء
ملف `.xcodeproj` **غير مُودع عمداً**؛ ولّده محلياً قبل فتح المشروع في Xcode:

```bash
cd SandboxLabApp
xcodegen generate
```

ثم افتح `SandboxLabApp.xcodeproj` في Xcode وابني التطبيق.
**GitHub Actions هو البناء الرسمي** (`.github/workflows/ci.yml`)؛ لا يُفترض بناء محلي على Linux.

## كود الاختبارات (Probes)
الوكيل **لا يكتب** كود الاختبارات. أنت تكتبه بنفسك في:
`SandboxLabApp/SandboxLabApp/Probes/CustomProbe.swift`
داخل الدالة `body()` في القالب الفارغ.

## ملاحظات
- **CI لا يشغّل الاختبارات (probes)**؛ الحالات تُشغَّل يدوياً على جهاز حقيقي.
- النتائج رصد خام (نص/خطأ/زمن) تُحفظ محلياً في SwiftData، بلا درجات أو توقعات مطابقة.

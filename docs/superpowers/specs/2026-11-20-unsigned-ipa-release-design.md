# ملحق تصميم: كود تجريبي + IPA غير موقع في Releases

التاريخ: 2026-11-21 — موافقة مختصرة من المستخدم على الشكل العام عبر أسئلة التوضيح.

## النية
1. كتابة حالة اختبار تجريبية صغيرة داخل القالب — **استثناء صريح** لقاعدة «الوكيل لا يكتب كود اختبار»، ويقتصر على هذه الحالة فقط.
2. أن يبني CI أرشيف IPA غير موقع كاملاً، ويرفعه إلى Releases بالوسم `0.0.0`، مع استبدال الأصل القديم في كل بناء جديد.

## القرارات
- الحالة التجريبية: فحص مسارات الساندبوكس (`Documents`، `tmp`، حزمة التطبيق) + محاولة كتابة ملف مؤقت؛ تُعاد النتائج كنص خام، وأي خطأ يُرمى كـ `ProbeError` يحمل errno الخام. لا UIKit، لا شبكة، لا بيانات مستخدمين، لا تحطم مقصود.
- IPA: يُبنى من `xcodebuild ... -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO`، ثم يُضغط `Payload/SandboxLabApp.app` إلى `SandboxLabApp.ipa`. **غير موقع** — صالح للسيدلودنج عبر AltStore/Sideloadly، وليس للتثبيت المباشر على iPhone عادي.
- Releases: وسم ثابت `0.0.0`، أصل واحدByName `SandboxLabApp.ipa`. عند كل push: إنشاء الريليز إن لم يوجد، حذف الأصل القديم (أو `--clobber`)، ثم رفع الجديد.
- الصلاحيات: `permissions: contents: write` على مستوى الـ workflow، و`GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` لخطوات `gh`.
- لا حلقات تشغيل: الـ workflow يعمل على `push`/`pull_request` فقط، وإنشاء الريليز لا يُطلق pushاً.
- تبقى قواعد AGENTS.md الأخرى سارية: لا أسرار، لا شهادات توقيع، CI يبني فقط ولا يشغّل الحالات على جهاز.

## ملفات متأثرة
- `SandboxLabApp/SandboxLabApp/Probes/CustomProbe.swift` — يُملأ لأول مرة بكود تجريبي.
- `.github/workflows/ci.yml` — إضافة مراحل IPA والريليز والصلاحيات.

## معايير القبول
- `swift test` يبقى 10/10 (Core لم يتغير).
- وظيفة `app` في CI تنجح وتُنتج `SandboxLabApp.ipa` ببنية `Payload/` صحيحة.
- الريليز `0.0.0` يحتوي أصلاً واحداً باسم `SandboxLabApp.ipa` يُستبدل في كل push.
- لا تتغير شهادات التوقيع ولا تُضاف أسرار.

# وصيتي 0.2.1 — إصلاح تحذيرات Flutter

هذا إصدار صيانة للكود المصدر فقط. التعديلات محصورة في أربعة ملفات:

- `lib/screens/entry_form.dart`: إزالة import غير مستخدم.
- `lib/screens/settings_screen.dart`: إحاطة `if (mounted)` بالأقواس.
- `lib/screens/will_screen.dart`: إحاطة `if (mounted)` بالأقواس.
- `lib/widgets/common.dart`: استعمال العنصر الاختياري `trailing?`.

لا يتغير التخزين المشفر أو وظائف التطبيق.

**استبدل الملفات الأربع فقط** إن كان لديك مشروع سابق، واحتفظ بمجلد `android` الذي ولدته سابقًا.

```powershell
cd E:\Android\wasiyyati
flutter analyze
flutter test
flutter doctor -v
flutter emulators
flutter devices
```

إذا كان هناك محاكي موجود لكنه متوقف، شغّله من Device Manager في Android Studio. لإنشاء ملف APK دون هاتف أو محاكي:

```powershell
flutter build apk --release
```

لم يتم تنفيذ Flutter analyzer أو الاختبارات في بيئة إعداد هذا الإصدار؛ يجب التحقق عبر Flutter SDK الموجود على جهازك.

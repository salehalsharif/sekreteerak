# سَكرتيرك — Sekreteerak

> **تكلم… والباقي علينا**

مساعدك الشخصي الصوتي لإدارة المهام والمواعيد والمتابعات باللغة العربية.

## المميزات

- 🎤 إدخال صوتي عربي طبيعي
- 🧠 فهم ذكي للوقت والنية من الكلام
- 📋 تحويل الكلام إلى مهام منظمة
- 🔔 تذكيرات وإشعارات ذكية
- 📊 ملخص يومي صباحي ومسائي
- 👆 واجهة بسيطة وسريعة

## التقنيات

- **Flutter** — واجهة أمامية متعددة المنصات
- **Supabase** — قاعدة بيانات + مصادقة + Edge Functions
- **OpenAI** — تحليل النوايا واستخراج الكيانات
- **Riverpod** — إدارة الحالة

## التشغيل

```bash
# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run

# تشغيل الاختبارات
flutter test
```

## الإعداد

1. أنشئ مشروع [Supabase](https://supabase.com)
2. شغّل `supabase/migrations/001_initial_schema.sql`
3. أضف متغيرات البيئة في `.env`:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   OPENAI_API_KEY=your-openai-key
   ```
4. انشر Edge Functions: `supabase functions deploy`

## الترخيص

ملكية خاصة — جميع الحقوق محفوظة

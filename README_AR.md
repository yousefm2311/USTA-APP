<div align="center">
  <h1>🛠️ مشروع أسطى (Merge Usta)</h1>
  <p><strong>تطبيق متكامل لخدمات الصيانة المنزلية وسوق الحرفيين (الأسطوات)</strong></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="#"><img src="https://img.shields.io/badge/GetX-State_Management-FF6F00?style=for-the-badge" alt="GetX" /></a>
    <a href="https://socket.io"><img src="https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socket.io&logoColor=white" alt="Socket.io" /></a>
    <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" /></a>
  </p>
  
  <p>
    <a href="README.md">🇺🇸 Read in English</a>
  </p>
</div>

---

## 📖 نظرة عامة على المشروع

**مشروع أسطى (Merge Usta)** هو تطبيق شامل مبني بإطار عمل Flutter، مصمم لربط طالبي الخدمات (العملاء) بمقدمي الخدمات المحترفين (الأسطوات). 

بدلاً من إدارة كودين منفصلين، يدمج المشروع بذكاء **تطبيق العميل وتطبيق الأسطى في حزمة برمجية واحدة (Single Codebase)** باستخدام نظام (App Switcher) مخصص عبر GetX. يحتوي التطبيق على محرك Real-Time قوي للدردشة وتتبع الخرائط، نظام متقدم للتعامل مع الوسائط (صور، فيديو، صوت)، ونظام حماية وتحقق من الهوية (KYC) مدعوم بالذكاء الاصطناعي.

---

## ✨ المميزات الأساسية

### 🧑‍💼 واجهة العميل (Customer App)
- **استكشاف الخدمات:** تصفح الأقسام المختلفة، قراءة التقييمات، والبحث عن أفضل الأسطوات.
- **طلبات فورية:** طلب الخدمة، التفاوض على السعر، والحصول على ردود سريعة.
- **تتبع حي على الخريطة:** تتبع موقع الأسطى لحظياً عبر خرائط جوجل (Google Maps).
- **دردشة حية (Real-Time):** محادثات فورية تدعم إرسال الصور، التسجيلات الصوتية، ومقاطع الفيديو.
- **المحفظة والدفع:** محفظة رقمية مدمجة وبوابات دفع إلكترونية آمنة.
- **المفضلة والتقييمات:** حفظ الأسطوات المفضلين وتقييمهم بعد انتهاء الخدمة.

### 👨‍🔧 واجهة الأسطى (Artisan App)
- **لوحة أرباح متكاملة:** إحصائيات دقيقة للأرباح اليومية، الأسبوعية، والشهرية.
- **لوحة طلبات حية:** استقبال إشعارات فورية للطلبات الجديدة في محيط الأسطى.
- **إدارة معرض الأعمال (Portfolio):** رفع صور وفيديوهات للأعمال السابقة لزيادة الموثوقية.
- **توثيق الحساب (KYC):** نظام تحقق من الهوية باستخدام التعرف على الوجه (Google ML Kit).
- **إدارة الحالات:** تغيير حالة التواجد (متاح/غير متاح) وإدارة الطلبات الحالية والمنتهية.

---

## ⚡ التقنيات المستخدمة (Tech Stack)

- **المحرك اللحظي (Real-Time):** استخدام `Socket.io` لإدارة الدردشة والتتبع اللحظي بكفاءة.
- **إدارة الحالة (State Management):** الاعتماد بشكل كامل على `GetX` لإدارة مسارات التطبيق وحالته.
- **الإشعارات (Push Notifications):** ربط متقدم مع `Firebase Cloud Messaging`.
- **الخرائط والمواقع:** الاعتماد على `google_maps_flutter` و `geolocator`.
- **المعالجة والوسائط:** دعم تصوير الفيديو وضغطه، تسجيل الصوت (`just_audio`, `record`).

---

## 🏗️ هيكل المشروع (Architecture)

يعتمد المشروع على هندسة برمجية نظيفة (Clean Architecture) مقسمة حسب الميزات (Feature-first)، تفصل بين تطبيق العميل وتطبيق الأسطى تماماً مع مشاركة الأدوات الأساسية:

```text
lib/
├── app/                      # الأدوات المشتركة ونظام التبديل بين العميل والأسطى
├── Artisan/                  # التطبيق الخاص بالأسطى
│   ├── core/                 # الإعدادات الأساسية للأسطى
│   ├── data/                 # النماذج والاتصال بقواعد البيانات
│   ├── features/             # الميزات (تسجيل، محفظة، طلبات، كشف الوجه)
│   └── main.dart             # نقطة الانطلاق لتطبيق الأسطى
├── Customer/                 # التطبيق الخاص بالعميل
│   ├── core/                 # الإعدادات الأساسية (الـ Sockets، الثيمات)
│   ├── data/                 # النماذج وربط الـ API للعميل
│   ├── features/             # الميزات (الخريطة الحية، الدردشة، الاستكشاف)
│   └── main.dart             # نقطة الانطلاق لتطبيق العميل
└── main.dart                 # نقطة الانطلاق الرئيسية للمشروع المدمج
```

---

## 🚀 دليل التشغيل (Getting Started)

### المتطلبات الأساسية
- تثبيت [Flutter SDK](https://flutter.dev/docs/get-started/install) (إصدار 3.9.2 فما فوق).
- Android Studio أو VS Code.
- مفتاح API نشط لخرائط جوجل (Google Maps API Key).
- ملفات إعدادات Firebase (`google-services.json` و `GoogleService-Info.plist`).

### خطوات التثبيت

1. **استنساخ المشروع (Clone):**
   ```bash
   git clone https://github.com/yousefm2311/Merge-Usta.git
   cd Merge-Usta
   ```

2. **تحميل المكتبات:**
   ```bash
   flutter pub get
   ```

3. **إعدادات البيئة (Environment):**
   تأكد من وضع روابط الـ API والـ Sockets في ملفات الإعدادات الموجودة في `lib/Customer/core/config/` و `lib/Artisan/core/config/`.

4. **تشغيل التطبيق:**
   ```bash
   flutter run
   ```

---

## 📱 لقطات من التطبيق (Screenshots)

*(قم بإضافة صور احترافية لواجهات التطبيق هنا لتوضيح العمل للزوار)*

| واجهة العميل الرئيسية | لوحة تحكم الأسطى | التتبع الحي على الخريطة | الدردشة الفورية |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/customer_home.png" width="200" alt="العميل" /> | <img src="docs/screenshots/artisan_dash.png" width="200" alt="الأسطى" /> | <img src="docs/screenshots/map_tracking.png" width="200" alt="الخريطة" /> | <img src="docs/screenshots/chat_screen.png" width="200" alt="الدردشة" /> |

---

## 🛡️ حقوق الملكية (License)
هذا المشروع خاص ومغلق المصدر (Private). جميع الحقوق محفوظة.

<div align="center">
  <p>بُرمج بكل ❤️ بواسطة <strong>يوسف محمد</strong></p>
</div>

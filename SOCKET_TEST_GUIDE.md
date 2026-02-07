# دليل اختبار Socket.IO للطلبات اللحظية

## 📋 نظرة عامة

هذا الدليل يشرح كيفية التأكد من أن الطلبات تصل لحظيًا (بدون refresh) عبر Socket.IO.

## 🚀 الخطوات السريعة

### 1️⃣ الوصول لصفحة الاختبار

1. افتح التطبيق وسجل دخول كـ **Artisan** (حرفي)
2. من الصفحة الرئيسية، اضغط على زر **"Socket Test"** في Quick Actions
3. ستفتح صفحة الاختبار مع شاشة سوداء للـ logs

### 2️⃣ الاتصال بالسوكت

1. اضغط على زر **"Connect"** (أخضر)
2. راقب الـ logs - يجب أن ترى:
   ```
   📋 Token loaded: eyJhbGciOiJIUzI1NiIsInR5...
   👤 Artisan ID: 67xxxxxxxxxxxxx
   🔄 Attempting to connect socket...
   ✅ Socket connected
   🔌 Socket Status: connected
   ```
3. يجب أن يتحول الشريط العلوي للون **الأخضر** مع كلمة "Connected"

### 3️⃣ الاشتراك في الأحداث

1. اضغط على زر **"Subscribe"** (أزرق)
2. يجب أن ترى في الـ logs:
   ```
   👂 Subscribing to request:new event...
   ✅ Subscribed to all request events
   ```
3. الزر سيتحول للون **البرتقالي** مع كلمة "Listening..."

### 4️⃣ الانضمام للغرف (Rooms)

1. اضغط على زر **"Join Rooms"** (بنفسجي)
2. يجب أن ترى:
   ```
   🚪 Joining rooms...
   ✅ Joined room: artisan:67xxxxxxxxxxxxx
   ✅ Joined room: user:67xxxxxxxxxxxxx
   ```

### 5️⃣ إنشاء طلب تجريبي

1. اضغط على زر **"Create Test Request"** (أخضر فاتح)
2. سيتم إرسال طلب REST API لإنشاء طلب جديد
3. راقب الـ logs - يجب أن ترى:
   ```
   📤 Creating test request via REST API...
   📥 Response Status: 201
   📥 Response Body: {"success":true,"data":{...}}
   ✅ Request created successfully!
   ⏳ Waiting for socket event...
   ```

### 6️⃣ استقبال الحدث اللحظي

إذا كان كل شيء يعمل بشكل صحيح، يجب أن ترى:

```
🆕 NEW REQUEST RECEIVED!
📦 Payload: {"_id":"...","artisanId":"...","serviceType":"Test Service",...}
```

وسيظهر **Dialog** منبثق يحتوي على تفاصيل الطلب!

## 🔍 استكشاف الأخطاء

### ❌ المشكلة: Socket لا يتصل

**الأعراض:**
- الشريط العلوي أحمر
- Log يقول: `⚠️ Skip socket connect: no auth token`

**الحل:**
1. تأكد من تسجيل الدخول بشكل صحيح
2. تحقق من وجود Token في الـ SharedPreferences
3. جرب تسجيل الخروج ثم الدخول مرة أخرى

---

### ❌ المشكلة: Socket متصل لكن لا يستقبل أحداث

**الأعراض:**
- الشريط أخضر "Connected"
- لكن عند إنشاء طلب، لا يظهر حدث `request:new`

**الحلول المحتملة:**

1. **تأكد من الانضمام للغرف:**
   - اضغط على "Join Rooms"
   - تحقق من الـ logs أن الغرف تم الانضمام لها

2. **تحقق من الـ artisanId:**
   - تأكد أن الـ artisanId في الطلب يطابق الـ artisanId المسجل دخوله
   - راجع الـ logs: `👤 Artisan ID: ...`

3. **تحقق من السيرفر:**
   - افتح terminal السيرفر
   - ابحث عن log: `emit request:new to artisan:67xxxxxxxxxxxxx`
   - إذا لم تجده، المشكلة في السيرفر

4. **تحقق من اسم الحدث:**
   - يجب أن يكون `request:new` بالضبط (مش `request:created`)
   - السيرفر والعميل يجب أن يستخدموا نفس الاسم

---

### ❌ المشكلة: الحدث يظهر في السيرفر لكن لا يصل للعميل

**الأعراض:**
- السيرفر يطبع: `emit request:new to artisan:...`
- لكن العميل لا يستقبل شيء

**الحلول:**

1. **تأكد من الاتصال الفعلي:**
   ```
   - راجع الـ logs: هل Socket متصل فعلاً؟
   - جرب Disconnect ثم Connect مرة أخرى
   ```

2. **تأكد من الاشتراك:**
   ```
   - اضغط على "Subscribe" مرة أخرى
   - تحقق من الـ logs: "✅ Subscribed to all request events"
   ```

3. **تحقق من الغرف:**
   ```
   - السيرفر يرسل للغرفة: artisan:67xxxxxxxxxxxxx
   - العميل منضم للغرفة: artisan:67xxxxxxxxxxxxx
   - يجب أن يكونوا متطابقين تمامًا!
   ```

---

## 📊 الأحداث المدعومة

الصفحة تستمع لجميع أحداث الطلبات:

- ✅ `request:new` - طلب جديد
- ✅ `request:accepted` - طلب مقبول
- ✅ `request:rejected` - طلب مرفوض
- ✅ `request:cancelled` - طلب ملغي
- ✅ `request:in_progress` - طلب قيد التنفيذ
- ✅ `request:completed` - طلب مكتمل

## 🔧 معلومات تقنية

### URL الاتصال
```
ws://172.17.100.202:5000/socket.io/?token=YOUR_TOKEN&transport=websocket
```

### الغرف المستخدمة
```
artisan:{artisanId}  - للحرفي
user:{artisanId}     - للمستخدم (اختياري)
```

### REST API للطلبات
```
POST /api/customer/requests
Headers:
  - Content-Type: application/json
  - Authorization: Bearer YOUR_TOKEN
Body:
  {
    "artisanId": "67xxxxxxxxxxxxx",
    "serviceType": "Test Service",
    "description": "Test description",
    "address": "Test Address",
    "scheduledDate": "2025-12-04T09:00:00.000Z"
  }
```

## 📝 ملاحظات مهمة

1. **التوكن يجب أن يكون صالح** - السيرفر يرفض الاتصال لو التوكن منتهي أو غلط
2. **الـ artisanId يجب أن يكون صحيح** - لو أرسلت طلب لحرفي تاني، مش هتستقبله
3. **الاسم الدقيق للحدث مهم** - `request:new` مش `request:created`
4. **الانضمام للغرف ضروري** - بدونه مش هتستقبل أي أحداث

## 🎯 Fallback: REST API

لو السوكت مش شغال، يمكنك استخدام REST API كـ fallback:

```dart
GET /api/artisan/requests/new      // طلبات جديدة
GET /api/artisan/requests/active   // طلبات نشطة
GET /api/artisan/requests/history  // سجل الطلبات
```

يُنصح باستدعاء هذه الـ endpoints بعد الاتصال لضمان تطابق الحالة.

## 🆘 الدعم

إذا واجهت أي مشكلة:

1. **افحص الـ logs** في صفحة الاختبار
2. **افحص logs السيرفر** (console)
3. **تأكد من صحة التوكن** والـ artisanId
4. **جرب Disconnect/Connect** مرة أخرى
5. **تحقق من اتصال الإنترنت**

---

**تم إنشاء هذا الدليل بواسطة Antigravity 🚀**

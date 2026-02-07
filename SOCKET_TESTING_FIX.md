# 🔧 حل مشكلة "Account not found" في اختبار السوكت

## ❌ المشكلة

عند الضغط على زر "Create Test Request" في صفحة اختبار السوكت، تظهر رسالة خطأ:

```
Response Status: 401
Response Body: {"error":"Account not found","message":"Account not found"...}
```

## 🤔 السبب

أنت مسجل دخول كـ **Artisan** (حرفي)، لكن الـ endpoint `/api/customer/requests` يتطلب حساب **Customer** (عميل).

**الحرفي لا يمكنه إنشاء طلبات - فقط العميل يمكنه ذلك!**

## ✅ الحل

تم تعديل صفحة الاختبار لتعرض **تعليمات** بدلاً من محاولة إنشاء طلب تلقائياً.

### الآن عند الضغط على زر "How to Test?"

سيظهر لك:
1. ✅ **Dialog** بالعربية يشرح كيفية الاختبار
2. ✅ **Logs** مفصلة بالخطوات المطلوبة
3. ✅ **Artisan ID** الخاص بك للاستخدام

---

## 🧪 كيف تختبر السوكت بشكل صحيح؟

### الطريقة 1️⃣: استخدام تطبيق العميل (الأسهل)

1. **سجل خروج** من حساب الحرفي
2. **سجل دخول** كـ **Customer** (عميل)
3. **اعمل طلب جديد** من التطبيق
4. **اختر الحرفي** الذي تريد اختباره (استخدم الـ Artisan ID من صفحة الاختبار)
5. **ارجع لحساب الحرفي** وافتح صفحة الاختبار
6. **راقب الـ Logs** - يجب أن ترى: `🆕 NEW REQUEST RECEIVED!`

### الطريقة 2️⃣: استخدام Postman (للمطورين)

#### الخطوات:

1. **احصل على توكن عميل:**
   ```
   POST http://172.17.100.202:5000/api/customer/login
   Body: {
     "email": "customer@example.com",
     "password": "password123"
   }
   ```

2. **احصل على Artisan ID:**
   - من صفحة الاختبار، اضغط "How to Test?"
   - انسخ الـ Artisan ID من الـ Logs

3. **أنشئ طلب جديد:**
   ```
   POST http://172.17.100.202:5000/api/customer/requests
   
   Headers:
   Authorization: Bearer {CUSTOMER_TOKEN}
   Content-Type: application/json
   
   Body:
   {
     "artisanId": "692d72203c28bacd24012911",
     "serviceType": "Plumbing",
     "description": "Fix kitchen sink",
     "address": "123 Main St, Cairo",
     "scheduledDate": "2025-12-04T10:00:00.000Z"
   }
   ```

4. **راقب صفحة الاختبار:**
   - يجب أن ترى في الـ Logs: `🆕 NEW REQUEST RECEIVED!`
   - يجب أن يظهر Dialog مع تفاصيل الطلب

---

## 📋 Checklist قبل الاختبار

تأكد من الخطوات التالية في صفحة الاختبار:

- [ ] ✅ الشريط العلوي **أخضر** (Connected)
- [ ] ✅ ضغطت على زر **"Subscribe"** (الزر برتقالي)
- [ ] ✅ ضغطت على زر **"Join Rooms"**
- [ ] ✅ في الـ Logs: `Joined room: artisan:{id}`
- [ ] ✅ في الـ Logs: `Subscribed to all request events`

---

## 🎯 النتيجة المتوقعة

عند إنشاء طلب من **حساب عميل** لهذا الحرفي، يجب أن ترى:

### في الـ Logs:
```
🆕 NEW REQUEST RECEIVED!
📦 Payload: {"_id":"...","artisanId":"692d72203c28bacd24012911",...}
```

### في الشاشة:
- ✅ Dialog منبثق مع تفاصيل الطلب
- ✅ الطلب يظهر في قائمة الطلبات الجديدة
- ✅ **بدون الحاجة لعمل refresh!** ⚡

---

## 🐛 استكشاف الأخطاء

### المشكلة: لا يظهر حدث في الـ Logs

**الحلول:**
1. تأكد أن الـ artisanId في الطلب **يطابق** الـ artisanId المسجل دخوله
2. تأكد أنك ضغطت "Join Rooms"
3. تأكد أن السوكت متصل (شريط أخضر)
4. راجع سجل السيرفر - هل يطبع `emit request:new to artisan:...`؟

### المشكلة: السيرفر يطبع الحدث لكن العميل لا يستقبله

**الحلول:**
1. تحقق من اسم الحدث في السيرفر: يجب أن يكون `request:new` بالضبط
2. تحقق من اسم الغرفة: `artisan:{artisanId}`
3. أعد الاتصال (Disconnect → Connect)
4. تأكد أنك ضغطت "Subscribe"

---

## 💡 ملاحظات مهمة

1. **الحرفي لا يمكنه إنشاء طلبات** - فقط العميل
2. **التوكن مهم** - استخدم توكن عميل لإنشاء الطلب
3. **Artisan ID يجب أن يطابق** - الطلب يجب أن يكون موجه للحرفي المسجل دخوله
4. **السوكت يجب أن يكون متصل** - تأكد من الشريط الأخضر

---

## 📊 مثال كامل

### السيناريو:
- **Artisan ID:** `692d72203c28bacd24012911`
- **Customer Token:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### الخطوات:

1. **في صفحة الاختبار (Artisan):**
   ```
   ✅ Connect
   ✅ Subscribe
   ✅ Join Rooms
   ✅ How to Test? (للحصول على Artisan ID)
   ```

2. **في Postman (Customer):**
   ```
   POST /api/customer/requests
   Authorization: Bearer {CUSTOMER_TOKEN}
   Body: {
     "artisanId": "692d72203c28bacd24012911",
     "serviceType": "Test",
     "description": "Test",
     "address": "Cairo"
   }
   ```

3. **النتيجة في صفحة الاختبار:**
   ```
   🆕 NEW REQUEST RECEIVED!
   📦 Payload: {...}
   [Dialog يظهر مع التفاصيل]
   ```

---

## 🎉 خلاصة

- ❌ **لا تستخدم** زر "Create Test Request" القديم (تم تعديله)
- ✅ **استخدم** زر "How to Test?" الجديد للحصول على التعليمات
- ✅ **أنشئ الطلب** من حساب عميل أو Postman
- ✅ **راقب** صفحة الاختبار لاستقبال الحدث

**الآن يمكنك اختبار السوكت بشكل صحيح! 🚀**

---

**تم التحديث: 3 ديسمبر 2025**  
**بواسطة: Antigravity 🚀**

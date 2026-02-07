import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_assets.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الشروط والأحكام')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              title: 'Usta',
              subtitle:
                  'باستخدامك للتطبيق، أنت توافق على الشروط والأحكام التالية. الرجاء قراءتها بعناية.',
              cs: cs,
              text: text,
            ),
            const SizedBox(height: 12),

            _SectionCard(
              title: '1) تعريف الخدمة',
              cs: cs,
              text: text,
              bullets: const [
                'Usta منصة تربط بين العملاء والحرفيين لتسهيل طلب الخدمات.',
                'التطبيق يعمل كوسيط تقني لعرض الطلبات وإدارتها وتسهيل التواصل.',
              ],
            ),

            _SectionCard(
              title: '2) إنشاء الحساب واستخدامه',
              cs: cs,
              text: text,
              bullets: const [
                'يلتزم المستخدم بإدخال بيانات صحيحة عند التسجيل.',
                'المستخدم مسؤول عن الحفاظ على سرية بيانات الدخول وعدم مشاركتها.',
                'قد يتم طلب إثباتات إضافية للحرفيين لضمان جودة الخدمة.',
              ],
            ),

            _SectionCard(
              title: '3) قواعد الاستخدام',
              cs: cs,
              text: text,
              bullets: const [
                'يُمنع استخدام التطبيق في أي نشاط مخالف للقانون أو الآداب العامة.',
                'يُمنع إساءة الاستخدام مثل التلاعب بالتقييمات أو إرسال محتوى مسيء.',
                'يحق لإدارة التطبيق اتخاذ إجراءات مناسبة عند رصد مخالفات.',
              ],
            ),

            _SectionCard(
              title: '4) الطلبات والتنفيذ',
              cs: cs,
              text: text,
              bullets: const [
                'العميل مسؤول عن صحة تفاصيل الطلب والعنوان ووسيلة التواصل.',
                'الحرفي مسؤول عن الالتزام بالمواعيد وجودة تنفيذ الخدمة المتفق عليها.',
                'قد تختلف تكلفة الخدمة حسب المعاينة أو تفاصيل إضافية يتم الاتفاق عليها بين الطرفين.',
              ],
            ),

            _SectionCard(
              title: '5) الدفع والرسوم',
              cs: cs,
              text: text,
              bullets: const [
                'قد يوفّر التطبيق وسائل دفع/تحصيل داخل التطبيق أو خارجها حسب نظام التشغيل.',
                'أي رسوم أو عمولات (إن وجدت) سيتم توضيحها داخل التطبيق قبل تأكيد العملية.',
                'أي مدفوعات تتم عبر طرف ثالث تخضع لشروط مزود الخدمة.',
              ],
            ),

            _SectionCard(
              title: '6) الإلغاء والاسترجاع',
              cs: cs,
              text: text,
              bullets: const [
                'يمكن للعميل إلغاء الطلب قبل بدء التنفيذ وفق سياسات الإلغاء داخل التطبيق.',
                'قد تُطبق رسوم إلغاء في بعض الحالات (مثل إلغاء بعد قبول الحرفي أو أثناء الطريق) إذا تم توضيح ذلك.',
                'في حال وجود نزاع، يمكن فتح شكوى من داخل التطبيق وسيتم مراجعتها.',
              ],
            ),

            _SectionCard(
              title: '7) المسؤولية وحدود الضمان',
              cs: cs,
              text: text,
              bullets: const [
                'التطبيق لا يضمن جودة الخدمة بشكل مطلق لأنه وسيط بين الطرفين.',
                'أي اتفاقات نهائية (سعر/مواد/وقت) تتم بين العميل والحرفي.',
                'لن يكون التطبيق مسؤولًا عن أي أضرار غير مباشرة إلا في حدود ما يسمح به القانون.',
              ],
            ),

            _SectionCard(
              title: '8) التقييمات والمراجعات',
              cs: cs,
              text: text,
              bullets: const [
                'يجب أن تكون التقييمات حقيقية وتعكس تجربة فعلية.',
                'يحق للتطبيق إزالة أي تقييمات مسيئة أو وهمية أو مخالفة.',
              ],
            ),

            _SectionCard(
              title: '9) إنهاء أو تعليق الحساب',
              cs: cs,
              text: text,
              bullets: const [
                'يحق للتطبيق تعليق/إغلاق الحساب في حال مخالفة الشروط أو إساءة الاستخدام.',
                'قد يتم تقييد بعض الميزات لحين التحقق أو حل النزاع.',
              ],
            ),

            _SectionCard(
              title: '10) التعديلات على الشروط',
              cs: cs,
              text: text,
              bullets: const [
                'قد نقوم بتحديث هذه الشروط من وقت لآخر.',
                'سيتم إخطار المستخدم بالتغييرات المهمة داخل التطبيق.',
              ],
            ),

            _SectionCard(
              title: '11) القانون المعمول به',
              cs: cs,
              text: text,
              bullets: const ['تخضع هذه الشروط لقوانين جمهورية مصر العربية.'],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التواصل والدعم',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لو عندك أي استفسار بخصوص الشروط والأحكام تواصل معنا من داخل التطبيق عبر الدعم الفني.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.gavel_outlined, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'آخر تحديث: 26 يناير 2026',
                          style: text.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final TextTheme text;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.cs,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.surface],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),

      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              AssetsData.logo,
              scale: 1,
              color: Get.isDarkMode
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final ColorScheme cs;
  final TextTheme text;

  const _SectionCard({
    required this.title,
    required this.bullets,
    required this.cs,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            // style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: text.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


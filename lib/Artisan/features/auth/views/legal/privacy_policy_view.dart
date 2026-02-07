import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              title: 'Usta',
              subtitle:
                  'نحن نحترم خصوصيتك ونلتزم بحماية بياناتك. هذه السياسة توضح كيف نجمع البيانات ونستخدمها ونحميها.',
              cs: cs,
              text: text,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '1) المعلومات التي نجمعها',
              cs: cs,
              text: text,
              bullets: const [
                'الاسم، رقم الهاتف، البريد الإلكتروني عند التسجيل أو التواصل.',
                'الموقع الجغرافي (بموافقتك) لعرض النتائج الأقرب وتحسين التجربة.',
                'بيانات الجهاز والاستخدام مثل نوع الجهاز ونظام التشغيل وعناوين IP.',
                'محتوى المراسلات والبلاغات داخل التطبيق عند استخدام الدردشة أو الشكاوى.',
              ],
            ),
            _SectionCard(
              title: '2) كيفية استخدام المعلومات',
              cs: cs,
              text: text,
              bullets: const [
                'تشغيل خدمات التطبيق وربط العميل بالحرفي بشكل صحيح.',
                'تحسين تجربة المستخدم وإصلاح الأخطاء ورفع جودة الخدمة.',
                'إرسال إشعارات مهمة مرتبطة بالطلبات والحالة والتنبيهات.',
                'تقديم الدعم الفني ومعالجة الشكاوى والنزاعات عند الحاجة.',
              ],
            ),
            _SectionCard(
              title: '3) مشاركة المعلومات',
              cs: cs,
              text: text,
              bullets: const [
                'لا نقوم ببيع بياناتك لأي طرف ثالث.',
                'قد نشارك الحد الأدنى اللازم لتنفيذ الخدمة فقط.',
                'قد نشارك بيانات مع مزودي خدمات تقنيين لتشغيل التطبيق بشكل آمن.',
                'قد نفصح عن بيانات إذا طُلب منا قانونيًا من الجهات المختصة.',
              ],
            ),
            _SectionCard(
              title: '4) حماية البيانات',
              cs: cs,
              text: text,
              bullets: const [
                'نستخدم إجراءات أمنية مناسبة لحماية البيانات من الوصول غير المصرح به.',
                'نراجع الإجراءات الأمنية بشكل دوري ونحسنها عند الحاجة.',
              ],
            ),
            _SectionCard(
              title: '5) حقوقك كمستخدم',
              cs: cs,
              text: text,
              bullets: const [
                'طلب الوصول لبياناتك أو تعديلها.',
                'طلب حذف الحساب أو البيانات وفقًا للمتطلبات القانونية.',
                'إيقاف إذن الموقع من إعدادات الجهاز في أي وقت.',
              ],
            ),
            _SectionCard(
              title: '6) الاحتفاظ بالبيانات',
              cs: cs,
              text: text,
              bullets: const [
                'نحتفظ بالبيانات للمدة اللازمة لتقديم الخدمة وتحسينها أو للالتزام بالقانون.',
                'قد نحتفظ بسجلات معينة لأغراض أمنية أو محاسبية عند الحاجة.',
              ],
            ),
            _SectionCard(
              title: '7) التعديلات على السياسة',
              cs: cs,
              text: text,
              bullets: const [
                'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر.',
                'سنقوم بإشعارك بالتغييرات المهمة داخل التطبيق.',
              ],
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
                    'لو عندك أي استفسار بخصوص الخصوصية تواصل معنا من داخل التطبيق عبر الدعم الفني.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: cs.primary),
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
            child: Icon(Icons.shield_outlined, color: cs.primary),
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
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

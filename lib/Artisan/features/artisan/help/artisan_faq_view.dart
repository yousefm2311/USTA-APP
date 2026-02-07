import 'package:flutter/material.dart';

class ArtisanFAQView extends StatelessWidget {
  const ArtisanFAQView({super.key});

  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);

  final List<Map<String, String>> faq = const [
    {
      "q": "إزاي أعدل بياناتي؟",
      "a": "من صفحة الملف الشخصي تقدر تعدّل الاسم، رقم الهاتف، البريد والصورة.",
    },
    {
      "q": "إزاي أضيف خدمة جديدة؟",
      "a": "من قائمة الخدمات اختار إضافة خدمة، وحدد السعر والوصف.",
    },
    {
      "q": "هل العميل يقدر يشوف موقعي؟",
      "a": "تقدر تتحكم في مشاركة موقعك من الملف الشخصي .",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "الأسئلة الشائعة",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faq.length,
        itemBuilder: (context, index) {
          return _faqItem(faq[index]["q"]!, faq[index]["a"]!, context);
        },
      ),
    );
  }

  Widget _faqItem(String q, String a, context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

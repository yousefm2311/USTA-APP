// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:usta/Customer/features/customer/requests/views/customer_active_requests/customer_write_review_view.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerCompletedRequestDetailsView extends StatelessWidget {
  const CustomerCompletedRequestDetailsView({super.key, this.artisanId});

  final String? artisanId;

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);
  Color get green => const Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          "تفاصيل الطلب".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 20),

          _sectionTitle("تفاصيل الخدمة"),
          _detailCard("نوع الخدمة", "تصليح كهرباء".tr),
          _detailCard("الحالة", "تم الانتهاء".tr, color: green),
          _detailCard("السعر النهائي", "250 جنيه".tr),

          const SizedBox(height: 20),

          _sectionTitle("الحرفي"),
          _artisanInfo(),

          const SizedBox(height: 20),

          _sectionTitle("الوصف"),
          _description(),

          const SizedBox(height: 20),

          _sectionTitle("صور المشكلة"),
          _images(),

          const SizedBox(height: 20),

          _sectionTitle("الموقع"),
          _location(),

          const SizedBox(height: 30),

          _writeReviewButton(),
          const SizedBox(height: 12),

          _reorderButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: green, size: 28),
          const SizedBox(width: 12),
           Expanded(
            child: Text(
              "تم الانتهاء من الطلب بنجاح".tr,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.tr,
      style: const TextStyle(
        fontFamily: "Cairo",
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _detailCard(String title, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            title.tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value.toString().tr,
            style: TextStyle(
              fontFamily: "Cairo",
              color: color ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _artisanInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: blue.withOpacity(0.15),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "محمد أحمد".tr,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "فني كهرباء".tr,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: Colors.amber.shade400),
          const SizedBox(width: 4),
          const Text(
            "4.8",
            style: TextStyle(fontFamily: "Cairo", color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _description() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        "المشكلة كانت انقطاع الكهرباء في جزء من الشقة وتم إصلاحها بالكامل.".tr,
        style: const TextStyle(
          fontFamily: "Cairo",
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _images() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(
          3,
          (i) => Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
              image: const DecorationImage(
                image: AssetImage("assets/images/sample.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _location() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "القاهرة - مدينة نصر".tr,
              style: const TextStyle(
                fontFamily: "Cairo",
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _writeReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          final id = artisanId?.trim() ?? '';
          if (id.isEmpty) {
            AppSnackBar.show('تنبيه'.tr, 'تعذر تحديد الحرفي'.tr);
            return;
          }
          Get.to(() => CustomerWriteReviewView(artisanId: id));
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(
          "كتابة تقييم".tr,
          style: const TextStyle(fontFamily: "Cairo", fontSize: 15),
        ),
      ),
    );
  }

  Widget _reorderButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {},
        icon: const Icon(Icons.restart_alt, color: Colors.white70),
        label: Text(
          "إعادة نفس الطلب".tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}



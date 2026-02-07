import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';

import 'customer_coupon_apply_view.dart';

class CustomerCouponsView extends StatelessWidget {
  const CustomerCouponsView({super.key});

  Color get bg => const Color(0xFF050816);
  // Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CustomerMarketingController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "الكوبونات".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Obx(
        () {
          if (ctrl.loadingCoupons.value && ctrl.coupons.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.couponsError.value.isNotEmpty && ctrl.coupons.isEmpty) {
            return _errorBox(ctrl.couponsError.value,
                onRetry: ctrl.fetchCoupons);
          }

          return RefreshIndicator(
            onRefresh: ctrl.fetchCoupons,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (ctrl.coupons.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      "لا توجد كوبونات متاحة حالياً. اسحب للتحديث أو جرّب لاحقاً."
                          .tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                      ),
                    ),
                  )
                else
                  ...ctrl.coupons.map((c) => _couponItem(context, c)),
                const SizedBox(height: 20),
                _applyButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _couponItem(BuildContext ctx, Map<String, dynamic> coupon) {
    final title =
        coupon['title']?.toString() ?? coupon['code']?.toString() ?? "كوبون".tr;
    final desc = coupon['description']?.toString() ??
        coupon['details']?.toString() ??
        "عرض متاح".tr;
    final discount = coupon['discount']?.toString() ??
        coupon['value']?.toString() ??
        coupon['percent']?.toString();
    final isActive = (coupon['active'] == true) &&
        !_isExpired(coupon['expiresAt'] ?? coupon['expiry']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isActive ? Theme.of(ctx).colorScheme.surface :  Theme.of(ctx).colorScheme.surface.withOpacity(0.6),
        border: Border.all(color: isActive ? Colors.white10 : Colors.redAccent),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer,
            color: isActive ? blue : Colors.redAccent,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 12,
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    "منتهي الصلاحية".tr,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontFamily: "Cairo",
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (discount != null)
            Text(
              discount,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  bool _isExpired(dynamic value) {
    try {
      if (value == null) return false;
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return dt.isBefore(DateTime.now());
      }
    } catch (_) {}
    return false;
  }

  Widget _applyButton(BuildContext ctx) {
    return ElevatedButton(
      onPressed: () {
        Get.to(() => const CustomerCouponApplyView());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        "تطبيق كوبون".tr,
        style: const TextStyle(fontFamily: "Cairo", fontSize: 16),
      ),
    );
  }

  Widget _errorBox(String msg, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 12),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "إعادة المحاولة".tr,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


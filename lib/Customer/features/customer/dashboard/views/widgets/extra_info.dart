import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/dashboard/controllers/customer_dashboard_controller.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/from_dashboard.dart';
import 'package:usta/Customer/features/customer/dashboard/views/widgets/info_tile.dart';

Widget extraInfo(CustomerDashboardController controller, context) {
  final rating = fromDashboard(controller, [
    'avgRating',
    'rating',
    'averageRating',
    'score',
  ]);

  final onlineRaw = fromDashboard(controller, ['online', 'isOnline']);
  final online = _toBool(onlineRaw);

  final lastUpdated = fromDashboard(controller, ['updatedAt', 'timestamp']);

  return Column(
    children: [
      infoTile(
        "التقييم المتوسط".tr,
        rating.isNotEmpty ? rating : '---',
        context,
      ),
      infoTile("الحالة".tr, online ? "متصل".tr : "غير متصل".tr, context),
      infoTile(
        "آخر تحديث".tr,
        lastUpdated.isNotEmpty ? lastUpdated : '---',
        context,
      ),
    ],
  );
}
bool _toBool(String v) {
  final s = v.trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  return false;
}


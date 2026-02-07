import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';

class CustomerRewardsView extends StatelessWidget {
  const CustomerRewardsView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerMarketingController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "مكافآتي".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: Obx(
        () {
          if (controller.loadingRewards.value &&
              controller.rewards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.rewardsError.value.isNotEmpty &&
              controller.rewards.isEmpty) {
            return _errorBox(controller.rewardsError.value,
                onRetry: controller.fetchRewards);
          }
          final rewards = controller.rewards;
          final points = rewards.isNotEmpty
              ? rewards.first['points'] ?? rewards.first['value']
              : 0;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "رصيدي الحالي".tr,
                        style: const TextStyle(
                          fontFamily: "Cairo",
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "@points نقطة".trParams(
                          {'points': points.toString()},
                        ),
                        style: const TextStyle(
                          fontFamily: "Cairo",
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetchRewards,
                    child: ListView(
                      children: rewards.isEmpty
                          ? [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  "لا توجد مكافآت متاحة حالياً.".tr,
                                  style: const TextStyle(
                                    fontFamily: "Cairo",
                                  ),
                                ),
                              )
                            ]
                          : rewards
                              .map((r) => _rewardItem(
                                    r['title']?.toString() ?? 'مكافأة'.tr,
                                    r['cost']?.toString() ??
                                        r['points']?.toString() ??
                                        '0',
                                  ))
                              .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rewardItem(String title, String points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 15,
              ),
            ),
          ),
          Text(
            "@points نقطة".trParams({'points': points}),
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 13,
            ),
          ),
        ],
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


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/connectivity/connectivity_service.dart';

class NoInternetOverlay extends StatelessWidget {
  const NoInternetOverlay({super.key, required this.service});

  final ConnectivityService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 64, color: scheme.error),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد اتصال بالإنترنت'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى التحقق من الاتصال ثم المحاولة مرة أخرى.'.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: () => service.checkNow(force: true),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'إعادة المحاولة'.tr,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


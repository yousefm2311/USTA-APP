import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/app/app_mode_controller.dart';

class ChooseUserTypeView extends StatefulWidget {
  const ChooseUserTypeView({super.key});

  @override
  State<ChooseUserTypeView> createState() => _ChooseUserTypeViewState();
}

class _ChooseUserTypeViewState extends State<ChooseUserTypeView> {
  bool _allowTap = false;

  @override
  void initState() {
    super.initState();
    // Prevent accidental carry-over tap from previous screen.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _allowTap = true;
        });
      }
    });
  }

  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBootstrapping = Get.isRegistered<AppModeController>()
          ? AppModeController.to.isBootstrapping.value
          : false;
      final canInteract = _allowTap && !isBootstrapping;

      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'إختر نوع الحساب',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'تحديد نوع الحساب يساعدنا في تخصيص تجربة الاستخدام لك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
                const SizedBox(height: 50),
                _optionCard(
                  context: context,
                  title: 'حرفي',
                  subtitle: 'لديك مهنة وتريد تقديم خدماتك للمستخدمين',
                  icon: Icons.handyman,
                  enabled: canInteract,
                  onTap: () => AppModeController.to.selectArtisan(force: true),
                ),
                const SizedBox(height: 20),
                _optionCard(
                  context: context,
                  title: 'مستخدم',
                  subtitle: 'تبحث عن حرفي أو خدمة معينة',
                  icon: Icons.person,
                  enabled: canInteract,
                  onTap: () => AppModeController.to.selectCustomer(force: true),
                ),
                if (isBootstrapping) ...[
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _optionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.7,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: blue.withOpacity(.15),
                    child: Icon(icon, color: blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

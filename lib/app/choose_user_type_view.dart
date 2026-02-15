import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/app/app_mode_controller.dart';

class ChooseUserTypeView extends StatefulWidget {
  const ChooseUserTypeView({super.key, this.fallbackMode});

  final AppUserType? fallbackMode;

  @override
  State<ChooseUserTypeView> createState() => _ChooseUserTypeViewState();
}

class _ChooseUserTypeViewState extends State<ChooseUserTypeView> {
  AppModeController? _controller;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppModeController>()) {
      _controller = AppModeController.to;
    }
  }

  Color get blue => const Color(0xFF2563EB);

  Future<void> _handleSelection(
    BuildContext context,
    AppUserType target,
  ) async {
    final controller = _controller;
    if (controller == null) return;
    if (_switching) return;
    setState(() {
      _switching = true;
    });

    if (target == AppUserType.artisan) {
      await controller.selectArtisan(force: true);
    } else if (target == AppUserType.customer) {
      await controller.selectCustomer(force: true);
    }

    if (!mounted) return;
    setState(() {
      _switching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      final canInteract = false;
      return _buildContent(
        context,
        isBootstrapping: false,
        canInteract: canInteract,
      );
    }

    return Obx(() {
      final isBootstrapping = controller.isBootstrapping.value;
      return _buildContent(
        context,
        isBootstrapping: isBootstrapping,
        canInteract: !isBootstrapping && !_switching,
      );
    });
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isBootstrapping,
    required bool canInteract,
  }) {

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'اختر نوع الحساب',
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
                onTap: () => _handleSelection(
                  context,
                  AppUserType.artisan,
                ),
              ),

              const SizedBox(height: 20),

              _optionCard(
                context: context,
                title: 'مستخدم',
                subtitle: 'تبحث عن حرفي أو خدمة معينة',
                icon: Icons.person,
                enabled: canInteract,
                onTap: () => _handleSelection(
                  context,
                  AppUserType.customer,
                ),
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
  }

  Widget _optionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required Future<void> Function() onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (!enabled) return;
              await onTap();
            },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
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

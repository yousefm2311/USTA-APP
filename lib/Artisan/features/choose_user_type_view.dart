import 'package:flutter/material.dart';
import 'package:usta/app/app_mode_controller.dart';

class ChooseUserTypeView extends StatelessWidget {
  const ChooseUserTypeView({super.key});

  Color get bg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);
  Color get blue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Title
              const Text(
                "إختر نوع الحساب",
                style: TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "تحديد نوع الحساب يساعدنا في تخصيص تجربة الاستخدام لك.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: "Cairo", fontSize: 14),
              ),
              const SizedBox(height: 50),

              // Artisan Card
              _optionCard(
                context: context,
                title: "حرفي",
                subtitle: "لديك مهنة وتريد تقديم خدماتك للمستخدمين",
                icon: Icons.handyman,
                onTap: () => AppModeController.to.selectArtisan(force: true),
              ),
              const SizedBox(height: 20),
              // Customer Card
              _optionCard(
                context: context,
                title: "مستخدم",
                subtitle: "تبحث عن حرفي أو خدمة معينة",
                icon: Icons.person,
                onTap: () => AppModeController.to.selectCustomer(force: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    context,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
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
                        fontFamily: "Cairo",
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontFamily: "Cairo", fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

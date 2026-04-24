import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/onboarding/controllers/onboarding_view_model.dart';

import 'onboarding_page.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  Color get primaryBlue => const Color(0xFF2563EB);
  Color get darkBg => const Color(0xFF050816);
  Color get card => const Color(0xFF0B1020);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<OnboardingController>()
        ? Get.find<OnboardingController>()
        : Get.put(OnboardingController());
    final slides = const [
      OnboardingPage(
        title: "مرحباً بك في USTA",
        subtitle: "احجز الحرفيين الموثوقين وتابع كل خطوة بتحديثات مباشرة.",
        image: "assets/images/onboarding_1.png",
      ),
      OnboardingPage(
        title: "اختر الحرفي المناسب",
        subtitle: "تصفح الفئات، قارن التقييمات، وتحدث قبل الحجز.",
        image: "assets/images/onboarding_2.png",
      ),
      OnboardingPage(
        title: "تسعير شفاف",
        subtitle: "أكد التقديرات، المدة الزمنية، والمدفوعات في مكان واحد.",
        image: "assets/images/onboarding_3.png",
      ),
      OnboardingPage(
        title: "جاهز للبدء",
        subtitle: "انتقل بين تجربة العميل والحرفي بحساب واحد.",
        image: "assets/images/onboarding_1.png",
      ),
    ];

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("USTA", style: AppTextStyles.title(context)),
                  TextButton(
                    onPressed: () async {
                      box.write(AppStrings.kOnboardingDoneKey, true);
                      Get.offAllNamed(AppRoutes.login);
                    },
                    child: Text("تخطي", style: AppTextStyles.body(context)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: slides.length,
                itemBuilder: (_, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [card, card.withOpacity(0.7)],
                        ),
                      ),
                      child: slide,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: controller.currentPage.value == index ? 26 : 10,
                    height: 8,
                    decoration: BoxDecoration(
                      color: controller.currentPage.value == index
                          ? primaryBlue
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    if (controller.currentPage.value == slides.length - 1) {
                      box.write(AppStrings.kOnboardingDoneKey, true);
                      Get.offAllNamed(AppRoutes.login);
                    } else {
                      controller.nextPage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    controller.currentPage.value == slides.length - 1
                        ? "ابدأ الآن"
                        : "التالي",
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

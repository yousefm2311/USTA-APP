
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Artisan/features/artisan/onboarding/controllers/onboarding_view_model.dart';
// import 'package:usta/Artisan/features/artisan/onboarding/data/models/onboarding_model.dart';
// import 'package:usta/Artisan/features/artisan/onboarding/views/widgets/onboarding_page_view_item.dart';

// class OnBoardingPageView extends GetView<OnBoardingViewModel> {
//   const OnBoardingPageView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: PageView.builder(
//         physics: const BouncingScrollPhysics(),
//         controller: controller.onboardingController,
//         onPageChanged: (value) {
//           controller.changeSmoothIndicator(value);
//         },
//         allowImplicitScrolling: true, // 🔹 لتسريع التنقل
//         itemBuilder: (context, index) =>
//             OnBoardingPageViewItems(index: index, model: onboardingData[index]),
//         itemCount: onboardingData.length,
//       ),
//     );
//   }
// }


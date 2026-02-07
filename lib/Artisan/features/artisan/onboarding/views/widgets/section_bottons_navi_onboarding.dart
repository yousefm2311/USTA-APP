
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
// import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
// import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
// import 'package:usta/Artisan/core/utils/routes/routes.dart';
// import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';
// import 'package:usta/Artisan/features/artisan/onboarding/controllers/onboarding_view_model.dart';

// class SectionsButtonsNavi extends StatelessWidget {
//   const SectionsButtonsNavi({super.key, required this.controller});

//   final OnBoardingViewModel controller;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         if (controller.currentIndex != 0)
//           TextButton(
//             onPressed: () {
//               controller.onboardingController.previousPage(
//                 duration: const Duration(milliseconds: 750),
//                 curve: Curves.fastLinearToSlowEaseIn,
//               );
//             },
//             child: Text(
//               AppStrings.back,
//               style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                 fontFamily: 'Rubik',
//                 fontSize: 25.0,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//         const Spacer(),
//         CustomMaterialButton(
//           text: controller.isLast ? AppStrings.getStarted : AppStrings.next,
//           onPressed: () {
//             if (controller.isLast) {
//               final prefs = AppPrefs();
//               prefs.setBool(kOnBoardingComplete, true).then((value) {
//                 Get.offAllNamed(AppRoutes.login);
//               });
//             } else {
//               controller.onboardingController.nextPage(
//                 duration: const Duration(milliseconds: 750),
//                 curve: Curves.fastLinearToSlowEaseIn,
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }
// }


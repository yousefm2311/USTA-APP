// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:usta/Artisan/features/artisan/onboarding/data/models/onboarding_model.dart';


// class OnBoardingViewModel extends GetxController {
//   final PageController onboardingController = PageController();
//   int currentIndex = 0;
//   bool isLast = false;

//   void changeSmoothIndicator(int value) {
//     currentIndex = value;
//     isLast = value == onboardingData.length - 1;
//     update(["indicator", "buttons"]);
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  PageController pageController = PageController();
  RxInt currentPage = 0.obs;

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void skip() {
    currentPage.value = 3;
    pageController.jumpToPage(3);
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }
}


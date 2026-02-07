// import 'package:quran_app_android/core/util/assets.dart';



import 'package:usta/Artisan/core/utils/constants/app_assets.dart';

class OnBoardingModel {
  String? image, title, description;

  OnBoardingModel({this.image, this.title, this.description});
}

List<OnBoardingModel> onboardingData = [
  OnBoardingModel(
    title: "تتبع الطلبات  بسهولة",
    description:
        "احصل على طلبك في أي وقت وفي أي مكان  يمكنك طلب أي خدمة",
    image: AssetsData.onboarding_1,
  ),
  OnBoardingModel(
    title: "الوصول إلى الموقع",
    description:
        "نحتاج إلى موقعك للعثور على أقرب الموظفين إليك وتقديم أفضل خدمة ممكنة.",
    image: AssetsData.onboarding_2,
  ),
  OnBoardingModel(
    title: "طرق دفع متعددة",
    description:
        "لدينا خيارات دفع متنوعة. ادفع حسب راحتك.",
    image: AssetsData.onboarding_3,
  ),

];


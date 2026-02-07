import 'package:get/get.dart';
import '../../services/settings/settings_service_v2.dart';


class CustomerBindingV2 extends Bindings {
  static Future<void> ensureInitialized() async {
    // if (!Get.isRegistered<ApiClientV2>()) {
    //   await Get.putAsync<ApiClientV2>(
    //     () async => (await ApiClientV2().init()),
    //     permanent: true,
    //   );
    // }
    // if (!Get.isRegistered<AuthServiceV2>()) {
    //   await Get.putAsync<AuthServiceV2>(
    //     () async => (await AuthServiceV2().init()),
    //     permanent: true,
    //   );
    // }
    if (!Get.isRegistered<SettingsServiceV2>()) {
      await Get.putAsync<SettingsServiceV2>(
        () async => (await SettingsServiceV2().init()),
        permanent: true,
      );
    }
  }

  @override
  void dependencies() {
    // core already ensured
    // repositories
    // Get.lazyPut(() => CustomerAuthRepoV2());
    // Get.lazyPut(() => CustomerProfileRepoV2());
    // Get.lazyPut(() => ExploreRepoV2());
    // Get.lazyPut(() => RequestsRepoV2());
    // Get.lazyPut(() => ReviewsRepoV2());
    // Get.lazyPut(() => FavoritesRepoV2());
    // Get.lazyPut(() => NotificationsRepoV2());
    // Get.lazyPut(() => PaymentsRepoV2());
    // Get.lazyPut(() => ComplaintsRepoV2());
    // Get.lazyPut(() => AnalyticsRepoV2());
    // Get.lazyPut(() => MarketingRepoV2());
    // Get.lazyPut(() => FcmRepoV2());

    // // controllers
    // Get.lazyPut(() => AuthControllerV2());
    // Get.lazyPut(() => ProfileControllerV2());
    // Get.lazyPut(() => ExploreControllerV2());
    // Get.lazyPut(() => RequestsControllerV2());
    // Get.lazyPut(() => ReviewsControllerV2());
    // Get.lazyPut(() => FavoritesControllerV2());
    // Get.lazyPut(() => NotificationsControllerV2());
    // Get.lazyPut(() => WalletControllerV2());
    // Get.lazyPut(() => PaymentsControllerV2());
    // Get.lazyPut(() => ComplaintsControllerV2());
    // Get.lazyPut(() => AnalyticsControllerV2());
    // Get.lazyPut(() => MarketingControllerV2());
    // Get.lazyPut(() => FcmControllerV2());
  }
}

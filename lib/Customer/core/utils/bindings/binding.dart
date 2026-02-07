import 'package:get/get.dart';
import 'package:usta/Customer/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Customer/core/realtime/realtime_controller.dart';
import 'package:usta/Customer/data/providers/customer_api.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/customer/requests/controllers/customer_requests_controller.dart';
import 'package:usta/Customer/features/customer/favorites/controllers/customer_favorites_controller.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';
import 'package:usta/Customer/features/customer/wallet/controllers/customer_wallet_controller.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/marketing/controllers/customer_marketing_controller.dart';
import 'package:usta/Customer/features/customer/payments/controllers/customer_payments_controller.dart';
import 'package:usta/Customer/features/customer/complaints/controllers/customer_complaints_controller.dart';
import 'package:usta/Customer/features/customer/chat/controller/chat_controller.dart';
import 'package:usta/Customer/features/customer/dashboard/controllers/customer_dashboard_controller.dart';
import 'package:usta/Customer/features/customer/chat/services/chat_realtime_service.dart';
import 'package:usta/Customer/features/customer/home/controllers/customer_banners_controller.dart';

class Binding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConnectivityService>(tag: 'customer')) {
      Get.put(ConnectivityService(), permanent: true, tag: 'customer');
    }

    if (!Get.isRegistered<CustomerApi>()) {
      Get.put(CustomerApi(), permanent: true);
    }
    if (!Get.isRegistered<RealtimeController>(tag: 'customer')) {
      Get.put(RealtimeController(), permanent: true, tag: 'customer');
    }
    if (!Get.isRegistered<ChatRealtimeService>(tag: 'customer')) {
      Get.put(ChatRealtimeService(), permanent: true, tag: 'customer');
    }
    if (!Get.isRegistered<CustomerRepository>()) {
      Get.put(CustomerRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.put(AuthController(), permanent: true, tag: 'customer');
    }

    Get.lazyPut<CustomerRequestsController>(
      () => CustomerRequestsController(),
      fenix: true,
    );
    Get.lazyPut<CustomerFavoritesController>(
      () => CustomerFavoritesController(),
      fenix: true,
    );
    Get.lazyPut<CustomerNotificationsController>(
      () => CustomerNotificationsController(),
      fenix: true,
    );
    Get.lazyPut<CustomerWalletController>(
      () => CustomerWalletController(),
      fenix: true,
    );
    Get.lazyPut<CustomerExploreController>(
      () => CustomerExploreController(),
      fenix: true,
    );
    Get.lazyPut<CustomerProfileController>(
      () => CustomerProfileController(),
      fenix: true,
    );
    Get.lazyPut<CustomerMarketingController>(
      () => CustomerMarketingController(),
      fenix: true,
    );
    Get.lazyPut<CustomerPaymentsController>(
      () => CustomerPaymentsController(),
      fenix: true,
    );
    Get.lazyPut<CustomerComplaintsController>(
      () => CustomerComplaintsController(),
      fenix: true,
    );
    Get.lazyPut<ChatController>(
      () => ChatController(),
      tag: 'customer',
      fenix: true,
    );
    Get.lazyPut<CustomerDashboardController>(
      () => CustomerDashboardController(),
      fenix: true,
    );
    Get.lazyPut<CustomerBannersController>(
      () => CustomerBannersController(),
      fenix: true,
    );
  }
}



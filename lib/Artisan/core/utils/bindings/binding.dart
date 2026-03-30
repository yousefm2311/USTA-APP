import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/chat_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/location_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/notifications_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_bindings.dart';
import 'package:usta/Artisan/core/realtime/requests_realtime_service.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/services/connectivity/connectivity_service.dart';
import 'package:usta/Artisan/features/artisan/chat/controllers/chat_controller.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/features/artisan/controllers/artisan_controller.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/verification/artisan_verification_guard_service.dart';
import 'package:usta/Artisan/features/artisan/earnings/controllers/earnings_controller.dart';
import 'package:usta/Artisan/features/artisan/help/controllers/complaints_controller.dart';
import 'package:usta/Artisan/features/artisan/notifications/controllers/notifications_controller.dart';
import 'package:usta/Artisan/features/artisan/onboarding/controllers/onboarding_view_model.dart';
import 'package:usta/Artisan/features/artisan/portfolio/controllers/portfolio_controller.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';
import 'package:usta/Artisan/features/artisan/requests/controllers/artisan_requests_controller.dart';
import 'package:usta/Artisan/features/artisan/reviews/controllers/reviews_controller.dart';
import 'package:usta/Artisan/features/artisan/services/controllers/services_controller.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/locale_controller.dart';
import 'package:usta/Artisan/features/artisan/settings/controllers/theme_controller.dart';
import 'package:usta/Artisan/features/artisan/wallet/controllers/wallet_controller.dart';
import 'package:usta/Artisan/features/auth/controllers/auth_controller.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';

class Binding extends Bindings {
  @override
  void dependencies() {
    RealtimeBindings().dependencies();
    if (!Get.isRegistered<ConnectivityService>(tag: 'artisan')) {
      Get.put(ConnectivityService(), permanent: true, tag: 'artisan');
    }
    if (!Get.isRegistered<RealtimeLifecycleService>()) {
      Get.put(RealtimeLifecycleService(), permanent: true);
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<ApiClient>(tag: 'artisan')) {
      Get.put(ApiClient(), permanent: true, tag: 'artisan');
    }
    if (!Get.isRegistered<ArtisanVerificationGuardService>()) {
      Get.put(ArtisanVerificationGuardService(), permanent: true);
    }
    final lifecycle = Get.find<RealtimeLifecycleService>();
    final requestsService = Get.put<RequestsRealtimeService>(
      RequestsRealtimeService(),
      permanent: true,
    );
    final chatService = Get.put<ChatRealtimeService>(
      ChatRealtimeService(),
      permanent: true,
      tag: 'artisan',
    );
    final locationService = Get.put<LocationRealtimeService>(
      LocationRealtimeService(),
      permanent: true,
    );
    final notificationsService = Get.put<NotificationsRealtimeService>(
      NotificationsRealtimeService(),
      permanent: true,
    );
    final artisanController = Get.put(ArtisanController(), permanent: true);
    lifecycle.register(requestsService);
    lifecycle.register(chatService);
    lifecycle.register(locationService);
    lifecycle.register(notificationsService);
    lifecycle.register(artisanController);
    // Kick off realtime stack once all services are registered (covers the case
    // when the user was already authenticated before bindings ran).
    Future.microtask(() => lifecycle.startAll());
    Get.lazyPut(() => OnboardingController());
    if (!Get.isRegistered<ThemeController>(tag: 'artisan')) {
      Get.lazyPut(() => ThemeController(), tag: 'artisan');
    }
    if (!Get.isRegistered<AuthController>(tag: 'artisan')) {
      Get.put(AuthController(), permanent: true, tag: 'artisan');
    }
    Get.put<ArtisanRequestsController>(
      ArtisanRequestsController(),
      permanent: true,
    );
    Get.lazyPut(() => ProfileController(), fenix: true);
    if (!Get.isRegistered<LocaleController>(tag: 'artisan')) {
      Get.lazyPut(() => LocaleController(), tag: 'artisan', fenix: true);
    }
    Get.lazyPut(() => WalletController(), fenix: true);
    Get.lazyPut(() => NotificationsController(), fenix: true);
    Get.lazyPut(() => ServicesController(), fenix: true);
    Get.lazyPut(() => PortfolioController(), fenix: true);
    Get.lazyPut(() => ArtisanVerificationController(), fenix: true);
    Get.lazyPut(() => ComplaintsController(), fenix: true);
    Get.put<ChatController>(
      ChatController(),
      permanent: true,
      tag: 'artisan',
    );
    Get.lazyPut(() => ReviewsController(), fenix: true);
    Get.lazyPut(() => EarningsController(), fenix: true);
  }
}

import 'package:get/get.dart';
import 'package:usta/Artisan/core/middleware/middleware.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/features/artisan/artisan_active_requests/artisan_active_requests_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_active_requests/artisan_request_details/artisan_request_details_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_active_requests/artisan_request_details/artisan_request_map_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_completed_requests/artisan_completed_requests_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_completed_requests/artisan_request_details_f_completed/artisan_request_details_from_completed_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_customer_requests/artisan_customer_requests_view.dart';
import 'package:usta/Artisan/features/artisan/artisan_customer_requests/artisan_request_details_f_customer/artisan_request_details_from_customer_view.dart';
import 'package:usta/Artisan/features/artisan/bottom_navi_bar/views/bottom_navi.dart';
import 'package:usta/Artisan/features/artisan/chat/views/artisan_chat_list_view.dart';
import 'package:usta/Artisan/features/artisan/earnings/views/artisan_earnings_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_complaint_details_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_complaints_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_help_view.dart';
import 'package:usta/Artisan/features/artisan/help/artisan_new_complaint_view.dart';
import 'package:usta/Artisan/features/artisan/history/artisan_history_view.dart';
import 'package:usta/Artisan/features/artisan/home/views/home_view/home_view.dart';
import 'package:usta/Artisan/features/artisan/notifications/views/artisan_notifications_settings_view.dart';
import 'package:usta/Artisan/features/artisan/notifications/views/artisan_notifications_view.dart';
import 'package:usta/Artisan/features/artisan/onboarding/views/onboarding_view.dart';
import 'package:usta/Artisan/features/artisan/portfolio/views/artisan_portfolio_view.dart';
import 'package:usta/Artisan/features/artisan/profile/views/artisan_profile_edit_view.dart';
import 'package:usta/Artisan/features/artisan/profile/views/profile_view.dart';
import 'package:usta/Artisan/features/artisan/services/views/artisan_services_pricing_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_about_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_change_password_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_language_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_location_settings_view.dart';
import 'package:usta/Artisan/features/artisan/settings/views/artisan_privacy_view.dart';
import 'package:usta/Artisan/features/artisan/show_artisan_new_request/artisan_accept_request_view.dart';
import 'package:usta/Artisan/features/artisan/show_artisan_new_request/show_artisan_new_requests_view.dart';
import 'package:usta/Artisan/features/artisan/wallet/views/artisan_wallet_view.dart';
import 'package:usta/Artisan/features/auth/views/activation_view.dart';
import 'package:usta/Artisan/features/auth/views/forget_password/presentation/views/forgot_password_code.dart';
import 'package:usta/Artisan/features/auth/views/forget_password/presentation/views/forgot_password_view.dart';
import 'package:usta/Artisan/features/auth/views/forget_password/presentation/views/set_new_password.dart';
import 'package:usta/Artisan/features/auth/views/forget_password/presentation/views/success.dart';
import 'package:usta/Artisan/features/auth/views/loign_view.dart';
import 'package:usta/Artisan/features/auth/views/register_view.dart';
import 'package:usta/app/choose_user_type_view.dart';

abstract class AppRoutes {
  static List<GetPage> routes = [
    GetPage(
      name: login,
      page: () => const LoginView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: register,
      page: () => RegisterView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: activation,
      page: () => const ActivationView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: forgetpassword,
      page: () => ForgotPasswordView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: forgetpasswordcode,
      page: () => const ForgotPasswordCode(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: setnewPassword,
      page: () => const SetNewPassword(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: success,
      page: () => const SuccessView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: home,
      page: () => ArtisanHomeView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: bottomNaviBar,
      page: () => ArtisanBottomNaviBar(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),

    GetPage(
      name: profile,
      page: () => const ArtisanProfileView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanProfileEditView,
      page: () => const ArtisanProfileEditView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanNewRequestsView,
      page: () => ShowArtisanNewRequestsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanActiveRequestsView,
      page: () => ArtisanActiveRequestsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),

    GetPage(
      name: artisanRequestDetailsView,
      page: () => ArtisanRequestDetailsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanRequestMapView,
      page: () => const ArtisanRequestMapView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanPortfolioView,
      page: () => ArtisanPortfolioView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),

    GetPage(
      name: artisanServicesPricingView,
      page: () => ArtisanServicesPricingView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),

    GetPage(
      name: artisanWalletView,
      page: () => ArtisanWalletView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanNotificationsView,
      page: () => ArtisanNotificationsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanCustomerRequestsView,
      page: () => ArtisanCustomerRequestsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanAcceptRequestView,
      page: () => ArtisanAcceptRequestView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanEarningsAnalyticsView,
      page: () => const ArtisanEarningsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanCompletedRequestsView,
      page: () => ArtisanCompletedRequestsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanChatListView,
      page: () => ArtisanChatListView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanRequestDetailsFromCustomerView,
      page: () => ArtisanRequestDetailsFromCustomerView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanRequestDetailsFromCompletedView,
      page: () => ArtisanRequestDetailsFromCompletedView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanNotificationSettingsView,
      page: () => const ArtisanNotificationsSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanChangePasswordView,
      page: () => const ArtisanChangePasswordView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanPrivacyView,
      page: () => ArtisanPrivacyView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanHelpView,
      page: () => const ArtisanHelpView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanComplaintsView,
      page: () => const ArtisanComplaintsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanComplaintDetailsView,
      page: () =>
          ArtisanComplaintDetailsView(complaintId: Get.parameters['id'] ?? ''),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanNewComplaintView,
      page: () => const ArtisanNewComplaintView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanLanguageView,
      page: () => ArtisanLanguageView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanAboutView,
      page: () => ArtisanAboutView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: artisanHistoryView,
      page: () => ArtisanHistoryView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: chooseUserTypeView,
      page: () => ChooseUserTypeView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: onboarding,
      page: () => OnboardingView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
      middlewares: [AuthMiddleWare()],
    ),
    GetPage(
      name: artisanLocationSettingsView,
      page: () => const ArtisanLocationSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
  ];

  static const String login = '/login';
  static const String chooseUserTypeView = '/chooseUserTypeView';
  static const String artisanLocationSettingsView =
      '/artisanLocationSettingsView';
  static const String customerBottomNaviBar = '/customerBottomNaviBar';
  static const String customerHomeView = '/customerHomeView';
  static const String artisanHistoryView = '/artisanHistoryView';
  static const String artisanAboutView = '/artisanAboutView';
  static const String artisanLanguageView = '/artisanLanguageView';
  static const String artisanPrivacyView = '/artisanPrivacyView';
  static const String artisanNotificationSettingsView =
      '/artisanNotificationSettingsView';
  static const String artisanChatListView = '/artisanChatListView';
  static const String artisanRequestDetailsFromCompletedView =
      '/artisanRequestDetailsFromCompletedView';
  static const String artisanRequestDetailsFromCustomerView =
      '/artisanRequestDetailsFromCustomerView';
  static const String artisanActiveRequestsView = '/artisanActiveRequestsView';
  static const String artisanHelpView = '/artisanHelpView';
  static const String artisanComplaintsView = '/artisanComplaintsView';
  static const String artisanComplaintDetailsView =
      '/artisanComplaintDetailsView';
  static const String artisanNewComplaintView = '/artisanNewComplaintView';
  static const String artisanCompletedRequestsView =
      '/artisanCompletedRequestsView';
  static const String artisanEarningsAnalyticsView =
      '/artisanEarningsAnalyticsView';
  static const String artisanRequestDetailsView = '/artisanRequestDetailsView';
  static const String artisanRequestMapView = '/artisanRequestMapView';
  static const String artisanNewRequestsView = '/artisanNewRequestsView';
  static const String artisanPortfolioView = '/ArtisanPortfolioView';
  static const String artisanServicesPricingView =
      '/artisanServicesPricingView';
  static const String artisanWalletView = '/artisanWalletView';
  static const String artisanNotificationsView = '/artisanNotificationsView';
  static const String artisanCustomerRequestsView =
      '/artisanCustomerRequestsView';
  static const String artisanAcceptRequestView = '/artisanAcceptRequestView';
  static const String artisanChangePasswordView = '/artisanChangePasswordView';
  static const String register = '/register';
  static const String activation = '/activation';
  static const String onboarding = '/onboarding';
  static const String splash = '/splash';
  static const String forgetpassword = '/forgotpassword';
  static const String forgetpasswordcode = '/forgotpasswordcode';
  static const String setnewPassword = '/setnewPassword';
  static const String success = '/success';
  static const String home = '/home';
  static const String bottomNaviBar = '/bottomNaviBar';
  static const String starttrip = '/starttrip';
  static const String profile = '/profile';
  static const String tripsummary = '/tripsummary';
  static const String triprequest = '/triprequest';
  static const String livetrip = '/livetrip';
  static const String inriderpassenger = '/inriderpassenger';
  static const String notifications = '/notifications';
  static const String updateapp = '/updateapp';
  static const String uploaddocuments = '/uploaddocuments';
  static const String artisanProfileEditView = '/artisanProfileEditView';
  // static const String socketTestPage = '/socketTestPage';
}

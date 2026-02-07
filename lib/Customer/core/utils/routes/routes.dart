import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_constant.dart';

import 'package:usta/Customer/features/auth/views/activation_view.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/forgot_password_code.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/forgot_password_view.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/set_new_password.dart';
import 'package:usta/Customer/features/auth/views/forget_password/presentation/views/success.dart';
import 'package:usta/Customer/features/auth/views/loign_view.dart';
import 'package:usta/Customer/features/auth/views/register_view.dart';
import 'package:usta/Customer/features/customer/customer_bottom_navibar.dart';
import 'package:usta/Customer/features/customer/home/views/customer_home_view.dart';

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
      name: customerHomeView,
      page: () => CustomerHomeView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: customerBottomNaviBar,
      page: () => CustomerBottomNaviBar(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
  ];

  static const String login = '/customer/login';
  static const String chooseUserTypeView = '/customer/ChooseUserTypeView';
  static const String customerBottomNaviBar = '/customer/customerBottomNaviBar';
  static const String customerHomeView = '/customer/customerHomeView';
  static const String register = '/customer/register';
  static const String activation = '/customer/activation';
  static const String onboarding = '/customer/onboarding';
  static const String splash = '/customer/splash';
  static const String forgetpassword = '/customer/forgotpassword';
  static const String forgetpasswordcode = '/customer/forgotpasswordcode';
  static const String setnewPassword = '/customer/setnewPassword';
  static const String success = '/customer/success';
  static const String home = '/customer/home';
  static const String bottomNaviBar = '/customer/bottomNaviBar';
  static const String starttrip = '/customer/starttrip';
  static const String profile = '/customer/profile';
  static const String tripsummary = '/customer/tripsummary';
  static const String triprequest = '/customer/triprequest';
  static const String livetrip = '/customer/livetrip';
  static const String inriderpassenger = '/customer/inriderpassenger';
  static const String notifications = '/customer/notifications';
  static const String updateapp = '/customer/updateapp';
  static const String uploaddocuments = '/customer/uploaddocuments';
}


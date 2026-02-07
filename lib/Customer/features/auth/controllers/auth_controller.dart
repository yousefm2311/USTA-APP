import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:usta/Customer/core/realtime/realtime_controller.dart';

import 'package:usta/Customer/core/services/network/api_exception.dart';

import 'package:usta/Customer/core/services/push/push_notifications_service.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/models/customer_profile.dart';
import 'package:usta/Customer/features/customer/notifications/controllers/customer_notifications_controller.dart';

import 'package:usta/Customer/core/utils/constants/app_colors.dart';

import 'package:usta/Customer/core/utils/constants/app_strings.dart';

import 'package:usta/Customer/core/utils/routes/routes.dart';

import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';
import 'package:usta/app/app_mode_controller.dart';

class AuthController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  final RealtimeController _realtime = Get.find<RealtimeController>(
    tag: 'customer',
  );

  final Rxn<CustomerProfile> profile = Rxn<CustomerProfile>();

  final emailCtrl = TextEditingController();

  final passwordCtrl = TextEditingController();

  final nameCtrl = TextEditingController();

  final phoneCtrl = TextEditingController();

  final codeCtrl = TextEditingController();

  final newPasswordCtrl = TextEditingController();

  static const _contactRequiredMessage =
      'Please enter your email address or phone number';

  static const _nameTooShortMessage =
      'Please enter your full name (at least 3 characters)';

  static const _strongPasswordMessage =
      'Password must be at least 8 characters and include letters and numbers';

  final RxBool isLoading = false.obs;

  final RxBool isRequestInFlight = false.obs;

  static const _wrongAccountMessage =
      'هذا الحساب خاص بالحرفيين. من فضلك ادخل من صفحة الحرفي.';

  bool _isCustomerModeActive() {
    if (!Get.isRegistered<AppModeController>()) return true;
    final controller = AppModeController.to;
    if (controller.isBootstrapping.value) return false;
    return controller.mode.value == AppUserType.customer;
  }

  @override
  void onClose() {
    emailCtrl.dispose();

    passwordCtrl.dispose();

    nameCtrl.dispose();

    phoneCtrl.dispose();

    codeCtrl.dispose();

    newPasswordCtrl.dispose();

    super.onClose();
  }

  Future<void> login() async {
    if (isLoading.value) return;

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    final password = passwordCtrl.text.trim();

    if (!_ensureContactProvided(email, phone)) {
      return;
    }

    if (!_isStrongPassword(password)) {
      _showSnack(_strongPasswordMessage, Colors.redAccent);
      return;
    }

    isLoading.value = true;

    try {
      final result = await _repo.login(
        password: password,

        email: email,

        phone: phone,
      );

      await _handleAuthSuccess(result, navigateHome: true);

      _showSnack(AppStrings.loginSuccess.tr, Colors.green);
    } on _WrongAccountException {
      return;
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (isLoading.value) return;

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    final name = nameCtrl.text.trim();

    final password = passwordCtrl.text.trim();

    if (name.length < 3) {
      _showSnack(_nameTooShortMessage, Colors.redAccent);

      return;
    }

    if (!_ensureContactProvided(email, phone)) {
      return;
    }

    if (!_isStrongPassword(password)) {
      _showSnack(_strongPasswordMessage, Colors.redAccent);

      return;
    }

    isLoading.value = true;

    try {
      final result = await _repo.signup(
        name: name,

        password: password,

        email: email,

        phone: phone,
      );

      await _handleAuthSuccess(result, navigateHome: false);

      _showSnack(AppStrings.createAccountSuccess.tr, Colors.green);

      Get.toNamed(
        AppRoutes.activation,
        arguments: {'email': emailCtrl.text.trim()},
      );
    } on _WrongAccountException {
      return;
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyEmail({String? email, String? phone}) async {
    if (isRequestInFlight.value) return false;

    isRequestInFlight.value = true;

    final payloadEmail = email ?? _nullableText(emailCtrl);

    final payloadPhone = phone ?? _nullableText(phoneCtrl);

    if (!_ensureContactProvided(payloadEmail, payloadPhone)) {
      isRequestInFlight.value = false;

      return false;
    }

    try {
      await _repo.api.verify(
        code: codeCtrl.text.trim(),

        email: payloadEmail,

        phone: payloadPhone,
      );

      _showSnack(AppStrings.verifySuccess.tr, Colors.green);

      Get.offAllNamed(AppRoutes.login);

      return true;
    } catch (e) {
      _handleError(e);

      return false;
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<void> resendVerification() async {
    if (isRequestInFlight.value) return;

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    if (!_ensureContactProvided(email, phone)) {
      return;
    }

    isRequestInFlight.value = true;

    try {
      await _repo.api.resendVerificationCode(email: email, phone: phone);

      _showSnack(AppStrings.verifyCodeSent.tr, AppColors.warning);
    } catch (e) {
      _handleError(e);
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<bool> sendForgotPassword({bool navigateToCode = true}) async {
    if (isRequestInFlight.value) return false;

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    if (!_ensureContactProvided(email, phone)) {
      return false;
    }

    isRequestInFlight.value = true;

    try {
      await _repo.api.forgotPassword(email: email, phone: phone);

      _showSnack(AppStrings.forgotPasswordSent.tr, Colors.green);

      codeCtrl.clear();

      if (navigateToCode) {
        Get.toNamed(AppRoutes.forgetpasswordcode);
      }
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<bool> verifyForgotPasswordCode() async {
    if (isRequestInFlight.value) return false;

    final code = codeCtrl.text.trim();

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    if (!_ensureContactProvided(email, phone)) {
      return false;
    }

    if (code.length < 6) {
      _showSnack(AppStrings.invalidCode.tr, Colors.redAccent);

      return false;
    }

    isRequestInFlight.value = true;
    try {
      final response = await _repo.api.verifyResetCode(
        email: email,
        phone: phone,
        code: code,
      );
      final isValid = _isForgotPasswordCodeValid(response);
      if (!isValid) {
        _showSnack(AppStrings.invalidCode.tr, Colors.redAccent);
        return false;
      }
      _showSnack(AppStrings.verifySuccess.tr, Colors.green);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      isRequestInFlight.value = false;
    }
  }

  bool validateForgotPasswordCode() {
    final code = codeCtrl.text.trim();
    if (code.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      _showSnack(AppStrings.invalidCode.tr, Colors.redAccent);
      return false;
    }
    return true;
  }

  Future<bool> resetPasswordWithCode() async {
    if (isRequestInFlight.value) return false;

    final email = _nullableText(emailCtrl);

    final phone = _nullableText(phoneCtrl);

    if (!_ensureContactProvided(email, phone)) {
      return false;
    }

    final code = codeCtrl.text.trim();

    if (code.length < 6) {
      _showSnack(AppStrings.invalidCode.tr, Colors.redAccent);

      return false;
    }

    final newPassword = passwordCtrl.text.trim();

    if (!_isStrongPassword(newPassword)) {
      _showSnack(_strongPasswordMessage, Colors.redAccent);

      return false;
    }

    isRequestInFlight.value = true;

    try {
      await _repo.api.forgotPassword(
        email: email,

        phone: phone,

        code: code,

        newPassword: newPassword,
      );

      _showSnack(AppStrings.passwordResetSuccess.tr, Colors.green);

      return true;
    } catch (e) {
      _handleError(e);

      return false;
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<void> changePassword({String? current, String? next}) async {
    if (isRequestInFlight.value) return;

    final newPass = next?.trim() ?? newPasswordCtrl.text.trim();

    if (!_isStrongPassword(newPass)) {
      _showSnack(_strongPasswordMessage, Colors.redAccent);

      return;
    }

    isRequestInFlight.value = true;

    try {
      await _repo.api.changePassword(
        currentPassword: current?.trim() ?? passwordCtrl.text.trim(),

        newPassword: newPass,
      );

      _showSnack(AppStrings.passwordUpdated.tr, Colors.green);
    } catch (e) {
      _handleError(e);
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<void> logout({bool remote = true}) async {
    await _storage.clear();
    if (remote) {
      try {
        await _repo.logout();
      } catch (_) {}
    }

    profile.value = null;
    _realtime.disconnect();
    if (!_isCustomerModeActive()) return;
    if (Get.isRegistered<AppModeController>() &&
        AppModeController.to.switcherAttached) {
      await AppModeController.to.resetToChooser();
      return;
    }
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _handleAuthSuccess(
    Map<String, dynamic> response, {
    required bool navigateHome,
  }) async {
    if (_payloadHasKey(response, 'artisan')) {
      await _rejectWrongAccount();
      throw _WrongAccountException();
    }

    CustomerProfile? extractedProfile = _repo.extractProfile(response);
    if (!_payloadHasKey(response, 'customer')) {
      final check = await _verifyCustomerAccount();
      if (check.status == _AccountCheckStatus.wrongAccount) {
        await _rejectWrongAccount();
        throw _WrongAccountException();
      }
      if (check.profile != null) {
        extractedProfile = check.profile;
      }
    }

    if (extractedProfile != null) {
      profile.value = extractedProfile;
      _realtime.joinCustomerRoom(extractedProfile.id);
    }

    final token = _storage.accessToken;
    if (token != null && token.isNotEmpty) {
      _realtime.setAuthToken(token);
    }

    if (Get.isRegistered<CustomerNotificationsController>()) {
      final notifications = Get.find<CustomerNotificationsController>();
      await notifications.ensureRegisteredFcm();
      await notifications.fetchNotifications(force: true);
    }
    if (Get.isRegistered<PushNotificationsService>()) {
      await Get.find<PushNotificationsService>().refreshTokenRegistration();
    }

    if (navigateHome) {
      Get.offAllNamed(AppRoutes.customerBottomNaviBar);
    }
  }

  bool _payloadHasKey(Map<String, dynamic> payload, String key) {
    if (payload.containsKey(key)) return true;
    final data = payload['data'];
    if (data is Map<String, dynamic> && data.containsKey(key)) {
      return true;
    }
    return false;
  }

  Future<_AccountCheckResult> _verifyCustomerAccount() async {
    try {
      final me = await _repo.api.me();
      final profile = _repo.extractProfile(me);
      if (profile != null) {
        return _AccountCheckResult.ok(profile);
      }
      return const _AccountCheckResult.unknown();
    } on ApiException catch (e) {
      final status = e.statusCode ?? 0;
      if (status == 401 || status == 403 || status == 404) {
        return const _AccountCheckResult.wrongAccount();
      }
      return const _AccountCheckResult.unknown();
    } catch (_) {
      return const _AccountCheckResult.unknown();
    }
  }

  Future<void> _rejectWrongAccount() async {
    await _storage.clear();
    profile.value = null;
    _realtime.disconnect();
    _showSnack(_wrongAccountMessage, Colors.redAccent);
  }

  bool _ensureContactProvided(String? email, String? phone) {
    final hasEmail = email != null && email.isNotEmpty;

    final hasPhone = phone != null && phone.isNotEmpty;

    if (hasEmail || hasPhone) {
      return true;
    }

    _showSnack(_contactRequiredMessage, Colors.redAccent);

    return false;
  }

  bool _isStrongPassword(String value) {
    final normalized = value.trim();

    if (normalized.length < 8) return false;

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(normalized);

    final hasDigit = RegExp(r'[0-9]').hasMatch(normalized);

    return hasLetter && hasDigit;
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  void _handleError(Object error) {
    final message = error is ApiException
        ? error.message
        : AppStrings.couldNotCompleteRequest.tr;
    _showSnack(message, Colors.redAccent);
  }

  void _showSnack(String message, Color color) {
    AppSnackBar.show(
      AppStrings.appName.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      duration: const Duration(seconds: 3),
    );
  }

  bool _isForgotPasswordCodeValid(Map<String, dynamic> response) {
    final direct = _extractBoolFlag(response);
    if (direct != null) return direct;
    final message = _extractMessage(response);
    if (message == null || message.trim().isEmpty) {
      return false;
    }
    final normalized = message.toLowerCase();
    if (_looksLikeFailureMessage(normalized)) return false;
    if (_looksLikeSuccessMessage(normalized)) return true;
    return false;
  }

  bool? _extractBoolFlag(Map<String, dynamic> payload) {
    const keys = [
      'success',
      'ok',
      'valid',
      'verified',
      'isValid',
      'isVerified',
    ];
    for (final key in keys) {
      final value = payload[key];
      if (value is bool) return value;
    }
    final nested = payload['data'];
    if (nested is Map<String, dynamic>) {
      for (final key in keys) {
        final value = nested[key];
        if (value is bool) return value;
      }
    }
    return null;
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    final direct = payload['message'] ?? payload['error'] ?? payload['msg'];
    if (direct is String) return direct;
    final nested = payload['data'];
    if (nested is Map<String, dynamic>) {
      final inner = nested['message'] ?? nested['error'] ?? nested['msg'];
      if (inner is String) return inner;
    }
    return null;
  }

  bool _looksLikeFailureMessage(String message) {
    return message.contains('invalid') ||
        message.contains('wrong') ||
        message.contains('expired') ||
        message.contains('incorrect') ||
        message.contains('not valid') ||
        message.contains('failed') ||
        message.contains('error');
  }

  bool _looksLikeSuccessMessage(String message) {
    return message.contains('verified') ||
        message.contains('success') ||
        message.contains('valid') ||
        message.contains('accepted');
  }
}

class _WrongAccountException implements Exception {}

enum _AccountCheckStatus { ok, wrongAccount, unknown }

class _AccountCheckResult {
  final _AccountCheckStatus status;
  final CustomerProfile? profile;

  const _AccountCheckResult._(this.status, this.profile);

  const _AccountCheckResult.ok(CustomerProfile profile)
    : this._(_AccountCheckStatus.ok, profile);

  const _AccountCheckResult.wrongAccount()
    : this._(_AccountCheckStatus.wrongAccount, null);

  const _AccountCheckResult.unknown()
    : this._(_AccountCheckStatus.unknown, null);
}

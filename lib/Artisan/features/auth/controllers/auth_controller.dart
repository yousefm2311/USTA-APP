import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/requests_realtime_service.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/fcm_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class AuthController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final AuthService _authService = Get.find<AuthService>();
  final AppPrefs prefs = AppPrefs();

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final professionCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isRequestInFlight = false.obs;
  final RxBool isForgotPasswordLoading = false.obs;
  final RxBool isCodeVerifying = false.obs;
  final RxBool isResetPasswordLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    professionCtrl.dispose();
    phoneCtrl.dispose();
    codeCtrl.dispose();
    newPasswordCtrl.dispose();
    super.onClose();
  }

  Future<void> login() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await _api.login(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );
      final profile = _extractProfile(response);
      if (!_isAccountActivated(profile)) {
        _showSnack(AppStrings.activateAccount.tr, AppColors.warning);
        Get.offNamed(AppRoutes.activation, arguments: {
          'email': emailCtrl.text.trim(),
        });
        return;
      }
      await _saveTokenFromResponse(response);
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().syncToken();
        await Get.find<FcmService>().flushQueuedTopics();
      }
      await _cacheProfile(response);
      await _handleRealtimeAfterAuth();
      Get.offAllNamed(resolveArtisanVerificationRoute(profile));
      _showSnack(AppStrings.loginSuccess.tr, Colors.green);
    } catch (e) {
      if (e is ApiException) {
        _showSnack(_localizeLoginError(e), Colors.redAccent);
      } else {
        _handleError(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await _api.signup(
        name: nameCtrl.text.trim(),
        profession: professionCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );
      _showSnack(AppStrings.createAccountSuccess.tr, Colors.green);
      Get.toNamed(AppRoutes.activation, arguments: {
        'email': emailCtrl.text.trim(),
      });
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        _showSnack(_localizeApiError(e.message), AppColors.warning);
        Get.offNamed(AppRoutes.activation, arguments: {
          'email': emailCtrl.text.trim(),
        });
        return;
      }
      _handleError(e);
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyEmail({String? email, String? phone}) async {
    if (isRequestInFlight.value) return false;
    isRequestInFlight.value = true;
    try {
      await _api.verifyEmail(
        email: email ?? emailCtrl.text.trim(),
        phone: phone ?? phoneCtrl.text.trim(),
        code: codeCtrl.text.trim(),
      );
      _showSnack(AppStrings.verifySuccess.tr, Colors.green);
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
    isRequestInFlight.value = true;
    try {
      await _api.resendVerification(emailCtrl.text.trim());
      _showSnack(AppStrings.verifyCodeSent.tr, Colors.green);
    } catch (e) {
      _handleError(e);
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<void> sendForgotPassword() async {
    if (isRequestInFlight.value || isForgotPasswordLoading.value) return;
    isRequestInFlight.value = true;
    isForgotPasswordLoading.value = true;
    try {
      await _api.forgotPassword(email: emailCtrl.text.trim());
      _showSnack(AppStrings.forgotPasswordSent.tr, Colors.green);
      Get.toNamed(AppRoutes.forgetpasswordcode);
    } catch (e) {
      _showSnack(AppStrings.forgotPasswordFailed.tr, Colors.redAccent);
    } finally {
      isRequestInFlight.value = false;
      isForgotPasswordLoading.value = false;
    }
  }

  Future<bool> verifyForgotPasswordCode() async {
    if (isRequestInFlight.value || isCodeVerifying.value) return false;
    isRequestInFlight.value = true;
    isCodeVerifying.value = true;
    try {
      await _api.verifyForgotPasswordCode(
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        code: codeCtrl.text.trim(),
      );
      return true;
    } catch (e) {
      if (e is ApiException) {
        _showSnack(_localizeApiError(e.message), Colors.redAccent);
      } else {
        _handleError(e);
      }
      return false;
    } finally {
      isRequestInFlight.value = false;
      isCodeVerifying.value = false;
    }
  }

  Future<bool> resetPasswordWithCode() async {
    if (isRequestInFlight.value || isResetPasswordLoading.value) return false;
    isRequestInFlight.value = true;
    isResetPasswordLoading.value = true;
    try {
      await _api.forgotPassword(
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        code: codeCtrl.text.trim(),
        newPassword: passwordCtrl.text.trim(),
      );
      _showSnack(AppStrings.passwordResetSuccess.tr, Colors.green);
      return true;
    } catch (e) {
      if (e is ApiException) {
        _showSnack(_localizeApiError(e.message), Colors.redAccent);
      } else {
        _handleError(e);
      }
      return false;
    } finally {
      isRequestInFlight.value = false;
      isResetPasswordLoading.value = false;
    }
  }

  Future<void> changePassword({String? current, String? next}) async {
    if (isRequestInFlight.value) return;
    isRequestInFlight.value = true;
    try {
      final currentPassword = current?.trim() ?? passwordCtrl.text.trim();
      final nextPassword = next?.trim() ?? newPasswordCtrl.text.trim();
      if (currentPassword.isEmpty || nextPassword.isEmpty) return;
      await _api.changePassword(
        current: currentPassword,
        next: nextPassword,
      );
      _showSnack(AppStrings.passwordUpdated.tr, Colors.green);
      Get.back();
    } catch (e) {
      _handleError(e);
    } finally {
      isRequestInFlight.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.updateStatus('offline');
    } catch (_) {
      // ignore
    }
    try {
      await _api.toggleOnline(online: false);
    } catch (_) {
      // ignore
    }
    try {
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().syncToken();
        await Get.find<FcmService>().flushQueuedTopics();
      }
    } catch (_) {
      // ignore
    }
    try {
      await _api.logout();
    } catch (_) {
      // Ignore remote logout failure, we still clear locally.
    }
    await prefs.remove(kCachedProfileKey);
    await _authService.handleUnauthorized(skipRefresh: true, forceLogout: true);
  }

  Future<void> _saveTokenFromResponse(dynamic response) async {
    final token = _extractToken(response);
    final refresh = _extractRefreshToken(response);
    if (token != null && token.isNotEmpty) {
      await _authService.saveTokens(accessToken: token, refreshToken: refresh);
      if (Get.isRegistered<RealtimeController>(tag: 'artisan')) {
        Get.find<RealtimeController>(tag: 'artisan').setAuthToken(token);
      }    }
  }

  Future<void> _cacheProfile(dynamic response) async {
    final profile = _extractProfile(response);
    if (profile != null) {
      await prefs.setString(kCachedProfileKey, jsonEncode(profile));
    }
  }

  Map<String, dynamic>? _extractProfile(dynamic response) {
    if (response is! Map<String, dynamic>) return null;
    Map<String, dynamic>? profile;
    profile = _normalizeMap(response['artisan']);
    profile ??= _normalizeMap(response['user']);
    if (profile != null) return profile;

    if (response['data'] is Map<String, dynamic>) {
      final data = response['data'] as Map<String, dynamic>;
      profile = _normalizeMap(data['artisan']);
      profile ??= _normalizeMap(data['user']);
      profile ??= data;
    }

    return profile;
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  bool _isAccountActivated(Map<String, dynamic>? profile) {
    if (profile == null) return true;
    final bool? verified = _recursiveBoolCheck(profile, [
      'isVerified',
      'verified',
      'emailVerified',
      'isEmailVerified',
      'confirmed',
      'is_active',
      'isActive',
      'active',
      'enabled',
    ]);
    if (verified != null) return verified;

    final status = _recursiveStatusCheck(profile);
    if (status != null) {
      final lower = status.toLowerCase();
      if (lower.contains('active') ||
          lower.contains('verified') ||
          lower.contains('enabled') ||
          lower.contains('approved')) {
        return true;
      }
      return false;
    }

    return true;
  }

  String? _recursiveStatusCheck(Map<String, dynamic> profile) {
    final statusFields = ['status', 'accountStatus', 'verificationStatus'];
    for (final field in statusFields) {
      final value = profile[field];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    for (final nestedKey in ['artisan', 'user', 'profile', 'data']) {
      final nested = profile[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedStatus = _recursiveStatusCheck(nested);
        if (nestedStatus != null) return nestedStatus;
      }
    }
    return null;
  }

  bool? _recursiveBoolCheck(
      Map<String, dynamic> profile, Iterable<String> fields) {
    final extracted =
        _extractBoolValue(profile, fields); // check current map first
    if (extracted != null) return extracted;
    for (final nestedKey in ['artisan', 'user', 'profile', 'data']) {
      final nested = profile[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedResult = _recursiveBoolCheck(nested, fields);
        if (nestedResult != null) return nestedResult;
      }
    }
    return null;
  }

  bool? _extractBoolValue(
      Map<String, dynamic> profile, Iterable<String> fields) {
    for (final field in fields) {
      if (!profile.containsKey(field)) continue;
      final value = profile[field];
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes') return true;
        if (lower == 'false' || lower == '0' || lower == 'no') return false;
      }
      if (value is num) return value != 0;
    }
    return null;
  }

  Future<void> _handleRealtimeAfterAuth() async {
    if (Get.isRegistered<RequestsRealtimeService>()) {
      await Get.find<RequestsRealtimeService>()
          .refreshArtisanProfile(forceJoin: true);
    }
  }

  String? _extractToken(dynamic response) {
    if (response is Map<String, dynamic>) {
      final direct =
          response['token'] ??
          response['accessToken'] ??
          response['access_token'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (response['data'] is Map<String, dynamic>) {
        final nested =
            (response['data'] as Map<String, dynamic>)['token'] ??
            (response['data'] as Map<String, dynamic>)['accessToken'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  String? _extractRefreshToken(dynamic response) {
    if (response is Map<String, dynamic>) {
      final direct =
          response['refreshToken'] ?? response['refresh_token'] ?? response['refresh'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (response['data'] is Map<String, dynamic>) {
        final nested =
            (response['data'] as Map<String, dynamic>)['refreshToken'] ??
            (response['data'] as Map<String, dynamic>)['refresh_token'] ??
            (response['data'] as Map<String, dynamic>)['refresh'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  void _handleError(Object error) {
    if (error is ApiException) {
      _showSnack(_localizeApiError(error.message), Colors.redAccent);
    } else {
      _showSnack(AppStrings.couldNotCompleteRequest.tr, Colors.redAccent);
    }
  }

  String _localizeLoginError(ApiException error) {
    final message = error.message;
    final lower = message.toLowerCase();

    bool hasAny(String text, List<String> tokens) =>
        tokens.any((token) => text.contains(token));

    final emailHints = ['email', 'e-mail', 'mail'];
    final userHints = ['user', 'account'];
    final notFoundHints = [
      'not found',
      'does not exist',
      'no account',
      'not registered',
      'unknown',
    ];
    final passwordHints = ['password', 'pass'];
    final invalidHints = ['invalid', 'wrong', 'incorrect', 'mismatch'];

    if (hasAny(lower, notFoundHints) &&
        (hasAny(lower, emailHints) || hasAny(lower, userHints))) {
      return AppStrings.emailNotFound.tr;
    }

    if (hasAny(lower, passwordHints) && hasAny(lower, invalidHints)) {
      return AppStrings.passwordIncorrect.tr;
    }

    if (lower.contains('invalid credential') ||
        lower.contains('invalid credentials')) {
      if (error.statusCode == 404) return AppStrings.emailNotFound.tr;
      return AppStrings.passwordIncorrect.tr;
    }

    if (error.statusCode == 404) return AppStrings.emailNotFound.tr;
    if (error.statusCode == 401 || error.statusCode == 403) {
      return AppStrings.passwordIncorrect.tr;
    }

    return _localizeApiError(message);
  }

  String _localizeApiError(String message) {
    final lower = message.toLowerCase();
    if (_matchesInvalidCode(lower)) {
      return AppStrings.invalidCode.tr;
    }
    if (lower.contains('not approved') || lower.contains('not verified')) {
      return AppStrings.accountNotApproved.tr;
    }
    return message;
  }

  bool _matchesInvalidCode(String text) {
    final codeKeywords = ['code', 'verification', 'token'];
    final invalidKeywords = ['invalid', 'wrong', 'incorrect', 'mismatch', 'expired'];
    final hasCode = codeKeywords.any((keyword) => text.contains(keyword));
    final hasInvalid = invalidKeywords.any((keyword) => text.contains(keyword));
    return hasCode && hasInvalid;
  }

  void _showSnack(String message, Color color) {
    final type = _snackTypeFromColor(color);
    AppSnackBar.show(
      _snackTitle(type),
      message,
      type: type,
    );
  }

  SnackBarType _snackTypeFromColor(Color color) {
    if (color == AppColors.success || color == Colors.green) {
      return SnackBarType.success;
    }
    if (color == AppColors.warning || color == Colors.orange) {
      return SnackBarType.warning;
    }
    if (color == AppColors.error || color == Colors.redAccent) {
      return SnackBarType.error;
    }
    return SnackBarType.info;
  }

  String _snackTitle(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return AppStrings.error.tr;
      case SnackBarType.warning:
        return AppStrings.warning.tr;
      case SnackBarType.success:
        return AppStrings.success.tr;
      case SnackBarType.info:
        return '';
    }
  }
}




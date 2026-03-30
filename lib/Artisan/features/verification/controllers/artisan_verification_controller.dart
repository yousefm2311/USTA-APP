import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/services/database/share_Prefs.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/services/verification/artisan_verification_guard_service.dart';
import 'package:usta/Artisan/core/utils/constants/app_constant.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ArtisanVerificationController extends GetxController {
  ArtisanVerificationController({
    ArtisanApi? api,
    ImagePicker? picker,
    AppPrefs? prefs,
  })  : _api = api ?? ArtisanApi(),
        _picker = picker ?? ImagePicker(),
        _prefs = prefs ?? AppPrefs();

  final ArtisanApi _api;
  final ImagePicker _picker;
  final AppPrefs _prefs;

  final Rxn<XFile> idFront = Rxn<XFile>();
  final Rxn<XFile> idBack = Rxn<XFile>();
  final Rxn<XFile> selfie = Rxn<XFile>();
  final RxMap<String, dynamic> verification = <String, dynamic>{}.obs;
  final RxBool loadingStatus = false.obs;
  final RxBool uploadingIds = false.obs;
  final RxBool uploadingSelfie = false.obs;
  final RxString pendingOperation = ''.obs;

  bool get hasSelectedIds => idFront.value != null && idBack.value != null;
  bool get hasSelectedSelfie => selfie.value != null;
  bool get isVerified => verification['identityVerified'] == true || verification['isVerified'] == true;
  bool get canRetry => verification['canRetry'] != false;
  int get attemptsRemaining => (verification['attemptsRemaining'] as num?)?.toInt() ?? 0;
  int get cooldownRemaining => (verification['cooldownRemaining'] as num?)?.toInt() ?? 0;
  bool get hasIdImages => verification['hasIdImages'] == true;
  String get verificationStatus =>
      (verification['verificationStatus'] ?? 'pending_documents').toString();
  String? get failureReason =>
      verification['rejectionReasonUserSafe']?.toString() ??
      verification['failureReason']?.toString();
  String? get rejectionCategory =>
      verification['rejectionCategory']?.toString();
  String get retryAction =>
      (verification['retryAction'] ?? 'both').toString();
  String get problemType =>
      (verification['problemType'] ?? 'unknown').toString();
  String? get blockedReasonCode =>
      verification['blockedReasonCode']?.toString();
  String? get availableRetryAt =>
      verification['availableRetryAt']?.toString();
  bool get isCooldownActive => cooldownRemaining > 0;

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
  }

  Future<void> pickIdFront(ImageSource source) async {
    idFront.value = await _pickImage(
      source,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  Future<void> pickIdBack(ImageSource source) async {
    idBack.value = await _pickImage(
      source,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  Future<void> pickSelfie(ImageSource source) async {
    selfie.value = await _pickImage(
      source,
      preferredCameraDevice: CameraDevice.front,
    );
  }

  Future<void> refreshStatus() async {
    if (loadingStatus.value) return;
    loadingStatus.value = true;
    try {
      await _prefs.init();
      final response = await _api.getVerificationStatus();
      _consumeVerificationResponse(response);
    } on ApiException catch (error) {
      _showError(_mapApiError(error));
      await _loadCachedProfileFallback();
    } catch (_) {
      await _loadCachedProfileFallback();
    } finally {
      loadingStatus.value = false;
    }
  }

  Future<void> submitIdImages() async {
    final front = idFront.value;
    final back = idBack.value;
    if (front == null || back == null) {
      _showError(AppStrings.kycMissingIdImages.tr);
      return;
    }
    if (uploadingIds.value) return;
    uploadingIds.value = true;
    pendingOperation.value = 'documents';
    try {
      final compressedFront = await _optimizeImage(
        front,
        suffix: 'id-front',
        quality: 90,
        minWidth: 1800,
        minHeight: 1100,
      );
      final compressedBack = await _optimizeImage(
        back,
        suffix: 'id-back',
        quality: 90,
        minWidth: 1800,
        minHeight: 1100,
      );
      final response = await _api.uploadVerificationId(
        idFront: compressedFront,
        idBack: compressedBack,
      );
      _consumeVerificationResponse(response);
      Get.offNamed(AppRoutes.artisanVerificationSelfieView);
      _showSuccess(AppStrings.kycIdUploadSuccess.tr);
    } on ApiException catch (error) {
      _showError(_mapApiError(error));
    } catch (_) {
      _showError(AppStrings.couldNotCompleteRequest.tr);
    } finally {
      uploadingIds.value = false;
      pendingOperation.value = '';
    }
  }

  Future<void> submitSelfie() async {
    final currentSelfie = selfie.value;
    if (currentSelfie == null) {
      _showError(AppStrings.kycMissingSelfie.tr);
      return;
    }
    if (uploadingSelfie.value) return;
    uploadingSelfie.value = true;
    pendingOperation.value = 'selfie';
    try {
      final compressedSelfie = await _optimizeImage(
        currentSelfie,
        suffix: 'selfie',
        quality: 86,
        minWidth: 1280,
        minHeight: 1280,
      );
      final response = await _api.uploadVerificationSelfie(
        selfie: compressedSelfie,
      );
      _consumeVerificationResponse(response);
      Get.offNamed(resolveArtisanVerificationRoute(verification));
      if (isVerified) {
        _showSuccess(AppStrings.kycVerificationPassed.tr);
      } else if (verificationStatus == 'under_review' ||
          verificationStatus == 'selfie_uploaded') {
        _showSuccess(AppStrings.kycUnderReviewMessage.tr);
      } else {
        _showError(failureReason ?? AppStrings.kycVerificationFailed.tr);
      }
    } on ApiException catch (error) {
      _showError(_mapApiError(error));
    } catch (_) {
      _showError(AppStrings.couldNotCompleteRequest.tr);
    } finally {
      uploadingSelfie.value = false;
      pendingOperation.value = '';
    }
  }

  void continueFromStatus() {
    if (isVerified) {
      Get.offAllNamed(AppRoutes.bottomNaviBar);
      return;
    }
    if (verificationStatus == 'under_review' ||
        verificationStatus == 'selfie_uploaded') {
      refreshStatus();
      return;
    }
    continueFromRejected();
  }

  void retryDocuments() {
    if (!_canRetryNow()) return;
    Get.offNamed(AppRoutes.artisanVerificationIdView);
  }

  void retrySelfie() {
    if (!_canRetryNow()) return;
    Get.offNamed(AppRoutes.artisanVerificationSelfieView);
  }

  void continueFromRejected() {
    if (!_canRetryNow()) return;
    switch (retryAction) {
      case 'documents':
        retryDocuments();
        return;
      case 'selfie':
        retrySelfie();
        return;
      case 'both':
      default:
        retryDocuments();
        return;
    }
  }

  Future<XFile?> _pickImage(
    ImageSource source, {
    required CameraDevice preferredCameraDevice,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 88,
        preferredCameraDevice: preferredCameraDevice,
      );
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      if (code.contains('camera_access_denied') ||
          code.contains('photo_access_denied') ||
          message.contains('permission')) {
        _showError(AppStrings.kycCameraPermissionDenied.tr);
      } else {
        _showError(AppStrings.filePickFailed.tr);
      }
      return null;
    } catch (error) {
      _showError(AppStrings.filePickFailed.tr);
      return null;
    }
  }

  bool _canRetryNow() {
    if (!canRetry) {
      _showError(AppStrings.kycAttemptsLimitReached.tr);
      return false;
    }
    if (isCooldownActive) {
      _showError(
        AppStrings.kycRetryCooldown.trParams({
          'seconds': '$cooldownRemaining',
        }),
      );
      return false;
    }
    return true;
  }

  Future<void> _loadCachedProfileFallback() async {
    try {
      final cached = decodeCachedArtisanProfile(_prefs.getString(kCachedProfileKey));
      final cachedVerification = _verificationFromProfile(cached);
      if (cachedVerification != null) {
        verification.assignAll(cachedVerification);
      }
    } catch (_) {
      // No cached fallback available.
    }
  }

  void _consumeVerificationResponse(dynamic response) {
    if (response is! Map<String, dynamic>) return;
    final artisan = _map(response['artisan']);
    final verificationPayload = _map(response['verification']);
    final effectiveVerification = verificationPayload ?? _verificationFromProfile(artisan);
    if (effectiveVerification != null) {
      verification.assignAll(effectiveVerification);
    }
    if (artisan != null) {
      _persistProfile(artisan);
    }
  }

  Map<String, dynamic>? _verificationFromProfile(Map<String, dynamic>? artisan) {
    if (artisan == null) return null;
    final attempts = (artisan['verificationAttempts'] as num?)?.toInt() ?? 0;
    final maxAttempts = (artisan['maxAttempts'] as num?)?.toInt() ?? 3;
    final category = artisan['rejectionCategory']?.toString();
    return {
      'identityVerified': artisan['identityVerified'] ?? false,
      'isVerified': artisan['identityVerified'] ?? false,
      'verificationStatus': artisan['verificationStatus'] ?? 'pending_documents',
      'attempts': attempts,
      'maxAttempts': maxAttempts,
      'failureReason': artisan['verificationFailureReason'],
      'rejectionReasonUserSafe':
          artisan['rejectionReasonUserSafe'] ?? _messageForCategory(category),
      'rejectionReasonInternal': artisan['rejectionReasonInternal'],
      'rejectionCategory': category,
      'confidence': artisan['verificationConfidence'],
      'hasIdImages': artisan['idFrontImage'] != null && artisan['idBackImage'] != null,
      'hasSelfieImage': artisan['selfieImage'] != null,
      'canRetry': attempts < maxAttempts,
      'attemptsRemaining': attempts >= maxAttempts ? 0 : maxAttempts - attempts,
      'cooldownRemaining': 0,
      'availableRetryAt': artisan['availableRetryAt'],
      'retryAction': artisan['retryAction'] ?? 'both',
      'problemType': artisan['problemType'] ?? 'unknown',
      'blockedReasonCode': artisan['blockedReasonCode'],
    };
  }

  Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  Future<void> _persistProfile(Map<String, dynamic> artisan) async {
    await _prefs.init();
    await _prefs.setString(kCachedProfileKey, jsonEncode(artisan));
    if (Get.isRegistered<ArtisanVerificationGuardService>()) {
      await Get.find<ArtisanVerificationGuardService>().syncAndEnforce(
        refreshFromServer: false,
      );
    }
  }

  Future<XFile> _optimizeImage(
    XFile source, {
    required String suffix,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    final originalFile = File(source.path);
    final originalPath = originalFile.path;
    final extension = originalPath.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
    final targetPath = originalPath.replaceFirst(
      RegExp(r'(\.[a-zA-Z0-9]+)?$'),
      '-$suffix-compressed$extension',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      originalPath,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      keepExif: false,
      format: extension == '.png'
          ? CompressFormat.png
          : CompressFormat.jpeg,
    );

    return compressed ?? source;
  }

  void _applyErrorState(ApiException error) {
    final details = error.details;
    if (details == null || details.isEmpty) return;
    verification.addAll({
      if (details['verificationStatus'] != null)
        'verificationStatus': details['verificationStatus'],
      if (details['attemptsRemaining'] != null)
        'attemptsRemaining': details['attemptsRemaining'],
      if (details['maxAttempts'] != null) 'maxAttempts': details['maxAttempts'],
      if (details['cooldownRemaining'] != null)
        'cooldownRemaining': details['cooldownRemaining'],
      if (details['availableRetryAt'] != null)
        'availableRetryAt': details['availableRetryAt'],
      if (details['retryAction'] != null) 'retryAction': details['retryAction'],
      if (details['problemType'] != null) 'problemType': details['problemType'],
      if (details['rejectionCategory'] != null)
        'rejectionCategory': details['rejectionCategory'],
      if (details['rejectionReasonUserSafe'] != null)
        'rejectionReasonUserSafe': details['rejectionReasonUserSafe'],
      if (details['failureReason'] != null)
        'failureReason': details['failureReason'],
      if (details['blockedReasonCode'] != null)
        'blockedReasonCode': details['blockedReasonCode'],
      'canRetry': details['canRetry'] ?? verification['canRetry'],
    });
  }

  String? _messageForCategory(String? category) {
    switch (category) {
      case 'id_blurry':
        return 'صور البطاقة غير واضحة. أعد رفع البطاقة بصورة أوضح.';
      case 'id_invalid':
        return 'تعذر التحقق من البطاقة. تأكد من أن البطاقة صحيحة وكاملة.';
      case 'face_mismatch':
        return 'صورة الوجه لا تطابق بيانات الهوية بشكل كافٍ.';
      case 'face_not_clear':
        return 'صورة السيلفي غير واضحة. التقط سيلفي أوضح.';
      case 'fraud_suspected':
        return 'تعذر إكمال التحقق الآن. إذا استمرت المشكلة تواصل مع الدعم.';
      default:
        return null;
    }
  }

  String rejectionCategoryLabel() {
    switch (rejectionCategory) {
      case 'id_blurry':
        return AppStrings.kycCategoryIdBlurry.tr;
      case 'id_invalid':
        return AppStrings.kycCategoryIdInvalid.tr;
      case 'face_mismatch':
        return AppStrings.kycCategoryFaceMismatch.tr;
      case 'face_not_clear':
        return AppStrings.kycCategoryFaceNotClear.tr;
      case 'fraud_suspected':
        return AppStrings.kycCategoryFraudSuspected.tr;
      default:
        return '';
    }
  }

  String retryAvailabilityLabel() {
    final raw = availableRetryAt;
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _mapApiError(ApiException error) {
    _applyErrorState(error);
    final statusCode = error.statusCode;
    final message = error.message.trim();
    if (statusCode == 403) {
      return AppStrings.kycAccessBlocked.tr;
    }
    if (statusCode == 401) {
      return AppStrings.kycSessionExpired.tr;
    }
    if (statusCode == 409 && error.code == 'kyc_already_approved') {
      return AppStrings.kycAlreadyApproved.tr;
    }
    if (statusCode == 409) {
      return message.isNotEmpty
          ? message
          : AppStrings.couldNotCompleteRequest.tr;
    }
    if (statusCode == 429) {
      return message.isNotEmpty
          ? message
          : AppStrings.kycAttemptsLimitReached.tr;
    }
    if (statusCode == 422) {
      return AppStrings.kycValidationError.tr;
    }
    if (statusCode == 400 &&
        message.toLowerCase().contains('image')) {
      return AppStrings.kycValidationError.tr;
    }
    if (error.code == 'network_timeout') {
      return AppStrings.kycTimeoutError.tr;
    }
    if (error.code == 'network_unavailable') {
      return AppStrings.kycNetworkError.tr;
    }
    return message.isNotEmpty
        ? message
        : AppStrings.couldNotCompleteRequest.tr;
  }

  void _showSuccess(String message) {
    AppSnackBar.show(
      AppStrings.success.tr,
      message,
      type: SnackBarType.success,
    );
  }

  void _showError(String message) {
    AppSnackBar.show(
      AppStrings.error.tr,
      message,
      type: SnackBarType.error,
    );
  }
}

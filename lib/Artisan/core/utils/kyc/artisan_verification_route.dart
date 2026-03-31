import 'dart:convert';

import 'package:usta/Artisan/core/utils/routes/routes.dart';

const Set<String> _artisanPublicRoutes = {
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.activation,
  AppRoutes.forgetpassword,
  AppRoutes.forgetpasswordcode,
  AppRoutes.setnewPassword,
  AppRoutes.success,
  AppRoutes.onboarding,
  AppRoutes.chooseUserTypeView,
};

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String? _extractString(Map<String, dynamic>? map, Iterable<String> keys) {
  if (map == null) return null;
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  for (final nestedKey in ['artisan', 'profile', 'data', 'verification']) {
    final nested = _asMap(map[nestedKey]);
    final nestedValue = _extractString(nested, keys);
    if (nestedValue != null) return nestedValue;
  }
  return null;
}

Map<String, dynamic>? decodeCachedArtisanProfile(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return _asMap(decoded);
  } catch (_) {
    return null;
  }
}

String extractArtisanVerificationStatus(Map<String, dynamic>? profile) {
  final status = _extractString(profile, ['verificationStatus'])?.toLowerCase();
  switch (status) {
    case 'documents_uploaded':
    case 'selfie_uploaded':
    case 'under_review':
    case 'approved':
    case 'rejected':
    case 'pending_documents':
      return status!;
    default:
      return 'pending_documents';
  }
}

String resolveArtisanVerificationRoute(Map<String, dynamic>? profile) {
  final status = extractArtisanVerificationStatus(profile);
  switch (status) {
    case 'documents_uploaded':
      return AppRoutes.artisanVerificationSelfieView;
    case 'selfie_uploaded':
    case 'under_review':
      return AppRoutes.artisanVerificationStatusView;
    case 'approved':
      return AppRoutes.bottomNaviBar;
    case 'rejected':
      return AppRoutes.artisanVerificationRejectedView;
    case 'pending_documents':
    default:
      return AppRoutes.artisanVerificationIdView;
  }
}

bool isArtisanVerificationPublicRoute(String? route) {
  if (route == null || route.isEmpty) return true;
  return _artisanPublicRoutes.contains(route);
}

bool isArtisanRouteAllowedForVerificationStatus(
  String? route,
  Map<String, dynamic>? profile,
) {
  if (route == null || route.isEmpty) return true;
  if (isArtisanVerificationPublicRoute(route)) return true;

  final status = extractArtisanVerificationStatus(profile);
  if (status == 'approved') return true;

  switch (status) {
    case 'pending_documents':
      return route == AppRoutes.artisanVerificationIdView ||
          route == AppRoutes.artisanVerificationCameraView ||
          route == AppRoutes.artisanVerificationDocumentCropView;
    case 'documents_uploaded':
      return route == AppRoutes.artisanVerificationIdView ||
          route == AppRoutes.artisanVerificationCameraView ||
          route == AppRoutes.artisanVerificationDocumentCropView ||
          route == AppRoutes.artisanVerificationSelfieView;
    case 'selfie_uploaded':
    case 'under_review':
      return route == AppRoutes.artisanVerificationStatusView;
    case 'rejected':
      return route == AppRoutes.artisanVerificationRejectedView ||
          route == AppRoutes.artisanVerificationIdView ||
          route == AppRoutes.artisanVerificationCameraView ||
          route == AppRoutes.artisanVerificationDocumentCropView ||
          route == AppRoutes.artisanVerificationSelfieView;
    default:
      return false;
  }
}

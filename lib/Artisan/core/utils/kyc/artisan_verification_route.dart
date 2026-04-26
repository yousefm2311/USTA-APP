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
  // Artisan identity verification is currently disabled product-wide.
  // Treat every artisan as allowed so stale cached KYC states never block entry.
  return 'approved';
}

String resolveArtisanVerificationRoute(Map<String, dynamic>? profile) {
  // KYC is disabled, so an authenticated artisan always lands in the main app.
  return AppRoutes.bottomNaviBar;
}

bool isArtisanVerificationPublicRoute(String? route) {
  if (route == null || route.isEmpty) return true;
  return _artisanPublicRoutes.contains(route);
}

bool isArtisanRouteAllowedForVerificationStatus(
  String? route,
  Map<String, dynamic>? profile,
) {
  // With KYC disabled, no artisan route should be blocked by verification state.
  return true;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';

void main() {
  test('verified artisan goes to home route', () {
    final route = resolveArtisanVerificationRoute({
      'verificationStatus': 'approved',
    });

    expect(route, AppRoutes.bottomNaviBar);
  });

  test('artisan with no documents goes to ID upload route', () {
    final route = resolveArtisanVerificationRoute({
      'verificationStatus': 'pending_documents',
    });

    expect(route, AppRoutes.artisanVerificationIdView);
  });

  test('artisan with uploaded IDs goes to selfie route', () {
    final route = resolveArtisanVerificationRoute({
      'verificationStatus': 'documents_uploaded',
    });

    expect(route, AppRoutes.artisanVerificationSelfieView);
  });

  test('artisan under review goes to status route', () {
    final route = resolveArtisanVerificationRoute({
      'verificationStatus': 'under_review',
    });

    expect(route, AppRoutes.artisanVerificationStatusView);
  });

  test('rejected artisan goes to rejected route', () {
    final route = resolveArtisanVerificationRoute({
      'verificationStatus': 'rejected',
    });

    expect(route, AppRoutes.artisanVerificationRejectedView);
  });

  test('cached profile decoder ignores invalid json safely', () {
    expect(decodeCachedArtisanProfile('{broken-json'), isNull);
  });
}

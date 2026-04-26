import 'package:flutter_test/flutter_test.dart';
import 'package:usta/Artisan/core/utils/kyc/artisan_verification_route.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';

void main() {
  test('KYC-disabled resolver always sends artisans to the main app', () {
    final statuses = [
      'approved',
      'pending_documents',
      'documents_uploaded',
      'under_review',
      'rejected',
      null,
    ];

    for (final status in statuses) {
      final profile = status == null ? null : {'verificationStatus': status};
      expect(resolveArtisanVerificationRoute(profile), AppRoutes.bottomNaviBar);
      expect(
        isArtisanRouteAllowedForVerificationStatus('/any-route', profile),
        isTrue,
      );
    }
  });

  test('cached profile decoder ignores invalid json safely', () {
    expect(decodeCachedArtisanProfile('{broken-json'), isNull);
  });
}

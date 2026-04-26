import 'package:get/get.dart';

class ArtisanVerificationGuardService extends GetxService {
  Future<void> syncAndEnforce({
    bool refreshFromServer = false,
    String? currentRoute,
  }) async {
    // KYC is disabled product-wide. Keep this service as a no-op so older
    // call sites remain safe while no route or backend check blocks artisans.
  }
}

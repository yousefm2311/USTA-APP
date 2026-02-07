import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';

/// Contract for services that operate over the authenticated realtime stack.
abstract class RealtimeAwareService {
  bool get isStarted;
  Future<void> start();
  Future<void> stop();
}

class RealtimeLifecycleService extends GetxService {
  final List<RealtimeAwareService> _services = [];

  /// Register a service to be started/stopped together.
  void register(RealtimeAwareService service) {
    if (_services.contains(service)) return;
    _services.add(service);
    final bool authedArtisan = Get.isRegistered<AuthService>() &&
        Get.find<AuthService>().isAuthenticated;
    // final bool authedCustomer = Get.isRegistered<AuthServiceV2>() &&
    //     Get.find<AuthServiceV2>().isAuthenticated;
    // if ((authedArtisan || authedCustomer) && !service.isStarted) {
    //   service.start();
    // }
  }

  Future<void> startAll() async {
    final bool isAuthedArtisan = Get.isRegistered<AuthService>() &&
        Get.find<AuthService>().isAuthenticated;
    // final bool isAuthedCustomer = Get.isRegistered<AuthServiceV2>() &&
    //     Get.find<AuthServiceV2>().isAuthenticated;
    // if (!isAuthedArtisan && !isAuthedCustomer) {
    //   return; // skip starting realtime stack when no one is authenticated
    // }
    for (final service in _services) {
      if (!service.isStarted) {
        await service.start();
      }
    }
  }

  Future<void> stopAll() async {
    for (final service in _services) {
      if (service.isStarted) {
        await service.stop();
      }
    }
  }
}


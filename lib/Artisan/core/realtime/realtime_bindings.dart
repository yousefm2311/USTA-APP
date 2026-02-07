import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/services/connectivity/connectivity_service.dart';

class RealtimeBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ConnectivityService>(tag: 'artisan')) {
      Get.put<ConnectivityService>(
        ConnectivityService(),
        permanent: true,
        tag: 'artisan',
      );
    }
    if (!Get.isRegistered<SocketService>()) {
      Get.put<SocketService>(SocketService(), permanent: true);
    }
    Get.put<RealtimeController>(
      RealtimeController(),
      permanent: true,
      tag: 'artisan',
    );
  }
}


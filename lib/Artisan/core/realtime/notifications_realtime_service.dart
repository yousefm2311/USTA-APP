import 'dart:async';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/realtime/events.dart';
import 'package:usta/Artisan/core/realtime/realtime_controller.dart';
import 'package:usta/Artisan/core/realtime/realtime_lifecycle_service.dart';
import 'package:usta/Artisan/core/realtime/socket_service.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/notifications/controllers/notifications_controller.dart';

class NotificationsRealtimeService extends GetxService
    implements RealtimeAwareService {
  final RealtimeController _rt = Get.find<RealtimeController>(tag: 'artisan');
  NotificationsController? _notificationsController;
  bool _started = false;
  bool _eventsRegistered = false;
  StreamSubscription<SocketStatus>? _statusSub;

  @override
  bool get isStarted => _started;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _statusSub?.cancel();
    _statusSub = _rt.status.stream.listen((status) {
      if (status == SocketStatus.connected) {
        _registerEvents();
      } else {
        _unregisterEvents();
      }
    });
    if (_rt.status.value == SocketStatus.connected) {
      _registerEvents();
    }
  }

  @override
  Future<void> stop() async {
    _started = false;
    await _statusSub?.cancel();
    _statusSub = null;
    _unregisterEvents();
  }

  void _registerEvents() {
    if (_eventsRegistered) return;
    _rt.onEvent(RealtimeEvents.notificationNew, (data) {
      if (!_started) return;
      _handleIncoming(data, showBanner: true);
    });
    _rt.onEvent(RealtimeEvents.notificationUpdate, (data) {
      if (!_started) return;
      _handleIncoming(data);
    });
    _eventsRegistered = true;
  }

  void _unregisterEvents() {
    if (!_eventsRegistered) return;
    _rt.offEvent(RealtimeEvents.notificationNew);
    _rt.offEvent(RealtimeEvents.notificationUpdate);
    _eventsRegistered = false;
  }

  void _handleIncoming(dynamic payload, {bool showBanner = false}) {
    if (!_started) return;
    _ensureController();
    if (payload is! Map) return;
    final notification = payload.cast<String, dynamic>();
    _notificationsController?.notifications.insert(0, notification);
    if (showBanner) {
      _showBanner(notification);
    }
  }

  void _showBanner(Map<String, dynamic> notification) {
    final ctx = Get.context;
    if (ctx == null) return;
    final title = notification['title']?.toString() ??
        AppStrings.notifications.tr;
    final body = notification['body']?.toString() ?? '';
    AppSnackBar.show(
      title,
      body,
      type: SnackBarType.info,
      duration: const Duration(seconds: 4),
    );
  }

  void _ensureController() {
    if (_notificationsController == null &&
        Get.isRegistered<NotificationsController>()) {
      _notificationsController = Get.find<NotificationsController>();
    }
  }
}


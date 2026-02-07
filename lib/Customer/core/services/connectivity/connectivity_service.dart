import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/config/app_config.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class ConnectivityService extends GetxService with WidgetsBindingObserver {
  DateTime? _lastCheckAt;
  bool _lastResult = true;
  int _consecutiveFailures = 0;
  StreamSubscription<dynamic>? _connectivitySub;
  final Connectivity _connectivity = Connectivity();
  bool? _lastNotifiedOnline;

  static const Duration _cacheDuration = Duration(seconds: 20);
  static const Duration _probeTimeout = Duration(seconds: 4);
  static const int _maxFailuresBeforeOffline = 2;
  static const String _probePath = '/health';

  final RxBool isOnline = true.obs;
  final RxBool checking = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    checkNow(force: true);
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((dynamic event) {
      final results = _normalizeConnectivity(event);
      _handleConnectivity(results);
    });
  }

  Future<bool> verifyServerReachable({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastCheckAt != null &&
        _lastResult &&
        now.difference(_lastCheckAt!) < _cacheDuration) {
      return _lastResult;
    }

    try {
      final ok = await _probeBackend();
      _lastCheckAt = now;
      _lastResult = ok;
      return ok;
    } on SocketException catch (error, stack) {
      log('[ConnectivityService] Connectivity probe failed: $error',
          stackTrace: stack);
      _lastCheckAt = now;
      _lastResult = false;
      return false;
    } catch (error, stack) {
      log('[ConnectivityService] Connectivity probe failed: $error',
          stackTrace: stack);
      _lastCheckAt = now;
      _lastResult = false;
      return false;
    }
  }

  Future<void> checkNow({bool force = false}) async {
    if (checking.value) return;
    final prevOnline = isOnline.value;
    checking.value = true;
    try {
      final ok = await verifyServerReachable(
        force: force || !isOnline.value,
      );
      if (ok) {
        _consecutiveFailures = 0;
        if (!isOnline.value) {
          isOnline.value = true;
        }
        return;
      }
      _consecutiveFailures += 1;
      if (isOnline.value &&
          _consecutiveFailures < _maxFailuresBeforeOffline) {
        return;
      }
      isOnline.value = false;
    } finally {
      checking.value = false;
      _notifyIfChanged(prevOnline, isOnline.value);
    }
  }

  void setOnline(bool value, {bool notify = false}) {
    final prevOnline = isOnline.value;
    if (value) {
      _consecutiveFailures = 0;
    }
    isOnline.value = value;
    if (notify) {
      _notifyIfChanged(prevOnline, value);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkNow(force: true);
    }
  }

  Future<bool> _probeBackend() async {
    final uri = _buildProbeUri();
    final client = HttpClient()..connectionTimeout = _probeTimeout;
    if (AppConfig.instance.allowBadCertificates) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }

    try {
      final request = await client.getUrl(uri).timeout(_probeTimeout);
      request.headers.set(HttpHeaders.userAgentHeader, 'UstaConnectivityProbe');
      final response = await request.close().timeout(_probeTimeout);
      await response.drain();
      return response.statusCode > 0;
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildProbeUri() {
    final origin = AppConfig.instance.origin.trim();
    if (origin.isEmpty) {
      return Uri.https('one.one.one.one', '/');
    }
    final parsed = Uri.tryParse(origin);
    if (parsed != null && parsed.host.isNotEmpty) {
      return parsed.replace(path: _probePath);
    }
    return Uri.https(origin, _probePath);
  }

  List<ConnectivityResult> _normalizeConnectivity(dynamic event) {
    if (event is ConnectivityResult) return <ConnectivityResult>[event];
    if (event is List<ConnectivityResult>) return event;
    return const <ConnectivityResult>[ConnectivityResult.none];
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (!hasNetwork) {
      _consecutiveFailures = _maxFailuresBeforeOffline;
      _lastResult = false;
      _lastCheckAt = DateTime.now();
      if (isOnline.value) {
        setOnline(false, notify: true);
      }
      return;
    }
    checkNow(force: true);
  }

  void _notifyIfChanged(bool previous, bool current) {
    if (_lastNotifiedOnline == null) {
      _lastNotifiedOnline = current;
      return;
    }
    if (_lastNotifiedOnline == current || previous == current) return;
    _lastNotifiedOnline = current;
    if (current) {
      AppSnackBar.show(
        'تم'.tr,
        'تم استعادة الاتصال بالإنترنت'.tr,
      );
    } else {
      AppSnackBar.show(
        'تنبيه'.tr,
        'لا يوجد اتصال بالإنترنت'.tr,
      );
    }
  }
}


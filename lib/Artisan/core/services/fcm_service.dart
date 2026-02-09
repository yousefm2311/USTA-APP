import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/device_id_service.dart';
import 'package:usta/Artisan/data/repositories/fcm_repository.dart';

class FcmService extends GetxService {
  FcmService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  static final RegExp _topicPattern = RegExp(r'^[a-z0-9_]+$');
  static const Set<String> _baseTopics = {'all', 'role_artisans'};

  final FirebaseMessaging _messaging;
  final DeviceIdService _deviceIdService = DeviceIdService();
  final FcmRepository _repo = Get.find<FcmRepository>();
  final AuthService _authService = Get.find<AuthService>();
  final GetStorage _cache = GetStorage();

  String? _deviceId;
  String? _currentToken;
  StreamSubscription<String>? _tokenSubscription;
  Timer? _tokenRetryTimer;
  bool _initialized = false;
  int _tokenRetryAttempt = 0;

  static const String _pendingSubscribeKey = 'fcm_pending_subscribe';
  static const String _pendingUnsubscribeKey = 'fcm_pending_unsubscribe';
  static const List<Duration> _tokenRetryDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
  ];
  static const Duration _tokenTimeout = Duration(seconds: 8);

  Future<FcmService> init() async {
    if (_initialized) return this;

    _deviceId = await _deviceIdService.getDeviceId();
    await _safeSetAutoInit();
    await _safeRequestPermission();

    _currentToken = await _safeGetToken();
    if (_currentToken == null || _currentToken!.isEmpty) {
      _scheduleTokenRetry();
    }
    _listenTokenRefresh();

    _authService.registerAccessTokenListener((token) {
      if (token != null && token.isNotEmpty) {
        _safeSyncToken();
        _safeFlushQueuedTopics();
      }
    });

    if (_authService.accessToken?.isNotEmpty == true) {
      await _safeSyncToken();
      await _safeFlushQueuedTopics();
    }

    _initialized = true;
    return this;
  }

  Future<void> syncToken({String? tokenOverride}) async {
    final accessToken = _authService.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    final deviceId = _deviceId ?? await _deviceIdService.getDeviceId();
    String? token = tokenOverride ?? _currentToken;
    if (token == null || token.isEmpty) {
      token = await _safeGetToken();
      if (token == null || token.isEmpty) {
        _scheduleTokenRetry();
        return;
      }
      _currentToken = token;
    }
    if (deviceId.isEmpty) return;

    await _repo.saveToken(
      token: token,
      deviceId: deviceId,
      platform: _resolvePlatform(),
    );
  }

  Future<void> subscribeTopic(String topic) async {
    if (!isValidTopicName(topic)) {
      throw ArgumentError('Invalid topic name: $topic');
    }
    if (_authService.accessToken?.isNotEmpty != true) {
      await _queueTopic(topic, subscribe: true);
      return;
    }
    final deviceId = _deviceId ?? await _deviceIdService.getDeviceId();
    await _repo.subscribeTopic(topic: topic, deviceId: deviceId);
  }

  Future<void> unsubscribeTopic(String topic) async {
    if (!isValidTopicName(topic)) {
      throw ArgumentError('Invalid topic name: $topic');
    }
    if (_authService.accessToken?.isNotEmpty != true) {
      await _queueTopic(topic, subscribe: false);
      return;
    }
    final deviceId = _deviceId ?? await _deviceIdService.getDeviceId();
    await _repo.unsubscribeTopic(topic: topic, deviceId: deviceId);
  }

  bool isValidTopicName(String topic) {
    if (!_topicPattern.hasMatch(topic)) return false;
    if (topic.startsWith('seg_')) return true;
    return _baseTopics.contains(topic);
  }

  String _resolvePlatform() {
    if (GetPlatform.isAndroid) return 'android';
    if (GetPlatform.isIOS) return 'ios';
    if (GetPlatform.isWeb) return 'web';
    return 'android';
  }

  Future<void> flushQueuedTopics() async {
    if (_authService.accessToken?.isNotEmpty != true) return;
    final subscribeQueue = _readQueued(_pendingSubscribeKey);
    final unsubscribeQueue = _readQueued(_pendingUnsubscribeKey);
    if (subscribeQueue.isEmpty && unsubscribeQueue.isEmpty) return;

    for (final topic in subscribeQueue) {
      if (isValidTopicName(topic)) {
        await _repo.subscribeTopic(
          topic: topic,
          deviceId: _deviceId ?? await _deviceIdService.getDeviceId(),
        );
      }
    }
    for (final topic in unsubscribeQueue) {
      if (isValidTopicName(topic)) {
        await _repo.unsubscribeTopic(
          topic: topic,
          deviceId: _deviceId ?? await _deviceIdService.getDeviceId(),
        );
      }
    }

    await _cache.remove(_pendingSubscribeKey);
    await _cache.remove(_pendingUnsubscribeKey);
  }

  Future<void> _queueTopic(String topic, {required bool subscribe}) async {
    final subscribeQueue = _readQueued(_pendingSubscribeKey);
    final unsubscribeQueue = _readQueued(_pendingUnsubscribeKey);

    if (subscribe) {
      subscribeQueue.add(topic);
      unsubscribeQueue.remove(topic);
    } else {
      unsubscribeQueue.add(topic);
      subscribeQueue.remove(topic);
    }

    await _cache.write(_pendingSubscribeKey, subscribeQueue.toList());
    await _cache.write(_pendingUnsubscribeKey, unsubscribeQueue.toList());
  }

  Set<String> _readQueued(String key) {
    final raw = _cache.read<List<dynamic>>(key) ?? const [];
    return raw.whereType<String>().toSet();
  }

  void _listenTokenRefresh() {
    _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _tokenRetryAttempt = 0;
      _tokenRetryTimer?.cancel();
      if (_authService.accessToken?.isNotEmpty == true) {
        _safeSyncToken(tokenOverride: token);
        _safeFlushQueuedTopics();
      }
    });
  }

  Future<void> _safeSetAutoInit() async {
    try {
      await _messaging.setAutoInitEnabled(true);
    } on FirebaseException catch (error, stack) {
      log('[FcmService] setAutoInitEnabled failed: $error',
          stackTrace: stack);
    } catch (error, stack) {
      log('[FcmService] setAutoInitEnabled failed: $error',
          stackTrace: stack);
    }
  }

  Future<void> _safeRequestPermission() async {
    try {
      await _messaging.requestPermission();
    } on FirebaseException catch (error, stack) {
      log('[FcmService] requestPermission failed: $error', stackTrace: stack);
    } catch (error, stack) {
      log('[FcmService] requestPermission failed: $error', stackTrace: stack);
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final supported = await _messaging.isSupported();
      if (!supported) return null;
      return await _messaging.getToken().timeout(_tokenTimeout);
    } on TimeoutException catch (error) {
      log('[FcmService] getToken timed out: $error');
      return null;
    } on FirebaseException catch (error, stack) {
      log('[FcmService] getToken failed: $error', stackTrace: stack);
      return null;
    } catch (error, stack) {
      log('[FcmService] getToken failed: $error', stackTrace: stack);
      return null;
    }
  }

  void _scheduleTokenRetry() {
    if (_tokenRetryTimer != null ||
        _tokenRetryAttempt >= _tokenRetryDelays.length) {
      return;
    }
    final delay = _tokenRetryDelays[_tokenRetryAttempt];
    _tokenRetryAttempt += 1;
    _tokenRetryTimer = Timer(delay, () async {
      _tokenRetryTimer = null;
      final token = await _safeGetToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        _tokenRetryAttempt = 0;
        if (_authService.accessToken?.isNotEmpty == true) {
          await _safeSyncToken(tokenOverride: token);
          await _safeFlushQueuedTopics();
        }
      } else {
        _scheduleTokenRetry();
      }
    });
  }

  Future<void> _safeSyncToken({String? tokenOverride}) async {
    try {
      await syncToken(tokenOverride: tokenOverride);
    } catch (error, stack) {
      log('[FcmService] syncToken failed: $error', stackTrace: stack);
    }
  }

  Future<void> _safeFlushQueuedTopics() async {
    try {
      await flushQueuedTopics();
    } catch (error, stack) {
      log('[FcmService] flushQueuedTopics failed: $error',
          stackTrace: stack);
    }
  }

  @override
  void onClose() {
    _tokenSubscription?.cancel();
    _tokenRetryTimer?.cancel();
    super.onClose();
  }
}

import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';

class FcmRepository {
  final ApiClient _client = Get.find<ApiClient>(tag: 'artisan');

  Future<void> saveToken({
    required String token,
    required String deviceId,
    String? platform,
  }) async {
    await _client.post(ApiEndpoints.fcmToken, data: {
      'token': token,
      'deviceId': deviceId,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
    });
  }

  Future<void> subscribeTopic({
    required String topic,
    required String deviceId,
  }) async {
    await _client.post(ApiEndpoints.subscribeTopic, data: {
      'topic': topic,
      'deviceId': deviceId,
    });
  }

  Future<void> unsubscribeTopic({
    required String topic,
    required String deviceId,
  }) async {
    await _client.post(ApiEndpoints.unsubscribeTopic, data: {
      'topic': topic,
      'deviceId': deviceId,
    });
  }
}


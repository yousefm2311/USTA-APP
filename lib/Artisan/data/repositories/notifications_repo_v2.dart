// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class NotificationsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<List<NotificationItem>> list() async {
//     final res = await _client.get(ApiEndpointsV2.notifications);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<void> markRead(String id) async {
//     await _client.put(ApiEndpointsV2.notificationRead(id));
//   }

//   Future<void> delete(String id) async {
//     await _client.delete(ApiEndpointsV2.notificationDelete(id));
//   }

//   Future<void> saveFcmToken(String token) async {
//     await _client.post(ApiEndpointsV2.fcmToken, data: {'token': token});
//   }

//   Future<List<FcmToken>> listFcmTokens() async {
//     final res = await _client.get(ApiEndpointsV2.fcmToken);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => FcmToken.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

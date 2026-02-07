// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class CustomerProfileRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Customer> me() async {
//     final res = await _client.get(ApiEndpointsV2.me);
//     return Customer.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<Customer> profile() async {
//     final res = await _client.get(ApiEndpointsV2.profile);
//     return Customer.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<Customer> updateProfile(Map<String, dynamic> payload) async {
//     final res = await _client.put(ApiEndpointsV2.updateProfile, data: payload);
//     return Customer.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<void> uploadPhoto(String base64) async {
//     await _client.post(ApiEndpointsV2.profilePhoto, data: {'photo': base64});
//   }

//   Future<void> deleteAccount() async {
//     await _client.delete(ApiEndpointsV2.deleteAccount);
//   }

//   Future<void> changePassword(
//       {required String oldPassword, required String newPassword}) async {
//     await _client.put(ApiEndpointsV2.changePassword,
//         data: {'oldPassword': oldPassword, 'newPassword': newPassword});
//   }

//   Future<void> updateMe(Map<String, dynamic> payload) async {
//     await _client.put(ApiEndpointsV2.updateMe, data: payload);
//   }

//   Future<void> updateNotificationSettings(
//       {required bool marketing,
//       required bool requests,
//       required bool chat}) async {
//     await _client.put(ApiEndpointsV2.notificationsSettings, data: {
//       'marketing': marketing,
//       'requests': requests,
//       'chat': chat,
//     });
//   }

//   Future<void> updateLanguage(String lang) async {
//     await _client.put(ApiEndpointsV2.language, data: {'language': lang});
//   }

//   Future<void> updateTheme(String theme) async {
//     await _client.put(ApiEndpointsV2.theme, data: {'theme': theme});
//   }

//   Future<void> setOnline(bool online, {DateTime? unavailableUntil}) async {
//     await _client.put(ApiEndpointsV2.online, data: {
//       'online': online,
//       'unavailableUntil': unavailableUntil?.toIso8601String()
//     });
//   }

//   Future<void> setAvailability(List<Map<String, dynamic>> slots) async {
//     await _client.put(ApiEndpointsV2.availability, data: {'slots': slots});
//   }

//   Future<Map<String, dynamic>> getOnline() async {
//     final res = await _client.get(ApiEndpointsV2.onlineStatus);
//     return ApiResponseParser.extractData(res.data);
//   }
// }

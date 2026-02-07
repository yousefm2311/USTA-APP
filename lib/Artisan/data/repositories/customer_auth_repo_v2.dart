// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';

// class CustomerAuthRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Map<String, dynamic>> signup(Map<String, dynamic> payload) async {
//     final res = await _client.post(ApiEndpointsV2.signup, data: payload);
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<Map<String, dynamic>> login(Map<String, dynamic> payload) async {
//     final res = await _client.post(ApiEndpointsV2.login, data: payload);
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<void> logout() async {
//     await _client.post(ApiEndpointsV2.logout);
//   }

//   Future<Map<String, dynamic>> refresh(String refreshToken) async {
//     final res = await _client
//         .post(ApiEndpointsV2.refreshToken, data: {'refreshToken': refreshToken});
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<void> verify(Map<String, dynamic> payload) async {
//     await _client.post(ApiEndpointsV2.verify, data: payload);
//   }

//   Future<void> forgotPassword(Map<String, dynamic> payload) async {
//     await _client.post(ApiEndpointsV2.forgotPassword, data: payload);
//   }
// }

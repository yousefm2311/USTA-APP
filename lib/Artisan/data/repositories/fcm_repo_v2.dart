// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class FcmRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<void> saveToken(String token) async {
//     await _client.post(ApiEndpointsV2.fcmToken, data: {'token': token});
//   }

//   Future<List<FcmToken>> listTokens() async {
//     final res = await _client.get(ApiEndpointsV2.fcmToken);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => FcmToken.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

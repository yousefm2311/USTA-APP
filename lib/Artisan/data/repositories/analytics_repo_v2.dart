// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';

// class AnalyticsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Map<String, dynamic>> dashboard() async {
//     final res = await _client.get(ApiEndpointsV2.dashboard);
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<Map<String, dynamic>> stats() async {
//     final res = await _client.get(ApiEndpointsV2.stats);
//     return ApiResponseParser.extractData(res.data);
//   }
// }

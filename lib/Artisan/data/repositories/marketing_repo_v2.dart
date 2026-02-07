// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class MarketingRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<List<Coupon>> coupons() async {
//     final res = await _client.get(ApiEndpointsV2.coupons);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Coupon.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<Map<String, dynamic>> applyCoupon(String code) async {
//     final res =
//         await _client.post(ApiEndpointsV2.applyCoupon, data: {'code': code});
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<void> referral(Map<String, dynamic> payload) async {
//     await _client.post(ApiEndpointsV2.referral, data: payload);
//   }

//   Future<List<Reward>> rewards() async {
//     final res = await _client.get(ApiEndpointsV2.rewards);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Reward.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<Recommendation>> recommendations() async {
//     final res = await _client.get(ApiEndpointsV2.recommendations);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Recommendation.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<LiveMapItem>> liveMap() async {
//     final res = await _client.get(ApiEndpointsV2.liveMap);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => LiveMapItem.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<AIFeedback> aiFeedback() async {
//     final res = await _client.get(ApiEndpointsV2.aiFeedback);
//     return AIFeedback.fromJson(ApiResponseParser.extractData(res.data));
//   }
// }

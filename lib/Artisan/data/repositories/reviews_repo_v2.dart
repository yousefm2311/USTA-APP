// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class ReviewsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Review> create(String artisanId, Map<String, dynamic> payload) async {
//     final res =
//         await _client.post(ApiEndpointsV2.createReview(artisanId), data: payload);
//     return Review.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<Review> update(String id, Map<String, dynamic> payload) async {
//     final res =
//         await _client.put(ApiEndpointsV2.updateReview(id), data: payload);
//     return Review.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<void> delete(String id) async {
//     await _client.delete(ApiEndpointsV2.deleteReview(id));
//   }

//   Future<List<Review>> list() async {
//     final res = await _client.get(ApiEndpointsV2.reviews);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class FavoritesRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<void> add(String artisanId) async {
//     await _client.post(ApiEndpointsV2.favorite(artisanId));
//   }

//   Future<void> remove(String artisanId) async {
//     await _client.delete(ApiEndpointsV2.favorite(artisanId));
//   }

//   Future<List<Favorite>> list() async {
//     final res = await _client.get(ApiEndpointsV2.favorites);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Favorite.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<ViewHistoryItem>> history() async {
//     final res = await _client.get(ApiEndpointsV2.history);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => ViewHistoryItem.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

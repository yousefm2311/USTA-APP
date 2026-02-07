// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class ExploreRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<List<Category>> categories() async {
//     final res = await _client.get(ApiEndpointsV2.categories);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<Artisan>> search(Map<String, dynamic> query) async {
//     final res = await _client.get(ApiEndpointsV2.searchArtisans, query: query);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Artisan.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<Artisan> artisan(String id) async {
//     final res = await _client.get(ApiEndpointsV2.artisan(id));
//     return Artisan.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<List<Artisan>> nearby(Map<String, dynamic> query) async {
//     final res = await _client.get(ApiEndpointsV2.nearbyArtisans, query: query);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Artisan.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<Artisan>> topRated() async {
//     final res = await _client.get(ApiEndpointsV2.topRatedArtisans);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Artisan.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<Artisan>> area() async {
//     final res = await _client.get(ApiEndpointsV2.areaArtisans);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Artisan.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

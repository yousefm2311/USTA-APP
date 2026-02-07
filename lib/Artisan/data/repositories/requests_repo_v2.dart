// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class RequestsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Request> create(Map<String, dynamic> payload) async {
//     final res = await _client.post(ApiEndpointsV2.requests, data: payload);
//     return Request.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<void> addImages(String id, List<String> imagesBase64) async {
//     await _client.post(ApiEndpointsV2.requestImages(id),
//         data: {'images': imagesBase64});
//   }

//   Future<List<Request>> active() async {
//     final res = await _client.get(ApiEndpointsV2.activeRequests);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Request.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<List<Request>> history() async {
//     final res = await _client.get(ApiEndpointsV2.historyRequests);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Request.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<Request> detail(String id) async {
//     final res = await _client.get(ApiEndpointsV2.request(id));
//     return Request.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<List<RequestTimelineItem>> timeline(String id) async {
//     final res = await _client.get(ApiEndpointsV2.requestTimeline(id));
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => RequestTimelineItem.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<void> cancel(String id) async {
//     await _client.delete(ApiEndpointsV2.cancelRequest(id));
//   }

//   Future<void> confirmCompletion(String id) async {
//     await _client.post(ApiEndpointsV2.confirmRequest(id));
//   }
// }

// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class ComplaintsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Complaint> create(Map<String, dynamic> payload) async {
//     final res = await _client.post(ApiEndpointsV2.complaints, data: payload);
//     return Complaint.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<List<Complaint>> list() async {
//     final res = await _client.get(ApiEndpointsV2.complaints);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => Complaint.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<Complaint> detail(String id) async {
//     final res = await _client.get(ApiEndpointsV2.complaint(id));
//     return Complaint.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<void> sendMessage(String id, String message) async {
//     await _client.post(ApiEndpointsV2.complaintMessages(id), data: {'message': message});
//   }

//   Future<List<ComplaintMessage>> messages(String id) async {
//     final res = await _client.get(ApiEndpointsV2.complaintMessages(id));
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => ComplaintMessage.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

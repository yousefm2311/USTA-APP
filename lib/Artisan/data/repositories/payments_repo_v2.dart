// import 'package:get/get.dart';
// import '../../core/network_v2/api_client_v2.dart';
// import '../../core/network_v2/api_response_parser.dart';
// import '../../core/utils/constants/api_endpoints_v2.dart';
// import '../models/customer_models_v2.dart';

// class PaymentsRepoV2 {
//   final ApiClientV2 _client = Get.find<ApiClientV2>();

//   Future<Payment> createPayment(Map<String, dynamic> payload) async {
//     final res = await _client.post(ApiEndpointsV2.payment, data: payload);
//     return Payment.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<Map<String, dynamic>> receipt(String id) async {
//     final res = await _client.get(ApiEndpointsV2.paymentReceipt(id));
//     return ApiResponseParser.extractData(res.data);
//   }

//   Future<Wallet> wallet() async {
//     final res = await _client.get(ApiEndpointsV2.wallet);
//     return Wallet.fromJson(ApiResponseParser.extractData(res.data));
//   }

//   Future<void> recharge(double amount) async {
//     await _client.post(ApiEndpointsV2.walletRecharge, data: {'amount': amount});
//   }

//   Future<List<WalletTransaction>> history() async {
//     final res = await _client.get(ApiEndpointsV2.walletHistory);
//     return ApiResponseParser.extractList(res.data)
//         .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
// }

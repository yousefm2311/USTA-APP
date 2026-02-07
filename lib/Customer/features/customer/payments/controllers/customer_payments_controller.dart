import 'package:get/get.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerPaymentsController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> payments = <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;
  final RxBool creating = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    loading.value = true;
    try {
      final response = await _repo.api.walletHistory();
      dynamic list = response['history'] ??
          response['payments'] ??
          response['transactions'];
      if (list == null && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        list = data['transactions'] ?? data['payments'] ?? data['history'];
      } else if (list == null && response['data'] is List) {
        list = response['data'];
      }
      if (list is List) {
        payments.assignAll(
          list
              .map<Map<String, dynamic>>(
                  (e) => e is Map<String, dynamic> ? e : {})
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      } else {
        payments.clear();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      payments.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<Map<String, dynamic>> fetchReceipt(String id) async {
    final res = await _repo.api.paymentReceipt(id);
    final data = res['data'];
    if (data is Map && data['receipt'] is Map<String, dynamic>) {
      return data['receipt'] as Map<String, dynamic>;
    }
    if (res['receipt'] is Map<String, dynamic>) {
      return res['receipt'] as Map<String, dynamic>;
    }
    return res;
  }

  Future<Map<String, dynamic>> createPayment({
    required String requestId,
    required double amount,
  }) async {
    creating.value = true;
    try {
      final res = await _repo.api.createPayment(
        requestId: requestId,
        amount: amount,
      );
      final data = res['data'];
      if (data is Map<String, dynamic>) return data;
      return res;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      rethrow;
    } finally {
      creating.value = false;
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String requestId,
  }) async {
    creating.value = true;
    try {
      final res = await _repo.api.createPaymentIntent(requestId: requestId);
      final data = res['data'];
      if (data is Map<String, dynamic>) return data;
      return res;
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      rethrow;
    } finally {
      creating.value = false;
    }
  }
}



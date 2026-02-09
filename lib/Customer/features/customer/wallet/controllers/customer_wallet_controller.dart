import 'package:get/get.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerWalletController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  final Rxn<num> balance = Rxn<num>();
  final RxList<Map<String, dynamic>> history = <Map<String, dynamic>>[].obs;
  final RxBool loadingBalance = false.obs;
  final RxBool loadingHistory = false.obs;
  final RxBool recharging = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_hasAccessToken()) {
      fetchWallet();
      fetchHistory();
    }
  }

  Future<void> fetchWallet() async {
    if (!_hasAccessToken()) {
      balance.value = null;
      loadingBalance.value = false;
      return;
    }
    loadingBalance.value = true;
    try {
      final response = await _repo.api.wallet();
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      balance.value = response['balance'] ??
          response['wallet'] ??
          response['amount'] ??
          data['balance'] ??
          data['amount'];
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      balance.value = null;
    } finally {
      loadingBalance.value = false;
    }
  }

  Future<void> fetchHistory() async {
    if (!_hasAccessToken()) {
      history.clear();
      loadingHistory.value = false;
      return;
    }
    loadingHistory.value = true;
    try {
      final response = await _repo.api.walletHistory();
      dynamic list = response['history'] ?? response['transactions'];
      if (list == null && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        list = data['transactions'] ?? data['history'] ?? data['items'];
      }
      if (list is List) {
        history.assignAll(
          list
              .map<Map<String, dynamic>>(
                  (e) => e is Map<String, dynamic> ? e : {})
              .toList(),
        );
      } else {
        history.clear();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      history.clear();
    } finally {
      loadingHistory.value = false;
    }
  }

  Future<void> recharge(num amount) async {
    recharging.value = true;
    try {
      await _repo.api.rechargeWallet(amount);
      await fetchWallet();
      await fetchHistory();
    } finally {
      recharging.value = false;
    }
  }

  bool _hasAccessToken() {
    final access = _storage.accessToken;
    return access != null && access.isNotEmpty;
  }
}


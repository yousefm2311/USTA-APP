import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerHistoryController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> views = <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    loading.value = true;
    try {
      final res = await _repo.api.viewHistory();
      final data = res['views'] ?? res['data'] ?? res['items'];
      if (data is List) {
        views.assignAll(
          data.map<Map<String, dynamic>>(
              (e) => e is Map<String, dynamic> ? e : {}),
        );
      } else {
        views.clear();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
        Get.find<AuthController>(tag: 'customer').logout(remote: false);
      }
      views.clear();
    } finally {
      loading.value = false;
    }
  }
}



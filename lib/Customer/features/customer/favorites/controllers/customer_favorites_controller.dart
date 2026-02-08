import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerFavoritesController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  final RxList<Map<String, dynamic>> favorites = <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_hasAccessToken()) {
      fetchFavorites();
    }
  }

  Future<void> fetchFavorites() async {
    if (!_hasAccessToken()) {
      loading.value = false;
      return;
    }
    loading.value = true;
    try {
      final response = await _repo.api.listFavorites();
      final data = response['favorites'] ??
          response['data'] ??
          response['rows'] ??
          response['items'];
      if (data is List) {
        favorites.assignAll(
          data.map<Map<String, dynamic>>((e) => e is Map<String, dynamic> ? e : {}),
        );
      }
    } on ApiException catch (e) {
      _handleAuthFailure(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> add(String artisanId, {Map<String, dynamic>? artisan}) async {
    saving.value = true;
    try {
      await _repo.api.addFavorite(artisanId);
      if (artisan != null) {
        favorites.removeWhere(
            (element) => (element['_id'] ?? element['id'] ?? element['artisanId']).toString() == artisanId);
        favorites.insert(0, artisan);
      } else {
        await fetchFavorites();
      }
    } on ApiException catch (e) {
      _handleAuthFailure(e);
    } finally {
      saving.value = false;
    }
  }

  Future<void> remove(String artisanId) async {
    saving.value = true;
    try {
      await _repo.api.removeFavorite(artisanId);
      favorites.removeWhere(
          (element) => (element['_id'] ?? element['id'] ?? element['artisanId']).toString() == artisanId);
    } on ApiException catch (e) {
      _handleAuthFailure(e);
    } finally {
      saving.value = false;
    }
  }

  bool isFavorite(String artisanId) {
    return favorites.any(
        (e) => (e['_id'] ?? e['id'] ?? e['artisanId']).toString() == artisanId);
  }

  bool _hasAccessToken() {
    final access = _storage.accessToken;
    return access != null && access.isNotEmpty;
  }

  void _handleAuthFailure(ApiException error) {
    if (error.statusCode == 401 &&
        Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
    }
  }
}

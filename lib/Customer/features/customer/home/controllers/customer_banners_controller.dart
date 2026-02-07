import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';

class CustomerBannersController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<Map<String, dynamic>> banners = <Map<String, dynamic>>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  DateTime? _lastFetchAt;
  String _lastKey = '';
  bool _loaded = false;

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<CustomerProfileController>()) {
      final profileCtrl = Get.find<CustomerProfileController>();
      ever(profileCtrl.profile, (_) => fetchBanners(force: true));
    }

    fetchBanners();
  }

  Future<void> fetchBanners({
    String? city,
    String? category,
    String? userType,
    bool force = false,
  }) async {
    final resolvedCity = city ?? _cityFromProfile();
    final resolvedUserType = _normalizeUserType(
      userType ?? _userTypeFromProfile(),
    );
    final effectiveUserType = resolvedUserType ?? 'all';

    final key =
        '${resolvedCity ?? ''}|${category ?? ''}|$effectiveUserType';
    final now = DateTime.now();
    if (!force &&
        _loaded &&
        key == _lastKey &&
        _lastFetchAt != null &&
        now.difference(_lastFetchAt!).inSeconds < 60) {
      return;
    }

    loading.value = true;
    error.value = '';
    try {
      final res = await _repo.api.activeBanners(
        city: resolvedCity,
        category: category,
        userType: effectiveUserType,
      );
      final list = res['data'] ?? res['banners'] ?? [];
      final parsed = _asList(list);
      final filtered = _filterByWindow(parsed);
      filtered.sort((a, b) => _priorityOf(b).compareTo(_priorityOf(a)));
      banners.assignAll(filtered);
      _loaded = true;
      _lastKey = key;
      _lastFetchAt = now;
    } on ApiException catch (e) {
      _handleError(e);
    } finally {
      loading.value = false;
    }
  }

  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is List) {
      return raw
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic> ? e : <String, dynamic>{},
          )
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _filterByWindow(
    List<Map<String, dynamic>> list,
  ) {
    final now = DateTime.now();
    return list.where((b) {
      final start = _parseDate(b['startAt']);
      final end = _parseDate(b['endAt']);
      if (start != null && now.isBefore(start)) return false;
      if (end != null && now.isAfter(end)) return false;
      return true;
    }).toList();
  }

  int _priorityOf(Map<String, dynamic> banner) {
    final v = banner['priority'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.trim().isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  String? _cityFromProfile() {
    if (!Get.isRegistered<CustomerProfileController>()) return null;
    final profile = Get.find<CustomerProfileController>().profile.value;
    if (profile == null) return null;
    final city =
        profile['city'] ??
        profile['area'] ??
        profile['governorate'] ??
        (profile['location'] is Map ? profile['location']['city'] : null);
    return city?.toString();
  }

  String? _userTypeFromProfile() {
    if (!Get.isRegistered<CustomerProfileController>()) return null;
    final profile = Get.find<CustomerProfileController>().profile.value;
    if (profile == null) return null;

    final raw =
        profile['userType'] ??
        profile['targetUserType'] ??
        profile['user_type'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }

    final isNew =
        profile['isNewUser'] ??
        profile['newUser'] ??
        profile['isNew'];
    if (isNew == true) return 'new_users';

    final count =
        profile['requestsCount'] ??
        profile['ordersCount'] ??
        profile['totalRequests'] ??
        profile['completedRequests'];
    if (count is num && count > 0) return 'returning_users';

    final createdAt = _parseDate(profile['createdAt']);
    if (createdAt != null) {
      final days = DateTime.now().difference(createdAt).inDays;
      return days <= 7 ? 'new_users' : 'returning_users';
    }

    return null;
  }

  String? _normalizeUserType(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toLowerCase();
    if (v == 'new_users' || v == 'returning_users' || v == 'all') return v;
    return null;
  }

  void _handleError(ApiException e) {
    if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
    }
    error.value = e.message;
  }
}



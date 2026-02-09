import 'package:get/get.dart';
import 'package:usta/Customer/core/services/network/api_exception.dart';
import 'package:usta/Customer/core/services/token_storage.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:usta/Customer/features/auth/controllers/auth_controller.dart';

class CustomerDashboardController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final TokenStorage _storage = Get.find<TokenStorage>(tag: 'customer');

  final RxBool loadingDashboard = false.obs;
  final RxBool loadingStats = false.obs;
  final RxMap<String, dynamic> dashboard = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> monthly = <Map<String, dynamic>>[].obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (_hasAccessToken()) {
      loadAll();
    }
  }

  Future<void> loadAll() async {
    await Future.wait([fetchDashboard(), fetchStats()]);
  }

  Future<void> fetchDashboard() async {
    if (!_hasAccessToken()) {
      loadingDashboard.value = false;
      return;
    }
    loadingDashboard.value = true;
    error.value = '';
    try {
      final res = await _repo.api.dashboard();
      final data = _extractData(res);
      dashboard.assignAll(data);
    } on ApiException catch (e) {
      _handleAuth(e);
      error.value = e.message;
    } finally {
      loadingDashboard.value = false;
    }
  }

  Future<void> fetchStats() async {
    if (!_hasAccessToken()) {
      loadingStats.value = false;
      return;
    }
    loadingStats.value = true;
    error.value = '';
    try {
      final res = await _repo.api.stats();
      final data = _extractData(res);
      monthly.assignAll(_extractMonthly(data));
    } on ApiException catch (e) {
      _handleAuth(e);
      error.value = e.message;
      monthly.clear();
    } finally {
      loadingStats.value = false;
    }
  }

  num get totalRequests => _numFromKeys([
    'totalRequests',
    'requests',
    'requestsTotal',
    'requests_count',
    'activeRequests',
  ]);

  num get completedRequests =>
      _numFromKeys(['completedRequests', 'completed', 'done']);

  num get pendingRequests =>
      _numFromKeys(['pendingRequests', 'pending', 'open', 'active']);

  num get revenue => _numFromKeys([
    'revenue',
    'totalRevenue',
    'amount',
    'totalAmount',
    'wallet',
  ]);

  num get activeRequests =>
      _numFromKeys(['activeRequests', 'active', 'current']);

  num get unreadNotifications =>
      _numFromKeys(['unreadNotifications', 'notificationsUnread', 'unread']);

  num get myReviews => _numFromKeys(['myReviews', 'reviews']);

  List<double> get monthValues {
    if (monthly.isEmpty) return [];
    return monthly
        .map(
          (e) => _toDouble(
            e['value'] ?? e['count'] ?? e['total'] ?? e['amount'] ?? 0,
          ),
        )
        .toList();
  }

  List<String> get monthLabels {
    if (monthly.isEmpty) return _defaultMonthLabels;
    return monthly
        .map((e) {
          final m = e['month'] ?? e['label'] ?? e['_id'];
          if (m is int) {
            return _defaultMonthLabels[(m - 1).clamp(0, 11)];
          }
          if (m is String && m.isNotEmpty) {
            if (m.contains('-')) {
              final parts = m.split('-');
              if (parts.length >= 2) {
                final monthNum = int.tryParse(parts[1]);
                if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
                  return _defaultMonthLabels[monthNum - 1];
                }
              }
            }
            return m;
          }
          return null;
        })
        .whereType<String>()
        .map((e) => e.tr)
        .toList()
        .take(monthValues.length)
        .toList();
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> res) {
    if (res['data'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(res['data'] as Map<String, dynamic>);
    }
    return Map<String, dynamic>.from(res);
  }

  List<Map<String, dynamic>> _extractMonthly(Map<String, dynamic> data) {
    dynamic list =
        data['monthly'] ??
        data['months'] ??
        data['chart'] ??
        data['series'] ??
        data['monthlyRequests'];
    if (list is List) {
      return list
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic> ? e : {'value': _toDouble(e)},
          )
          .toList();
    }
    return [];
  }

  num _numFromKeys(List<String> keys) {
    for (final key in keys) {
      final v = dashboard[key];
      if (v != null) return _toDouble(v);
    }
    if (dashboard['data'] is Map<String, dynamic>) {
      final nested = dashboard['data'] as Map<String, dynamic>;
      for (final key in keys) {
        final v = nested[key];
        if (v != null) return _toDouble(v);
      }
    }
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0;
  }

  void _handleAuth(ApiException e) {
    if (e.statusCode == 401 && Get.isRegistered<AuthController>(tag: 'customer')) {
      Get.find<AuthController>(tag: 'customer').logout(remote: false);
    }
  }

  bool _hasAccessToken() {
    final access = _storage.accessToken;
    return access != null && access.isNotEmpty;
  }

  List<String> get _defaultMonthLabels => const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
}


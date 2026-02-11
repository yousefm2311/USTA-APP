
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/auth_service.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class WalletController extends GetxController {
  final ArtisanApi _api = ArtisanApi();
  final AuthService _auth = Get.find<AuthService>();

  final RxBool loading = false.obs;
  final RxBool withdrawing = false.obs;
  final RxInt balance = 0.obs;
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _auth.whenAuthenticated(fetchWallet);
  }

  Future<void> fetchWallet() async {
    if (!_auth.isAuthenticated) return;

    loading.value = true;
    try {
      await _tryFetchWallet();
    } finally {
      loading.value = false;
    }
  }

  Future<void> _tryFetchWallet() async {
    try {
      /// ---- balance summary ----
      final balanceResp = await _api.wallet();
      final balanceData = ApiClient.instance.unwrapData(balanceResp);
      if (balanceData is Map<String, dynamic>) {
        balance.value = int.tryParse('${balanceData['balance'] ?? 0}') ?? 0;
      }

      /// ---- history ----
      final response = await _api.walletHistory();
      final data = ApiClient.instance.unwrapData(response);
      final txs = (data is Map<String, dynamic>)
          ? (data['transactions'] ?? data['history'])
          : null;

      if (txs is List) {
        final parsed = txs
            .map(
              (e) =>
                  (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            )
            .toList();

        parsed.sort((a, b) {
          final da =
              DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

        transactions.assignAll(parsed);
      }
    } on ApiException catch (e) {
      // هنا بقى السحر 🎩
      if (e.statusCode == 401) {
        final refreshed = await _auth.refreshTokens();
        if (refreshed) {
          /// retry automatically
          final balanceRetry = await _api.wallet();
          final balanceData = ApiClient.instance.unwrapData(balanceRetry);
          if (balanceData is Map<String, dynamic>) {
            balance.value = int.tryParse('${balanceData['balance'] ?? 0}') ?? 0;
          }

          final responseRetry = await _api.walletHistory();
          final dataRetry = ApiClient.instance.unwrapData(responseRetry);
          final txsRetry = (dataRetry is Map<String, dynamic>)
              ? (dataRetry['transactions'] ?? dataRetry['history'])
              : null;

          if (txsRetry is List) {
            final parsed = txsRetry
                .map(
                  (e) =>
                      (e as Map?)?.cast<String, dynamic>() ??
                      <String, dynamic>{},
                )
                .toList();

            parsed.sort((a, b) {
              final da =
                  DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db =
                  DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });

            transactions.assignAll(parsed);
          }
          return;
        }

        /// Refresh failed → logout cleanly
        await _auth.handleUnauthorized(skipRefresh: true);
        return;
      }

      _showError(AppStrings.walletLoadFailed.tr);
    } catch (_) {
      _showError(AppStrings.walletLoadFailed.tr);
    }
  }

  Future<void> withdraw(int amount) async {
    if (amount <= 0) {
      _showError(AppStrings.invalidWithdrawAmount.tr);
      return;
    }
    if (amount > balance.value) {
      _showError(AppStrings.insufficientBalance.tr);
      return;
    }
    withdrawing.value = true;
    try {
      await _tryWithdraw(amount);
    } finally {
      withdrawing.value = false;
    }
  }

  Future<void> _tryWithdraw(int amount) async {
    try {
      await _api.withdraw(amount);
      await fetchWallet();
      _showError(AppStrings.withdrawSuccess.tr, isError: false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await _auth.refreshTokens();
        if (refreshed) {
          await _api.withdraw(amount);
          await fetchWallet();
          _showError(AppStrings.withdrawSuccess.tr, isError: false);
          return;
        }
        await _auth.handleUnauthorized(skipRefresh: true);
        return;
      }

      _showError(AppStrings.withdrawFailed.tr);
    } catch (_) {
      _showError(AppStrings.withdrawFailed.tr);
    }
  }

  void _showError(String message, {bool isError = true}) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


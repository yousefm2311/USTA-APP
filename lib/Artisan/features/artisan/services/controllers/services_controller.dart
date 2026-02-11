
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/network/api_client.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/data/providers/artisan_api.dart';

class ServicesController extends GetxController {
  final ArtisanApi _api = ArtisanApi();

  final RxBool loading = false.obs;
  final RxBool saving = false.obs;
  final RxBool categoriesLoading = false.obs;

  /// Keep id & name so we can delete/update correctly.
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pricing = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;

  List<String> get serviceNames => services
      .map((e) => (e['name'] ?? '').toString())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get categoryNames => categories
      .map((e) => (e['name'] ?? '').toString())
      .where((e) => e.isNotEmpty)
      .toList();

  String get _currentCurrency =>
      pricing.isNotEmpty &&
          (pricing.first['currency']?.toString().isNotEmpty ?? false)
      ? pricing.first['currency'].toString()
      : 'EGP';

  Map<String, dynamic>? _serviceByName(String name) {
    try {
      return services.firstWhere(
        (e) => (e['name'] ?? e['serviceName'] ?? '').toString() == name,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _serviceById(String id) {
    try {
      return services.firstWhere(
        (e) => (e['id'] ?? e['_id'])?.toString() == id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadFromProfile() async {
    loading.value = true;
    try {
      final response = await _api.me();
      final data = ApiClient.instance.unwrapData(response);
      final artisan = data is Map<String, dynamic>
          ? (data['artisan'] ?? data) as Map<String, dynamic>?
          : null;

      final srv = artisan?['services'];
      if (srv is List) {
        services.assignAll(
          srv
              .map((e) {
                if (e is Map) {
                  return {
                    'id': e['_id']?.toString() ?? e['id']?.toString() ?? '',
                    'name':
                        e['name']?.toString() ??
                        e['serviceName']?.toString() ??
                        '',
                  };
                }
                return {'id': e.toString(), 'name': e.toString()};
              })
              .where((e) => (e['name']?.toString() ?? '').isNotEmpty)
              .toList(),
        );
      } else {
        services.clear();
      }

      final price = artisan?['pricing'];
      if (price is List) {
        pricing.assignAll(
          price
              .map(
                (e) =>
                    (e as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
              )
              .toList(),
        );
      } else {
        pricing.clear();
      }
    } catch (_) {
      _showSnack(AppStrings.servicesLoadFailed.tr, isError: true);
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadCategories() async {
    categoriesLoading.value = true;
    try {
      final response = await _api.categories();
      final data = ApiClient.instance.unwrapData(response);
      final raw = data is Map<String, dynamic> ? data['categories'] : data;
      if (raw is List) {
        categories.assignAll(
          raw
              .map((e) {
                if (e is Map) {
                  return {
                    'id': e['_id']?.toString() ?? e['id']?.toString() ?? '',
                    'name': e['name']?.toString() ?? '',
                  };
                }
                return {'id': '', 'name': e.toString()};
              })
              .where((e) => (e['name']?.toString() ?? '').isNotEmpty)
              .toList(),
        );
      } else {
        categories.clear();
      }
    } catch (_) {
      _showSnack(AppStrings.categoriesLoadFailed.tr, isError: true);
    } finally {
      categoriesLoading.value = false;
    }
  }

  Future<void> setServices(List<String> items) async {
    saving.value = true;
    try {
      await _api.setServices(items);
      await loadFromProfile();
      _showSnack(AppStrings.servicesUpdatedMessage.tr, isError: false);
    } catch (_) {
      _showSnack(AppStrings.servicesUpdateFailed.tr, isError: true);
    } finally {
      saving.value = false;
    }
  }

  Future<void> setPricing(List<Map<String, dynamic>> items) async {
    saving.value = true;
    try {
      final merged = [...pricing];
      for (final item in items) {
        final name = item['serviceName'] ?? item['name'];
        final idx = merged.indexWhere(
          (p) => (p['serviceName'] ?? p['name'])?.toString() == name,
        );
        final normalized = {
          ...item,
          'serviceName': name,
          'currency': item['currency'] ?? _currentCurrency,
        };
        if (idx >= 0) {
          merged[idx] = {...merged[idx], ...normalized};
        } else {
          merged.add(normalized);
        }
      }
      await _api.setPricing(merged);
      pricing.assignAll(merged);
      _showSnack(AppStrings.pricingSavedMessage.tr, isError: false);
    } catch (_) {
      _showSnack(AppStrings.pricingSaveFailed.tr, isError: true);
    } finally {
      saving.value = false;
    }
  }

  Future<void> saveServiceWithPrice({
    required String name,
    int? price,
    int? min,
    int? max,
    String? previousName,
  }) async {
    saving.value = true;
    try {
      final newName = name.trim();
      final oldName = previousName?.trim();
      final resolvedMin = min ?? price ?? 0;
      final resolvedMax = max ?? price ?? resolvedMin;

      final existingService =
          oldName != null && oldName.isNotEmpty
              ? _serviceByName(oldName)
              : _serviceByName(newName);

      // Update service name if it already exists, otherwise recreate list to add it.
      if (existingService != null &&
          (existingService['id']?.toString().isNotEmpty ?? false)) {
        await _api.updateService(
          existingService['id'].toString(),
          newName,
        );
      } else {
        final names = serviceNames;
        if (oldName != null && oldName.isNotEmpty) {
          names.remove(oldName);
        }
        if (!names.contains(newName)) {
          names.add(newName);
        }
        await _api.setServices(names);
      }

      // Replace pricing entry for this service (and drop any stale one with the old name).
      final namesToDrop = <String>{
        newName,
        if (oldName != null && oldName.isNotEmpty) oldName,
      };

      final updatedPricing = pricing
          .where((p) {
            final pname =
                (p['serviceName'] ?? p['name'])?.toString() ?? '';
            return !namesToDrop.contains(pname);
          })
          .map((p) => {...p})
          .toList();

      updatedPricing.add({
        'serviceName': newName,
        'min': resolvedMin,
        'max': resolvedMax,
        'currency': _currentCurrency,
      });

      await _api.setPricing(updatedPricing);
      await loadFromProfile();
      _showSnack(AppStrings.serviceSavedMessage.tr, isError: false);
    } catch (_) {
      _showSnack(AppStrings.serviceSaveFailed.tr, isError: true);
    } finally {
      saving.value = false;
    }
  }

  Future<void> deleteService(
    String id, {
    String? serviceName,
  }) async {
    final name = serviceName ??
        _serviceById(id)?['name']?.toString() ??
        '';
    if (id.isEmpty && name.isEmpty) return;

    saving.value = true;
    try {
      if (id.isNotEmpty) {
        await _api.deleteService(id);
      }

      if (name.isNotEmpty && pricing.isNotEmpty) {
        final filteredPricing = pricing
            .where(
              (p) =>
                  (p['serviceName'] ?? p['name'])?.toString() != name,
            )
            .map((p) => {...p})
            .toList();

        if (filteredPricing.length != pricing.length) {
          await _api.setPricing(filteredPricing);
        }
      }

      await loadFromProfile();
      _showSnack(AppStrings.serviceDeletedMessage.tr, isError: false);
    } catch (_) {
      _showSnack(AppStrings.serviceDeleteFailed.tr, isError: true);
    } finally {
      saving.value = false;
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    AppSnackBar.show(
      isError ? AppStrings.error.tr : AppStrings.success.tr,
      message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }
}


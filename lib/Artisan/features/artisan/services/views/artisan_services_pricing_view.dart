// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/core/utils/widgets/icon_broken.dart';
import 'package:usta/Artisan/features/artisan/services/controllers/services_controller.dart';

class ArtisanServicesPricingView extends StatefulWidget {
  const ArtisanServicesPricingView({super.key});

  @override
  State<ArtisanServicesPricingView> createState() =>
      _ArtisanServicesPricingViewState();
}

class _ArtisanServicesPricingViewState
    extends State<ArtisanServicesPricingView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final ServicesController controller = Get.find<ServicesController>();

  @override
  void initState() {
    super.initState();
    controller.loadFromProfile();
    controller.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.quickActionsServices.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.save.tr,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addServiceDialog,
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              controller.loadFromProfile();
              controller.loadCategories();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        final loading = controller.loading.value;
        final items = _buildItems();

        if (loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          color: primaryBlue,
          onRefresh: () async {
            await Future.wait([
              controller.loadFromProfile(),
              controller.loadCategories(),
            ]);
          },
          child: items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.inbox_outlined,
                      size: 54,
                      color: scheme.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        AppStrings.noData.tr,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: scheme.onSurface.withOpacity(0.7)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'اسحب لتحديث القائمة',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _serviceItem(
                      context: context,
                      id: item.id,
                      name: item.name,
                      min: item.min,
                      max: item.max,
                      currency: item.currency,
                    );
                  },
                ),
        );
      }),
    );
  }

  // ====== UI Item ======

  Widget _serviceItem({
    required BuildContext context,
    required String id,
    required String name,
    required int min,
    required int max,
    required String currency,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final priceText = _priceLabel(min: min, max: max, currency: currency);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _editServiceDialog(
        currentId: id,
        currentName: name,
        currentMin: min,
        currentMax: max,
        currency: currency,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                scheme.brightness == Brightness.dark ? 0.18 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryBlue.withOpacity(0.22)),
              ),
              child: Icon(Icons.build, color: primaryBlue),
            ),

            const SizedBox(width: 12),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primaryBlue.withOpacity(0.18)),
                    ),
                    child: Text(
                      priceText,
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 12,
                        color: primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: AppStrings.edit.tr,
                  onPressed: () => _editServiceDialog(
                    currentId: id,
                    currentName: name,
                    currentMin: min,
                    currentMax: max,
                    currency: currency,
                  ),
                  icon: Icon(
                    IconBroken.Edit,
                    color: scheme.onSurface.withOpacity(0.85),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(context, id: id, name: name),
                  icon: const Icon(IconBroken.Delete, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_ServicePriceItem> _buildItems() {
    if (controller.pricing.isNotEmpty) {
      return controller.pricing.map<_ServicePriceItem>((e) {
        final name = (e['serviceName'] ?? e['name'] ?? '').toString().trim();
        final currency = (e['currency'] ?? 'EGP').toString();
        final min = _toInt(e['min'] ?? e['price'] ?? 0);
        final max = _toInt(e['max'] ?? e['price'] ?? min);

        // حاول تجيب id من services لو مش موجود في pricing
        final srv = controller.services.firstWhere(
          (s) => (s['name'] ?? '').toString().trim() == name,
          orElse: () => {},
        );
        final id = (e['id'] ?? e['_id'] ?? srv['id'] ?? srv['_id'] ?? '')
            .toString();

        return _ServicePriceItem(
          id: id,
          name: name.isEmpty ? 'خدمة' : name,
          min: min,
          max: max,
          currency: currency.isEmpty ? 'EGP' : currency,
        );
      }).toList();
    }
    return controller.serviceNames.map<_ServicePriceItem>((n) {
      final name = n.toString().trim();
      final srv = controller.services.firstWhere(
        (s) => (s['name'] ?? '').toString().trim() == name,
        orElse: () => {},
      );
      final id = (srv['id'] ?? srv['_id'] ?? '').toString();
      return _ServicePriceItem(
        id: id,
        name: name.isEmpty ? 'خدمة' : name,
        min: 0,
        max: 0,
        currency: 'EGP',
      );
    }).toList();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _priceLabel({
    required int min,
    required int max,
    required String currency,
  }) {
    if (min <= 0 && max <= 0) return "بدون سعر";
    if (min > 0 && max > 0 && max != min) return "$min - $max $currency";
    final p = (min > 0 ? min : max);
    return "$p $currency";
  }

  List<String> _serviceOptions(String? selectedName) {
    final options = controller.categoryNames;
    if (selectedName != null &&
        selectedName.isNotEmpty &&
        !options.contains(selectedName)) {
      return [selectedName, ...options];
    }
    return options;
  }

  void _addServiceDialog() {
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    _serviceDialog(
      title: AppStrings.quickActionsServices.tr,
      minCtrl: minCtrl,
      maxCtrl: maxCtrl,
      onSave: (selectedName) {
        final name = selectedName.trim();
        final min = int.tryParse(minCtrl.text.trim()) ?? 0;
        final max = int.tryParse(maxCtrl.text.trim()) ?? 0;

        if (name.isEmpty) {
          _snack(
            AppStrings.serviceNameRequired.tr,
            Colors.redAccent,
          );
          return;
        }
        final fixedMax = (max > 0 && max < min) ? min : max;
        controller.saveServiceWithPrice(name: name, min: min, max: fixedMax);

        Navigator.pop(context);
      },
    );
  }

  void _editServiceDialog({
    required String currentId,
    required String currentName,
    required int currentMin,
    required int currentMax,
    required String currency,
  }) {
    final minCtrl = TextEditingController(
      text: currentMin <= 0 ? '' : currentMin.toString(),
    );
    final maxCtrl = TextEditingController(
      text: currentMax <= 0 ? '' : currentMax.toString(),
    );

    _serviceDialog(
      title: AppStrings.edit.tr,
      initialName: currentName,
      minCtrl: minCtrl,
      maxCtrl: maxCtrl,
      onSave: (selectedName) {
        final name = selectedName.trim();
        final min = int.tryParse(minCtrl.text.trim()) ?? 0;
        final max = int.tryParse(maxCtrl.text.trim()) ?? 0;
        final fixedMax = (max > 0 && max < min) ? min : max;

        if (name.isEmpty) {
          _snack(
            AppStrings.serviceNameRequired.tr,
            Colors.redAccent,
          );
          return;
        }

        controller.saveServiceWithPrice(
          name: name,
          min: min,
          max: fixedMax,
          previousName: currentName,
        );

        Navigator.pop(context);
      },
    );
  }

  void _serviceDialog({
    required String title,
    String? initialName,
    required TextEditingController minCtrl,
    required TextEditingController maxCtrl,
    required void Function(String selectedName) onSave,
  }) {
    final scheme = Theme.of(context).colorScheme;
    String? selectedName = initialName?.trim();
    controller.loadCategories();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Obx(() {
                final options = _serviceOptions(selectedName);
                final hasOptions = options.isNotEmpty;
                final isLoading = controller.categoriesLoading.value;
                final canSave =
                    selectedName != null && selectedName!.trim().isNotEmpty;

                if (hasOptions &&
                    (selectedName == null || !options.contains(selectedName))) {
                  selectedName = options.first;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: hasOptions ? selectedName : null,
                      items: options
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(
                                name,
                                style: AppTextStyles.body(context),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: hasOptions
                          ? (value) => setState(() => selectedName = value)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'اختر الخدمة',
                        prefixIcon: const Icon(Icons.home_repair_service),
                        labelStyle: AppTextStyles.body(context),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.lightBlueAccent,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ] else if (!hasOptions) ...[
                      const SizedBox(height: 10),
                      Text(
                        'لا توجد خدمات متاحة حالياً',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            label: 'أقل سعر',
                            ctrl: minCtrl,
                            isNumber: true,
                            prefix: const Icon(Icons.payments_outlined),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _inputField(
                            label: 'أعلى سعر (اختياري)',
                            ctrl: maxCtrl,
                            isNumber: true,
                            prefix: const Icon(Icons.payments_outlined),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSave
                                ? () => onSave(selectedName!.trim())
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              AppStrings.save.tr,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade500,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              AppStrings.cancel.tr,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    bool isNumber = false,
    Widget? prefix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix,
        labelStyle: AppTextStyles.body(context),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context, {
    required String id,
    required String name,
  }) {
    if (id.isEmpty) {
      _snack(
        AppStrings.serviceDeleteMissingId.tr,
        Colors.redAccent,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('حذف الخدمة', style: AppTextStyles.title(context)),
        content: Text(
          'هل تريد حذف "$name"؟',
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel.tr,
              style: AppTextStyles.body(context),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteService(id, serviceName: name);
            },
            child: Text(
              'حذف',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    final type =
        color == Colors.redAccent ? SnackBarType.error : SnackBarType.info;
    AppSnackBar.show(
      type == SnackBarType.error ? AppStrings.error.tr : AppStrings.info.tr,
      msg,
      type: type,
    );
  }
}

// ====== Small helper model for UI only ======
class _ServicePriceItem {
  final String id;
  final String name;
  final int min;
  final int max;
  final String currency;

  _ServicePriceItem({
    required this.id,
    required this.name,
    required this.min,
    required this.max,
    required this.currency,
  });
}


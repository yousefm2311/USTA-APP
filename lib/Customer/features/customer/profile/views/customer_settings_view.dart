import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/services/settings/local_controller.dart';
import 'package:usta/Customer/core/services/settings/nearby_radius_settings.dart';
import 'package:usta/Customer/core/services/settings/theme_controller.dart';
import 'package:usta/Customer/features/customer/profile/controllers/customer_profile_controller.dart';
import 'package:usta/Customer/features/customer/explore/controllers/customer_explore_controller.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/settings_section_title.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/settings_segmented_row.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/settings_slots_list.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/settings_switch_tile.dart';
import 'package:usta/Customer/features/customer/profile/views/widgets/settings_unavailable_picker.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class CustomerSettingsView extends StatefulWidget {
  const CustomerSettingsView({super.key});

  @override
  State<CustomerSettingsView> createState() => _CustomerSettingsViewState();
}

class _CustomerSettingsViewState extends State<CustomerSettingsView> {
  final controller = Get.find<CustomerProfileController>();
  final LocaleController localeController = Get.find<LocaleController>(tag: 'customer');
  final ThemeController themeController = Get.find<ThemeController>(tag: 'customer');

  Worker? _profileWorker;
  Worker? _onlineWorker;
  Worker? _untilWorker;

  bool marketing = true;
  bool requests = true;
  bool chat = true;

  String lang = 'ar';
  String theme = 'light';

  bool online = false;
  DateTime? unavailableUntil;

  final List<Map<String, dynamic>> slots = [];
  final TextEditingController _radiusCtrl = TextEditingController();
  double? _radiusKm;

  @override
  void initState() {
    super.initState();
    lang = localeController.locale.value.languageCode;
    theme = themeController.isDark.value ? 'dark' : 'light';
    _syncWithProfile(controller.profile.value ?? {});
    online = controller.online.value;
    unavailableUntil = controller.unavailableUntil.value;
    _loadRadiusSetting();
    _profileWorker = ever(controller.profile, (p) {
      if (p != null && !controller.updatingSettings.value) {
        _syncWithProfile(Map<String, dynamic>.from(p as Map));
      }
    });

    _onlineWorker = ever(controller.online, (_) {
      if (mounted) setState(() => online = controller.online.value);
    });

    _untilWorker = ever(controller.unavailableUntil, (_) {
      if (mounted)
        setState(() => unavailableUntil = controller.unavailableUntil.value);
    });
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _onlineWorker?.dispose();
    _untilWorker?.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: scheme.surface,
          title: Text(
            "الإعدادات".tr,
            style: const TextStyle(fontFamily: "Cairo"),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SettingsSectionTitle(title: "الإشعارات".tr),
            SettingsSwitchTile(
              title: "التسويقية".tr,
              value: marketing,
              onChanged: (v) => setState(() => marketing = v),
            ),
            SettingsSwitchTile(
              title: "الطلبات".tr,
              value: requests,
              onChanged: (v) => setState(() => requests = v),
            ),
            SettingsSwitchTile(
              title: "المحادثات".tr,
              value: chat,
              onChanged: (v) => setState(() => chat = v),
            ),

            SettingsSectionTitle(title: "اللغة".tr),
            const SizedBox(height: 6),
            SettingsSegmentedRow(
              title: 'اختيار اللغة'.tr,
              options: [
                const SettingsSegOption(value: 'ar', label: 'AR'),
                const SettingsSegOption(value: 'en', label: 'EN'),
              ],
              selected: lang,
              onSelect: (v) => setState(() => lang = v),
            ),

            SettingsSectionTitle(title: "الثيم".tr),
            const SizedBox(height: 6),
            SettingsSegmentedRow(
              title: 'اختيار الثيم'.tr,
              options: [
                SettingsSegOption(value: 'light', label: 'فاتح'.tr),
                SettingsSegOption(value: 'dark', label: 'داكن'.tr),
              ],
              selected: theme,
              onSelect: (v) => setState(() => theme = v),
            ),

            SettingsSectionTitle(title: "نطاق البحث".tr),
            const SizedBox(height: 6),
            TextFormField(
              controller: _radiusCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: const TextStyle(fontFamily: 'Cairo'),
              decoration: InputDecoration(
                labelText: 'المسافة بالكيلومتر'.tr,
                hintText: 'الافتراضي 60 كم'.tr,
                suffixText: 'كم'.tr,
                labelStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  _radiusCtrl.clear();
                  _radiusKm = null;
                  setState(() {});
                },
                child: Text(
                  'استخدام الافتراضي'.tr,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ),

            SettingsSectionTitle(title: "الحالة".tr),
            SettingsSwitchTile(
              title: 'متاح للعمل'.tr,
              value: online,
              onChanged: (v) {
                setState(() => online = v);
                controller.online.value = v; // update live in controller
              },
              activeColor: scheme.primary,
            ),
            SettingsUnavailablePicker(
              text: unavailableUntil == null
                  ? 'غير محدد'.tr
                  : unavailableUntil!.toLocal().toString().split('.').first,
              onPick: _pickDateTime,
              onClear: () => setState(() => unavailableUntil = null),
            ),

            SettingsSectionTitle(title: "المواعيد المتاحة".tr),
            SettingsSlotsList(
              slots: slots,
              onRemove: (index) => setState(() => slots.removeAt(index)),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _addSlot,
              icon: const Icon(Icons.add),
              label: Text(
                'إضافة موعد'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),

            const SizedBox(height: 18),

            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.updatingSettings.value
                      ? null
                      : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    controller.updatingSettings.value
                        ? 'جارٍ التحديث...'.tr
                        : 'حفظ الإعدادات'.tr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _loadRadiusSetting() async {
    final km = await NearbyRadiusSettings.readKm();
    if (!mounted) return;
    if (km != null) {
      _radiusKm = km;
      _radiusCtrl.text = _formatKm(km);
    }
    setState(() {});
  }

  String _formatKm(double km) {
    final raw = km.toStringAsFixed(2);
    return raw.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double? _parseRadiusKm() {
    final raw = _radiusCtrl.text.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) return double.nan;
    return parsed;
  }

  Future<void> _saveSettings() async {
    final parsedRadius = _parseRadiusKm();
    if (parsedRadius != null && parsedRadius.isNaN) {
      AppSnackBar.show(
        'خطأ'.tr,
        'يرجى إدخال مسافة صحيحة بالكيلومتر'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final radiusChanged = parsedRadius != _radiusKm;
    _radiusKm = parsedRadius;
    await NearbyRadiusSettings.saveKm(parsedRadius);

    try {
      await controller.updateNotificationSettings(
        marketing: marketing,
        requests: requests,
        chat: chat,
      );

      await controller.setLanguage(lang);
      await controller.setTheme(theme);

      await controller.setOnlineStatus(
        onlineStatus: online,
        until: unavailableUntil,
      );

      await controller.setAvailability(List<Map<String, dynamic>>.from(slots));

      if (radiusChanged && Get.isRegistered<CustomerExploreController>()) {
        await Get.find<CustomerExploreController>().fetchNearby(force: true);
      }

      if (mounted) Get.back();
    } catch (_) {
      AppSnackBar.show(
        'خطأ'.tr,
        'حصلت مشكلة أثناء حفظ الإعدادات'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _syncWithProfile(Map<String, dynamic> profile) {
    if (controller.updatingSettings.value) return;

    final notif =
        profile['notifications'] ??
        profile['notificationSettings'] ??
        profile['settings'] ??
        {};

    if (notif is Map) {
      marketing = (notif['marketing'] ?? marketing) == true;
      requests = (notif['requests'] ?? requests) == true;
      chat = (notif['chat'] ?? chat) == true;
    }

    if (profile['language'] != null) lang = profile['language'].toString();
    if (profile['theme'] != null) theme = profile['theme'].toString();

    if (profile['online'] is bool) online = profile['online'] as bool;

    final untilRaw = profile['unavailableUntil'];
    if (untilRaw is String && untilRaw.isNotEmpty) {
      unavailableUntil = DateTime.tryParse(untilRaw);
    } else {
      unavailableUntil = null;
    }

    final slotsRaw = profile['slots'] ?? profile['availabilitySlots'];
    if (slotsRaw is List) {
      slots
        ..clear()
        ..addAll(
          slotsRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: unavailableUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(unavailableUntil ?? now),
    );
    if (time == null) return;

    setState(() {
      unavailableUntil = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addSlot() async {
    const days = [
      'السبت',
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];

    String selectedDay = days.first;
    TimeOfDay? from;
    TimeOfDay? to;

    await showDialog(
      context: context,
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;

        return AlertDialog(
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'إضافة موعد'.tr,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setLocal) {
              String timeText(TimeOfDay? t) => t == null
                  ? 'اختر وقت'.tr
                  : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

              final border = OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: scheme.outlineVariant.withOpacity(0.55),
                ),
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    dropdownColor: scheme.surface,
                    decoration: InputDecoration(
                      labelText: 'اليوم'.tr,
                      labelStyle: const TextStyle(fontFamily: 'Cairo'),
                      enabledBorder: border,
                      border: border,
                    ),
                    items: days
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              d.tr,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setLocal(() => selectedDay = v ?? selectedDay),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: scheme.outlineVariant.withOpacity(0.55),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: from ?? TimeOfDay.now(),
                            );
                            if (picked != null) setLocal(() => from = picked);
                          },
                          icon: const Icon(Icons.schedule, size: 18),
                          label: Text(
                            '${'من'.tr}: ${timeText(from)}',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: scheme.outlineVariant.withOpacity(0.55),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: to ?? TimeOfDay.now(),
                            );
                            if (picked != null) setLocal(() => to = picked);
                          },
                          icon: const Icon(Icons.schedule, size: 18),
                          label: Text(
                            '${'إلى'.tr}: ${timeText(to)}',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ملاحظة: تأكد أن "من" أقل من "إلى".'.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'إلغاء'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (from == null || to == null) {
                  AppSnackBar.show(
                    'خطأ'.tr,
                    'اختر وقت البداية والنهاية'.tr,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                final fromMin = from!.hour * 60 + from!.minute;
                final toMin = to!.hour * 60 + to!.minute;
                if (fromMin >= toMin) {
                  AppSnackBar.show(
                    'خطأ'.tr,
                    'وقت "من" يجب أن يكون قبل "إلى"'.tr,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                final slot = {
                  'day': selectedDay,
                  'from':
                      '${from!.hour.toString().padLeft(2, '0')}:${from!.minute.toString().padLeft(2, '0')}',
                  'to':
                      '${to!.hour.toString().padLeft(2, '0')}:${to!.minute.toString().padLeft(2, '0')}',
                };

                setState(() => slots.add(slot));
                Get.back();
              },
              child: Text(
                'حفظ'.tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        );
      },
    );
  }
}




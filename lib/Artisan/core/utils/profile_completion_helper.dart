import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/profile_completion_card.dart';

class ProfileCompletionHelper {
  static final GetStorage _box = GetStorage();
  static const Duration _defaultHideDuration = Duration(hours: 24);

  static int completionPercent(Map<String, dynamic> profile) {
    final raw = profile['profileCompletion'] ??
        profile['completion'] ??
        profile['profile_completion'];
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static bool isCompletedFlag(Map<String, dynamic> profile) {
    final raw =
        profile['isCompleted'] ?? profile['isProfileCompleted'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    return raw?.toString().toLowerCase() == 'true';
  }

  static bool hasMissingFieldsKey(Map<String, dynamic> profile) {
    return profile.containsKey('missingFields') ||
        profile.containsKey('missing_fields');
  }

  static List<String> missingFields(Map<String, dynamic> profile) {
    final raw = profile['missingFields'] ?? profile['missing_fields'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static int effectiveCompletionPercent(
    Map<String, dynamic> profile,
    List<ProfileCompletionItem> items,
  ) {
    if (isCompletedFlag(profile)) return 100;
    final completion = completionPercent(profile).clamp(0, 100);
    final missing = missingFields(profile);
    final hasMissingKey = hasMissingFieldsKey(profile);

    if (completion >= 100) return 100;
    if (hasMissingKey && missing.isEmpty) return 100;

    if (hasMissingKey && completion <= 0 && items.isNotEmpty) {
      final missingSet = ProfileCompletionChecklist.normalizeMissing(missing);
      var missingCount = items
          .where((item) =>
              ProfileCompletionChecklist.isMissingItem(item, missingSet))
          .length;
      if (missingCount == 0 && missingSet.isNotEmpty) {
        missingCount = missingSet.length.clamp(0, items.length);
      }
      final computed =
          (((items.length - missingCount) / items.length) * 100).round();
      return computed.clamp(0, 100);
    }

    return completion;
  }

  static bool isProfileComplete(
    Map<String, dynamic> profile,
    List<ProfileCompletionItem> items,
  ) {
    if (isCompletedFlag(profile)) return true;
    final completion = effectiveCompletionPercent(profile, items);
    final missing = missingFields(profile);
    final hasMissingKey = hasMissingFieldsKey(profile);
    if (completion >= 100) return true;
    if (hasMissingKey && missing.isEmpty) return true;
    return false;
  }

  static List<ProfileCompletionItem> items() {
    return [
      ProfileCompletionItem(
        key: 'avatar',
        label: AppStrings.profilephoto.tr,
        aliases: const [
          'profile_photo',
          'profilephoto',
          'profilePhoto',
          'photo',
          'profile_image',
          'profileImage',
          'avatar',
        ],
        onTap: () => pushNamedRoute(AppRoutes.artisanProfileEditView),
      ),
      ProfileCompletionItem(
        key: 'name',
        label: AppStrings.name.tr,
        aliases: const ['full_name', 'fullname', 'display_name'],
        onTap: () => pushNamedRoute(AppRoutes.artisanProfileEditView),
      ),
      ProfileCompletionItem(
        key: 'profession',
        label: AppStrings.profession.tr,
        aliases: const ['job_title', 'title', 'specialty'],
        onTap: () => pushNamedRoute(AppRoutes.artisanProfileEditView),
      ),
      ProfileCompletionItem(
        key: 'phone',
        label: AppStrings.phone.tr,
        aliases: const ['phone_number', 'mobile', 'mobile_number'],
        onTap: () => pushNamedRoute(AppRoutes.artisanProfileEditView),
      ),
      ProfileCompletionItem(
        key: 'description',
        label: AppStrings.description.tr,
        aliases: const ['bio', 'about', 'about_me'],
        onTap: () => pushNamedRoute(AppRoutes.artisanProfileEditView),
      ),
      ProfileCompletionItem(
        key: 'services',
        label: AppStrings.servicesLabel.tr,
        aliases: const ['service', 'service_list'],
        onTap: () => pushNamedRoute(AppRoutes.artisanServicesPricingView),
      ),
      ProfileCompletionItem(
        key: 'pricing',
        label: AppStrings.pricing.tr,
        aliases: const ['prices', 'rates'],
        onTap: () => pushNamedRoute(AppRoutes.artisanServicesPricingView),
      ),
      ProfileCompletionItem(
        key: 'portfolio',
        label: AppStrings.portfolio.tr,
        aliases: const ['gallery', 'work_samples', 'workSamples'],
        onTap: () => pushNamedRoute(AppRoutes.artisanPortfolioView),
      ),
      ProfileCompletionItem(
        key: 'location',
        label: AppStrings.setLocation.tr,
        aliases: const ['address', 'city', 'geo'],
        onTap: () => pushNamedRoute(AppRoutes.artisanLocationSettingsView),
      ),
    ];
  }

  static ProfileCompletionItem? firstMissingItem(
    List<ProfileCompletionItem> items,
    List<String> missingFields,
  ) {
    final missing = ProfileCompletionChecklist.normalizeMissing(missingFields);
    for (final item in items) {
      if (ProfileCompletionChecklist.isMissingItem(item, missing)) {
        return item;
      }
    }
    return null;
  }

  static bool shouldShowBottomSheet(
    Map<String, dynamic> profile,
    List<ProfileCompletionItem> items,
  ) {
    if (isProfileComplete(profile, items)) return false;

    final missing = missingFields(profile);
    final hideUntil = _box.read(_hideUntilKey(profile));
    final lastMissing = _box.read(_missingHashKey(profile));
    final currentMissing = _missingHash(missing);

    if (hideUntil is int &&
        DateTime.now().millisecondsSinceEpoch < hideUntil &&
        lastMissing == currentMissing) {
      return false;
    }

    return true;
  }

  static void hideBottomSheet(
    Map<String, dynamic> profile,
    List<String> missingFields, {
    Duration duration = _defaultHideDuration,
  }) {
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    _box.write(_hideUntilKey(profile), until);
    _box.write(_missingHashKey(profile), _missingHash(missingFields));
  }

  static String _missingHash(List<String> missingFields) {
    final normalized = missingFields
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList()
      ..sort();
    return normalized.join('|');
  }

  static String _hideUntilKey(Map<String, dynamic> profile) {
    return 'profile_completion_hide_until_${_profileId(profile)}';
  }

  static String _missingHashKey(Map<String, dynamic> profile) {
    return 'profile_completion_missing_hash_${_profileId(profile)}';
  }

  static String _profileId(Map<String, dynamic> profile) {
    final raw = profile['id'] ??
        profile['_id'] ??
        profile['userId'] ??
        profile['artisanId'] ??
        profile['uid'] ??
        profile['uuid'];
    if (raw == null) return 'default';
    return raw.toString();
  }
}


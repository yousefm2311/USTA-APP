import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/profile_completion_helper.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';

class ArtisanProfileView extends StatefulWidget {
  const ArtisanProfileView({super.key});

  @override
  State<ArtisanProfileView> createState() => _ArtisanProfileViewState();
}

class _ArtisanProfileViewState extends State<ArtisanProfileView> {
  final ProfileController controller = Get.find<ProfileController>();

  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color _surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  Color _surfaceV(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceVariant;
  Color _onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  Color _outline(BuildContext context) => Theme.of(context).colorScheme.outline;

  TextStyle _muted(BuildContext context) => AppTextStyles.caption(context).copyWith(
    color:  _onSurface(context).withOpacity(0.65),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(

        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppStrings.profileTitle.tr,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              tooltip: AppStrings.edit.tr,
              onPressed: () => Get.toNamed(AppRoutes.artisanProfileEditView),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = controller.profile;
          final items = ProfileCompletionHelper.items();
          final completion =
              ProfileCompletionHelper.effectiveCompletionPercent(data, items);
          final missing = ProfileCompletionHelper.missingFields(data);
          final nextItem = ProfileCompletionHelper.firstMissingItem(
            items,
            missing,
          );
          final onCompleteTap = nextItem?.onTap ??
              () => Get.toNamed(AppRoutes.artisanProfileEditView);

          return RefreshIndicator(
            onRefresh: controller.fetchProfile,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _headerCard(context),
                const SizedBox(height: 12),

                if (completion < 100) ...[
                  _profileCompletionSummary(
                    context,
                    completion: completion,
                    onCompleteTap: onCompleteTap,
                  ),
                  const SizedBox(height: 12),
                ],

                _sectionCard(
                  context,
                  title: AppStrings.quickStats.tr,
                  child: _statsGrid(context, data),
                ),
                const SizedBox(height: 12),

                _sectionCard(
                  context,
                  title: AppStrings.about.tr,
                  child: _aboutSection(context, data),
                ),
                const SizedBox(height: 12),

                _sectionCard(
                  context,
                  title: AppStrings.servicesLabel.tr,
                  trailing: TextButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.artisanServicesPricingView),
                    child: Text(
                      AppStrings.edit.tr,
                      style: TextStyle(color: _primary(context)),
                    ),
                  ),
                  child: _servicesSection(context, data),
                ),
                const SizedBox(height: 12),

                _sectionCard(
                  context,
                  title: AppStrings.pricing.tr,
                  trailing: TextButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.artisanServicesPricingView),
                    child: Text(
                      AppStrings.edit.tr,
                      style: TextStyle(color: _primary(context)),
                    ),
                  ),
                  child: _pricingSection(context, data),
                ),
                const SizedBox(height: 12),

                // _sectionCard(
                //   context,
                //   title: AppStrings.availability.tr,
                //   trailing: TextButton(
                //     onPressed: () =>
                //         Get.to(() => ArtisanAvailabilityView()),
                //     child: Text(
                //       AppStrings.edit.tr,
                //       style: TextStyle(color: _primary(context)),
                //     ),
                //   ),
                //   child: _availabilitySection(context, data),
                // ),
                // const SizedBox(height: 12),

                _sectionCard(
                  context,
                  title: AppStrings.portfolio.tr,
                  trailing: TextButton(
                    onPressed: () =>
                        Get.toNamed(AppRoutes.artisanPortfolioView),
                    child: Text(
                      AppStrings.add.tr,
                      style: TextStyle(color: _primary(context)),
                    ),
                  ),
                  child: _portfolioSection(context, data),
                ),
                const SizedBox(height: 12),

                _sectionCard(
                  context,
                  title: AppStrings.security.tr,
                  child: _securityActions(context),
                ),

                const SizedBox(height: 14),
                // _incompleteHints(context, data, completion),
              ],
            ),
          );
        }),
      ),
    );
  }

  // =========================
  // Header (Premium)
  // =========================
Widget _headerCard(BuildContext context) {
    return Obx(() {
      final data = controller.profile;

      final name = (data['name'] ?? '').toString();
      final profession = (data['profession'] ?? '').toString();
      final status = (data['status'] ?? '').toString();

      // ✅ أهم سطر: القيمة تتقرأ reactive
      final online = controller.isOnline;

      final avatarRaw = data['avatar']?.toString() ?? '';
      final avatar = _resolveAnyUrl(avatarRaw);

      final badgeColor = online ? Colors.green : Colors.redAccent;
      final toggling = controller.togglingStatus.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              _primary(context).withOpacity(0.95),
              const Color(0xFF60A5FA),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.10,
              ),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                _avatarCircle(context, avatar),
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: InkWell(
                    onTap: toggling
                        ? null
                        : () => controller.toggleOnline(!online),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: toggling
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              online
                                  ? Icons.wifi_tethering_rounded
                                  : Icons.wifi_off_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? AppStrings.name.tr : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profession.isEmpty ? AppStrings.profession.tr : profession,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        bg: Colors.white.withOpacity(0.18),
                        border: Colors.white.withOpacity(0.35),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: online
                                  ? Colors.limeAccent
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              online
                                  ? AppStrings.online.tr
                                  : AppStrings.offline.tr,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status.isNotEmpty)
                        _pill(
                          bg: Colors.white.withOpacity(0.14),
                          border: Colors.white.withOpacity(0.28),
                          child: Text(
                            status,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              children: [
                _headerBtn(
                  context,
                  icon: Icons.my_location_rounded,
                  label: AppStrings.setLocation.tr,
                  onTap: () =>
                      Get.toNamed(AppRoutes.artisanLocationSettingsView),
                ),
                const SizedBox(height: 8),
                _headerBtn(
                  context,
                  icon: Icons.lock_reset_rounded,
                  label: AppStrings.changePassword.tr,
                  onTap: () => Get.toNamed(AppRoutes.artisanChangePasswordView),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _profileCompletionSummary(
    BuildContext context, {
    required int completion,
    required VoidCallback? onCompleteTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _completionColor(completion);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline(context).withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.profileCompletionTitle.tr,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                AppStrings.profileCompletionPercentLabel.trParams(
                  {'percent': '$completion'},
                ),
                style: AppTextStyles.caption(context).copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              color: accent,
              backgroundColor: accent.withOpacity(0.18),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.profileCompletionSubtitle.tr,
                  style: AppTextStyles.small(context).copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onCompleteTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  AppStrings.profileCompletionCta.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _completionColor(int percent) {
    if (percent >= 100) return Colors.green;
    if (percent < 50) return Colors.redAccent;
    if (percent < 80) return Colors.orangeAccent;
    return Colors.orangeAccent;
  }


  Widget _avatarCircle(BuildContext context, String url) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.30)),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? const Icon(Icons.person, color: Colors.white, size: 38)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 38),
              ),
      ),
    );
  }

  Widget _headerBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required Color bg,
    required Color border,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  // =========================
  // Section Card Wrapper
  // =========================
  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline(context).withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // =========================
  // Stats Grid
  // =========================
  Widget _statsGrid(BuildContext context, Map<String, dynamic> data) {
    final portfolio = (data['portfolio'] as List?) ?? [];
    final completed =
        (data['stats']?['completedRequests'] ?? data['completedRequests'] ?? 0)
            as num;
    final avgRating = (data['stats']?['avgRating'] ?? data['rating'] ?? 0)
        .toString();
    final reviews =
        (data['stats']?['reviewsCount'] ?? data['reviewsCount'] ?? 0) as num;

    final cards = [
      _StatCard(
        title: AppStrings.requestsCompleted.tr,
        value: completed.toString(),
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _StatCard(
        title: AppStrings.rating.tr,
        value: avgRating,
        icon: Icons.star_rounded,
        color: Colors.amber,
      ),
      _StatCard(
        title: AppStrings.reviews.tr,
        value: reviews.toString(),
        icon: Icons.rate_review_rounded,
        color: Colors.orange,
      ),
      _StatCard(
        title: AppStrings.portfolio.tr,
        value: portfolio.length.toString(),
        icon: Icons.photo_library_rounded,
        color: Colors.blueAccent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (_, i) => cards[i],
    );
  }

  // =========================
  // About
  // =========================
  Widget _aboutSection(BuildContext context, Map<String, dynamic> data) {
    final desc = (data['description'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desc.isNotEmpty)
          Text(desc, style: AppTextStyles.body(context))
        else
          Text(AppStrings.noData.tr, style: _muted(context)),
        const SizedBox(height: 12),
        _infoRow(
          context,
          Icons.location_on_rounded,
          address.isEmpty ? AppStrings.noData.tr : address,
        ),
        _infoRow(
          context,
          Icons.phone_rounded,
          phone.isEmpty ? AppStrings.noData.tr : phone,
        ),
        _infoRow(
          context,
          Icons.email_rounded,
          email.isEmpty ? AppStrings.noData.tr : email,
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _surfaceV(context).withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _outline(context).withOpacity(0.12)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: _onSurface(context).withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(context))),
        ],
      ),
    );
  }

  // =========================
  // Services
  // =========================
  Widget _servicesSection(BuildContext context, Map<String, dynamic> data) {
    final services = (data['services'] as List?) ?? [];
    if (services.isEmpty)
      return Text(AppStrings.noData.tr, style: _muted(context));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((e) {
        final name = (e['name'] ?? '').toString();
        if (name.isEmpty) return const SizedBox();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _primary(context).withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _primary(context).withOpacity(0.25)),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: _primary(context),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // Pricing
  // =========================
  Widget _pricingSection(BuildContext context, Map<String, dynamic> data) {
    final pricing = (data['pricing'] as List?) ?? [];
    if (pricing.isEmpty)
      return Text(AppStrings.noData.tr, style: _muted(context));

    return Column(
      children: List.generate(pricing.length, (i) {
        final p = pricing[i] as Map;
        final service = (p['serviceName'] ?? '').toString();
        final min = (p['min'] ?? '').toString();
        final max = (p['max'] ?? '').toString();
        final currency = (p['currency'] ?? 'EGP').toString();

        return Container(
          margin: EdgeInsets.only(bottom: i == pricing.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surfaceV(context).withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _outline(context).withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sell_rounded,
                color: _onSurface(context).withOpacity(0.7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  service.isEmpty ? AppStrings.noData.tr : service,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primary(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _primary(context).withOpacity(0.22),
                  ),
                ),
                child: Text(
                  "$min - $max $currency",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _primary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // =========================
  // Availability
  // =========================
  Widget _availabilitySection(BuildContext context, Map<String, dynamic> data) {
    final slots = (data['availabilitySlots'] as List?) ?? [];
    final unavailable = data['unavailableUntil']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unavailable != null && unavailable.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.unavailableUntil.tr}: $unavailable',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (slots.isEmpty)
          Text(AppStrings.noData.tr, style: _muted(context))
        else
          Column(
            children: slots.map((s) {
              final day = (s['dayOfWeek'] ?? 0) as int;
              final from = (s['from'] ?? '').toString();
              final to = (s['to'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceV(context).withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _outline(context).withOpacity(0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: _onSurface(context).withOpacity(0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dayNameAr(day),
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text("$from - $to", style: _muted(context)),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // =========================
  // Portfolio (Preview nicer)
  // =========================
  Widget _portfolioSection(BuildContext context, Map<String, dynamic> data) {
    final portfolio = (data['portfolio'] as List?) ?? [];
    if (portfolio.isEmpty)
      return Text(AppStrings.noData.tr, style: _muted(context));

    final items = portfolio.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) {
        final item = items[i] as Map;
        final path = (item['path'] ?? item['image'] ?? '').toString();
        final desc = (item['description'] ?? '').toString();
        final url = _resolvePortfolioUrl(path);

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceV(context).withOpacity(0.45),
              border: Border.all(color: _outline(context).withOpacity(0.12)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: url.isEmpty
                      ? _portfolioPlaceholder(context)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _portfolioPlaceholder(context),
                        ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      desc.isEmpty ? AppStrings.noData.tr : desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _portfolioPlaceholder(BuildContext context) {
    return Container(
      color: _surface(context),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: _onSurface(context).withOpacity(0.35),
          size: 30,
        ),
      ),
    );
  }

  // =========================
  // Personal photos
  // =========================
  Widget _personalPhotosSection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final photos = _personalPhotos(data);
    if (photos.isEmpty)
      return Text(AppStrings.noData.tr, style: _muted(context));

    final display = photos.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: display.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final url = _resolveAnyUrl(display[i]);
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceV(context).withOpacity(0.45),
              border: Border.all(color: _outline(context).withOpacity(0.12)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: url.isEmpty
                ? _photoPlaceholder(context)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(context),
                  ),
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Container(
      color: _surface(context),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: _onSurface(context).withOpacity(0.35),
          size: 26,
        ),
      ),
    );
  }

  List<String> _personalPhotos(Map<String, dynamic> data) {
    final rawList = data['personalPhotos'] ??
        data['personalImages'] ??
        data['images'] ??
        data['photos'];
    final List<String> urls = [];

    if (rawList is List) {
      for (final item in rawList) {
        if (item is String) {
          if (item.trim().isNotEmpty) urls.add(item);
        } else if (item is Map) {
          final path = (item['path'] ??
                  item['image'] ??
                  item['url'] ??
                  item['avatar'] ??
                  '')
              .toString();
          if (path.trim().isNotEmpty) urls.add(path);
        }
      }
    }

    if (urls.isEmpty) {
      final avatar = (data['avatar'] ?? '').toString();
      if (avatar.isNotEmpty) urls.add(avatar);
    }

    return urls;
  }

  // =========================
  // Security actions
  // =========================
  Widget _securityActions(BuildContext context) {
    return Column(
      children: [
        _actionTile(
          context,
          icon: Icons.lock_reset_rounded,
          title: AppStrings.changePassword.tr,
          onTap: () => Get.toNamed(AppRoutes.artisanChangePasswordView),
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceV(context).withOpacity(0.30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _outline(context).withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _primary(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _onSurface(context).withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Hints if incomplete
  // =========================
  Widget _incompleteHints(
    BuildContext context,
    Map<String, dynamic> data,
    int completion,
  ) {
    final services = (data['services'] as List?) ?? [];
    final portfolio = (data['portfolio'] as List?) ?? [];

    if (completion >= 100) return const SizedBox.shrink();
    if (services.isNotEmpty && portfolio.isNotEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (services.isEmpty)
          _hint(
            context,
            '${AppStrings.servicesLabel.tr}: ${AppStrings.noData.tr}',
          ),
        if (portfolio.isEmpty)
          _hint(context, '${AppStrings.portfolio.tr}: ${AppStrings.noData.tr}'),
      ],
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // URL helpers
  // =========================
  String _resolveAnyUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return _resolvePortfolioUrl(raw);
  }

  String _resolvePortfolioUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;

    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;

    final baseNoApi = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;

    if (raw.startsWith('/uploads')) return '$baseNoApi$raw';
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/$raw';
  }

  String _dayNameAr(int d) {
    const names = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    if (d < 0 || d > 6) return 'يوم';
    return names[d];
  }
}

// =======================
// Stat Card (clean)
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(
          scheme.brightness == Brightness.dark ? 0.35 : 0.55,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


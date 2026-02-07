// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/api_endpoints.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/widgets/app_snackbar.dart';
import 'package:usta/Artisan/features/artisan/portfolio/controllers/portfolio_controller.dart';
import 'package:usta/Artisan/features/artisan/portfolio/views/artisan_add_portfolio_view.dart';

class ArtisanPortfolioView extends StatefulWidget {
  const ArtisanPortfolioView({super.key});

  @override
  State<ArtisanPortfolioView> createState() => _ArtisanPortfolioViewState();
}

class _ArtisanPortfolioViewState extends State<ArtisanPortfolioView> {
  Color get primaryBlue => const Color(0xFF2563EB);

  final PortfolioController controller = Get.find<PortfolioController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadFromProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.quickActionsPortfolio.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadFromProfile(),
          ),
          IconButton(
            tooltip: 'إضافة',
            onPressed: () => Get.to(() => const ArtisanAddPortfolioView()),
            icon: const Icon(Icons.add_photo_alternate),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() {
        final loading = controller.loading.value;
        final items = controller.items;

        if (loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          color: primaryBlue,
          onRefresh: () async => controller.loadFromProfile(),
          child: items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.photo_library_outlined,
                      size: 56,
                      color: scheme.onSurface.withOpacity(0.25),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        AppStrings.noData.tr,
                        style: AppTextStyles.body(context).copyWith(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'اسحب لتحديث',
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .86,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemBuilder: (context, index) {
                      return _portfolioItem(items[index], index);
                    },
                  ),
                ),
        );
      }),
    );
  }

  Widget _portfolioItem(Map<String, dynamic> item, int index) {
    final scheme = Theme.of(context).colorScheme;

    final id = (item['id'] ?? item['_id'] ?? '').toString();
    final desc = (item['description'] ?? '').toString();

    final rawPath = (item['image'] ?? item['path'] ?? item['url'] ?? '')
        .toString();

    final imageUrl = _resolvePortfolioUrl(rawPath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openImageViewer(
          imageUrl: imageUrl,
          desc: desc,
          heroTag: 'portfolio_$index',
        ),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withOpacity(0.15)),
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Hero(
                        tag: 'portfolio_$index',
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _brokenPlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: scheme.surfaceVariant.withOpacity(
                                scheme.brightness == Brightness.dark
                                    ? 0.25
                                    : 0.7,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryBlue,
                                    value: progress.expectedTotalBytes == null
                                        ? null
                                        : progress.cumulativeBytesLoaded /
                                              (progress.expectedTotalBytes ??
                                                  1),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : _brokenPlaceholder(),
              ),

              // Description overlay
              if (desc.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                    child: Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // Delete button
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _confirmDelete(id: id, desc: desc),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brokenPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 44,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }

  Future<void> _confirmDelete({
    required String id,
    required String desc,
  }) async {
    if (id.isEmpty) {
      AppSnackBar.show(
        AppStrings.error.tr,
        AppStrings.portfolioMissingId.tr,
        type: SnackBarType.error,
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('حذف الصورة', style: AppTextStyles.title(context)),
        content: Text(
          desc.isEmpty ? 'هل تريد حذف هذه الصورة؟' : 'هل تريد حذف: "$desc" ؟',
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel.tr, style: AppTextStyles.body(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'حذف',
              style: AppTextStyles.body(context).copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      controller.deletePortfolio(id);
    }
  }

  void _openImageViewer({
    required String imageUrl,
    required String desc,
    required String heroTag,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outline.withOpacity(0.15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: imageUrl.isNotEmpty
                            ? InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: Hero(
                                  tag: heroTag,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 120,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const Center(child: Icon(Icons.image, size: 120)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 13,
                          color: scheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                  ],
                ),
              ),

              // Close button
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolvePortfolioUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;

    // baseUrl may be like: https://domain.com/api
    final base = ApiEndpoints.baseUrl.endsWith('/')
        ? ApiEndpoints.baseUrl.substring(0, ApiEndpoints.baseUrl.length - 1)
        : ApiEndpoints.baseUrl;

    final baseNoApi = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;

    // common paths
    if (raw.startsWith('/')) return '$baseNoApi$raw';
    return '$baseNoApi/$raw';
  }
}


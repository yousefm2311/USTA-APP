import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/verification/artisan_verification_guard_service.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';

enum VerificationPreviewType { document, selfie }

class VerificationScaffold extends StatelessWidget {
  const VerificationScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.child,
  });

  final String title;
  final String subtitle;
  final int currentStep;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvoked: (_) {
          if (Get.isRegistered<ArtisanVerificationGuardService>()) {
            Get.find<ArtisanVerificationGuardService>().syncAndEnforce(
              refreshFromServer: false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: _VerificationPalette.pageBackground,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                _VerificationHeader(title: title, subtitle: subtitle),
                const SizedBox(height: 18),
                VerificationStepIndicator(currentStep: currentStep),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerificationStepIndicator extends StatelessWidget {
  const VerificationStepIndicator({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppStrings.kycStepId.tr,
      AppStrings.kycStepSelfie.tr,
      AppStrings.kycStepStatus.tr,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _VerificationPalette.border),
      ),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final connectorIndex = index ~/ 2;
            final isCompleted = connectorIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? _VerificationPalette.primary
                      : _VerificationPalette.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCurrent = stepIndex == currentStep;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isCurrent ? 32 : 26,
                  height: isCurrent ? 32 : 26,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? _VerificationPalette.primary
                        : _VerificationPalette.softSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent || isCompleted
                          ? _VerificationPalette.primary
                          : _VerificationPalette.border,
                      width: isCurrent ? 1.8 : 1.2,
                    ),
                    boxShadow: isCurrent
                        ? const [
                            BoxShadow(
                              color: Color(0x1A2563EB),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : _VerificationPalette.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[stepIndex],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? _VerificationPalette.textPrimary
                        : _VerificationPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class VerificationStatusBanner extends StatelessWidget {
  const VerificationStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    this.secondaryMessage,
    this.color = const Color(0xFFB45309),
    this.backgroundColor = const Color(0xFFFFF7ED),
  });

  final String message;
  final String? secondaryMessage;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _VerificationPalette.textPrimary,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondaryMessage != null &&
                    secondaryMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _VerificationPalette.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationRequirementsOverview extends StatelessWidget {
  const VerificationRequirementsOverview({
    super.key,
    required this.completedCount,
    required this.items,
  });

  final int completedCount;
  final List<VerificationRequirementItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _VerificationPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.kycRequiredImagesTitle.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _VerificationPalette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.kycCaptureChecklistBody.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _VerificationPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _VerificationPalette.softPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppStrings.kycDocumentsReadyStatus.trParams({
                    'count': '$completedCount',
                  }),
                  style: const TextStyle(
                    color: _VerificationPalette.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(
                      bottom: item == items.last ? 0 : 10,
                    ),
                    child: _RequirementRow(item: item),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class VerificationRequirementItem {
  const VerificationRequirementItem({
    required this.label,
    required this.ready,
    required this.icon,
  });

  final String label;
  final bool ready;
  final IconData icon;
}

class VerificationImageCard extends StatelessWidget {
  const VerificationImageCard({
    super.key,
    required this.title,
    required this.description,
    required this.previewBytes,
    required this.icon,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.previewType,
    this.badgeLabel,
  });

  final String title;
  final String description;
  final Uint8List? previewBytes;
  final IconData icon;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VerificationPreviewType previewType;
  final String? badgeLabel;

  bool get _hasImage => previewBytes != null && previewBytes!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hints = _buildHints();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _VerificationPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeLabel != null) ...[
            Text(
              badgeLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _VerificationPalette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _VerificationPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _VerificationPalette.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: previewType == VerificationPreviewType.document
                ? 1.58
                : 0.92,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasImage
                      ? _VerificationPalette.primary.withOpacity(0.24)
                      : _VerificationPalette.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_hasImage)
                    Image.memory(
                      previewBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PreviewFallback(
                        icon: Icons.broken_image_outlined,
                        title: AppStrings.filePickFailed.tr,
                        subtitle: description,
                      ),
                    )
                  else
                    _PreviewFallback(
                      icon: icon,
                      title: previewType == VerificationPreviewType.document
                          ? AppStrings.kycPreviewDocument.tr
                          : AppStrings.kycPreviewSelfie.tr,
                      subtitle: previewType == VerificationPreviewType.document
                          ? AppStrings.kycDocumentGuide.tr
                          : AppStrings.kycSelfieGuide.tr,
                    ),
                  IgnorePointer(
                    child: _PreviewGuide(type: previewType, active: _hasImage),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: _PreviewStateChip(hasImage: _hasImage),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: hints
                .map(
                  (hint) => Padding(
                    padding: EdgeInsets.only(
                      bottom: hint == hints.last ? 0 : 8,
                    ),
                    child: _HintRow(text: hint),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPickCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: _VerificationPalette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(
                AppStrings.kycUseCamera.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onPickGallery,
              style: TextButton.styleFrom(
                foregroundColor: _VerificationPalette.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(
                AppStrings.kycUseGallery.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildHints() {
    if (previewType == VerificationPreviewType.document) {
      return [description, AppStrings.kycDocumentGuide.tr];
    }

    return [description, AppStrings.kycSelfieGuide.tr];
  }
}

class VerificationPrimaryButton extends StatelessWidget {
  const VerificationPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _VerificationPalette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class VerificationSecondaryButton extends StatelessWidget {
  const VerificationSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _VerificationPalette.textPrimary,
          side: const BorderSide(color: _VerificationPalette.border),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _VerificationPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _VerificationPalette.softPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: _VerificationPalette.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _VerificationPalette.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _VerificationPalette.textSecondary,
                    height: 1.55,
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

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.item});

  final VerificationRequirementItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: item.ready
            ? const Color(0xFFF0FDF4)
            : _VerificationPalette.softSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            item.ready ? Icons.check_circle_rounded : item.icon,
            size: 18,
            color: item.ready
                ? const Color(0xFF16A34A)
                : _VerificationPalette.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: _VerificationPalette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            item.ready ? AppStrings.ok.tr : AppStrings.next.tr,
            style: TextStyle(
              color: item.ready
                  ? const Color(0xFF15803D)
                  : _VerificationPalette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: _VerificationPalette.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _VerificationPalette.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: _VerificationPalette.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _VerificationPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _VerificationPalette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStateChip extends StatelessWidget {
  const _PreviewStateChip({required this.hasImage});

  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final background = hasImage
        ? const Color(0xFFECFDF5)
        : Colors.white.withOpacity(0.92);
    final foreground = hasImage
        ? const Color(0xFF166534)
        : _VerificationPalette.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasImage
              ? const Color(0xFFBBF7D0)
              : Colors.white.withOpacity(0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasImage ? Icons.check_circle_rounded : Icons.image_outlined,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            hasImage
                ? AppStrings.kycReadyToUpload.tr
                : AppStrings.kycNoImageSelected.tr,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewGuide extends StatelessWidget {
  const _PreviewGuide({required this.type, required this.active});

  final VerificationPreviewType type;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final borderColor = active
        ? Colors.white.withOpacity(0.88)
        : _VerificationPalette.primary.withOpacity(0.5);
    final fillColor = active
        ? Colors.black.withOpacity(0.05)
        : _VerificationPalette.primary.withOpacity(0.04);

    if (type == VerificationPreviewType.selfie) {
      return Center(
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 232,
        height: 148,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
        ),
      ),
    );
  }
}

class _VerificationPalette {
  static const Color pageBackground = Color(0xFFF6F7FB);
  static const Color softSurface = Color(0xFFF8FAFC);
  static const Color softPrimary = Color(0xFFEFF4FF);
  static const Color primary = AppColors.primary;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFD9E2EC);
}

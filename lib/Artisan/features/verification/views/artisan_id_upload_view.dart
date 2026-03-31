import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_camera_view.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_ui.dart';

class ArtisanIdUploadView extends GetView<ArtisanVerificationController> {
  const ArtisanIdUploadView({super.key});

  Future<void> _captureFront() async {
    final result = await Get.toNamed(
      AppRoutes.artisanVerificationCameraView,
      arguments: {
        'mode': VerificationCaptureMode.document,
        'screenTitle': AppStrings.kycIdFrontLabel.tr,
        'screenHint': AppStrings.kycIdFrontHint.tr,
        'frameLabel': AppStrings.kycFrontSideShort.tr,
      },
    );
    final file = result is XFile ? result : null;
    await controller.setIdFrontFile(file);
  }

  Future<void> _captureBack() async {
    final result = await Get.toNamed(
      AppRoutes.artisanVerificationCameraView,
      arguments: {
        'mode': VerificationCaptureMode.document,
        'screenTitle': AppStrings.kycIdBackLabel.tr,
        'screenHint': AppStrings.kycIdBackHint.tr,
        'frameLabel': AppStrings.kycBackSideShort.tr,
      },
    );
    final file = result is XFile ? result : null;
    await controller.setIdBackFile(file);
  }

  Future<void> _pickFrontFromGallery() async {
    final rawFile = await controller.pickVerificationImage(
      ImageSource.gallery,
      selfie: false,
    );
    if (rawFile == null) return;

    final result = await Get.toNamed(
      AppRoutes.artisanVerificationDocumentCropView,
      arguments: {
        'file': rawFile,
        'screenTitle': AppStrings.kycIdFrontLabel.tr,
        'screenHint': AppStrings.kycAdjustDocumentCrop.tr,
        'frameLabel': AppStrings.kycFrontSideShort.tr,
      },
    );
    final file = result is XFile ? result : null;
    await controller.setIdFrontFile(file);
  }

  Future<void> _pickBackFromGallery() async {
    final rawFile = await controller.pickVerificationImage(
      ImageSource.gallery,
      selfie: false,
    );
    if (rawFile == null) return;

    final result = await Get.toNamed(
      AppRoutes.artisanVerificationDocumentCropView,
      arguments: {
        'file': rawFile,
        'screenTitle': AppStrings.kycIdBackLabel.tr,
        'screenHint': AppStrings.kycAdjustDocumentCrop.tr,
        'frameLabel': AppStrings.kycBackSideShort.tr,
      },
    );
    final file = result is XFile ? result : null;
    await controller.setIdBackFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return VerificationScaffold(
      title: AppStrings.kycIdTitle.tr,
      subtitle: AppStrings.kycIdSubtitle.tr,
      currentStep: 0,
      child: Obx(() {
        final frontReady = controller.idFrontBytes.value != null;
        final backReady = controller.idBackBytes.value != null;
        final completedCount = (frontReady ? 1 : 0) + (backReady ? 1 : 0);
        final frontCard = VerificationImageCard(
          title: AppStrings.kycIdFrontLabel.tr,
          description: AppStrings.kycIdFrontHint.tr,
          previewBytes: controller.idFrontBytes.value,
          icon: Icons.badge_outlined,
          previewType: VerificationPreviewType.document,
          badgeLabel: AppStrings.kycFrontSideShort.tr,
          onPickCamera: _captureFront,
          onPickGallery: _pickFrontFromGallery,
        );
        final backCard = VerificationImageCard(
          title: AppStrings.kycIdBackLabel.tr,
          description: AppStrings.kycIdBackHint.tr,
          previewBytes: controller.idBackBytes.value,
          icon: Icons.credit_card_outlined,
          previewType: VerificationPreviewType.document,
          badgeLabel: AppStrings.kycBackSideShort.tr,
          onPickCamera: _captureBack,
          onPickGallery: _pickBackFromGallery,
        );

        return Column(
          children: [
            VerificationRequirementsOverview(
              completedCount: completedCount,
              items: [
                VerificationRequirementItem(
                  label: AppStrings.kycFrontSideShort.tr,
                  ready: frontReady,
                  icon: Icons.badge_outlined,
                ),
                VerificationRequirementItem(
                  label: AppStrings.kycBackSideShort.tr,
                  ready: backReady,
                  icon: Icons.credit_card_outlined,
                ),
              ],
            ),
            if (!controller.canRetry || controller.isCooldownActive) ...[
              VerificationStatusBanner(
                icon: Icons.warning_amber_rounded,
                message: controller.isCooldownActive
                    ? AppStrings.kycRetryCooldown.trParams({
                        'seconds': '${controller.cooldownRemaining}',
                      })
                    : AppStrings.kycAttemptsLimitReached.tr,
                secondaryMessage:
                    controller.isCooldownActive &&
                        controller.retryAvailabilityLabel().isNotEmpty
                    ? AppStrings.kycRetryAvailableAt.trParams({
                        'time': controller.retryAvailabilityLabel(),
                      })
                    : null,
              ),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 760) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: frontCard),
                      const SizedBox(width: 16),
                      Expanded(child: backCard),
                    ],
                  );
                }

                return Column(
                  children: [frontCard, const SizedBox(height: 16), backCard],
                );
              },
            ),
            const SizedBox(height: 18),
            VerificationPrimaryButton(
              label: AppStrings.kycUploadIdsButton.tr,
              loading: controller.uploadingIds.value,
              onPressed:
                  controller.uploadingIds.value ||
                      !controller.canRetry ||
                      controller.isCooldownActive
                  ? null
                  : controller.submitIdImages,
            ),
          ],
        );
      }),
    );
  }
}

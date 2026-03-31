import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_camera_view.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_ui.dart';

class ArtisanSelfieVerificationView
    extends GetView<ArtisanVerificationController> {
  const ArtisanSelfieVerificationView({super.key});

  Future<void> _captureSelfie() async {
    final result = await Get.toNamed(
      AppRoutes.artisanVerificationCameraView,
      arguments: {
        'mode': VerificationCaptureMode.selfie,
        'screenTitle': AppStrings.kycSelfieCaptureLabel.tr,
        'screenHint': AppStrings.kycSelfieHint.tr,
        'frameLabel': AppStrings.kycSelfieCaptureLabel.tr,
      },
    );
    final file = result is XFile ? result : null;
    await controller.setSelfieFile(file);
  }

  Future<void> _pickSelfieFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    await controller.setSelfieFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return VerificationScaffold(
      title: AppStrings.kycSelfieTitle.tr,
      subtitle: AppStrings.kycSelfieSubtitle.tr,
      currentStep: 1,
      child: Obx(
        () => Column(
          children: [
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
            VerificationImageCard(
              title: AppStrings.kycSelfieCaptureLabel.tr,
              description: AppStrings.kycSelfieHint.tr,
              previewBytes: controller.selfieBytes.value,
              icon: Icons.face_outlined,
              previewType: VerificationPreviewType.selfie,
              onPickCamera: _captureSelfie,
              onPickGallery: _pickSelfieFromGallery,
            ),
            const SizedBox(height: 18),
            VerificationPrimaryButton(
              label: AppStrings.kycUploadSelfieButton.tr,
              loading: controller.uploadingSelfie.value,
              onPressed:
                  controller.uploadingSelfie.value ||
                      !controller.canRetry ||
                      controller.isCooldownActive
                  ? null
                  : controller.submitSelfie,
            ),
          ],
        ),
      ),
    );
  }
}

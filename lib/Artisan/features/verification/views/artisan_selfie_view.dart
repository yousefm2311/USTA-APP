import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_widgets.dart';

class ArtisanSelfieVerificationView extends GetView<ArtisanVerificationController> {
  const ArtisanSelfieVerificationView({super.key});

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  controller.isCooldownActive
                      ? AppStrings.kycRetryCooldown.trParams({
                          'seconds': '${controller.cooldownRemaining}',
                        })
                      : AppStrings.kycAttemptsLimitReached.tr,
                ),
              ),
            ],
            VerificationImageCard(
              title: AppStrings.kycSelfieCaptureLabel.tr,
              description: AppStrings.kycSelfieHint.tr,
              filePath: controller.selfie.value?.path,
              icon: Icons.face_outlined,
              onPickCamera: () => controller.pickSelfie(ImageSource.camera),
              onPickGallery: () => controller.pickSelfie(ImageSource.gallery),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.uploadingSelfie.value ||
                        !controller.canRetry ||
                        controller.isCooldownActive
                    ? null
                    : controller.submitSelfie,
                child: controller.uploadingSelfie.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.kycUploadSelfieButton.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_widgets.dart';

class ArtisanIdUploadView extends GetView<ArtisanVerificationController> {
  const ArtisanIdUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return VerificationScaffold(
      title: AppStrings.kycIdTitle.tr,
      subtitle: AppStrings.kycIdSubtitle.tr,
      currentStep: 0,
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
              if (controller.isCooldownActive &&
                  controller.retryAvailabilityLabel().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.kycRetryAvailableAt.trParams({
                        'time': controller.retryAvailabilityLabel(),
                      }),
                    ),
                  ),
                ),
            ],
            VerificationImageCard(
              title: AppStrings.kycIdFrontLabel.tr,
              description: AppStrings.kycIdFrontHint.tr,
              filePath: controller.idFront.value?.path,
              icon: Icons.badge_outlined,
              onPickCamera: () => controller.pickIdFront(ImageSource.camera),
              onPickGallery: () => controller.pickIdFront(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            VerificationImageCard(
              title: AppStrings.kycIdBackLabel.tr,
              description: AppStrings.kycIdBackHint.tr,
              filePath: controller.idBack.value?.path,
              icon: Icons.credit_card_outlined,
              onPickCamera: () => controller.pickIdBack(ImageSource.camera),
              onPickGallery: () => controller.pickIdBack(ImageSource.gallery),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.uploadingIds.value ||
                        !controller.canRetry ||
                        controller.isCooldownActive
                    ? null
                    : controller.submitIdImages,
                child: controller.uploadingIds.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.kycUploadIdsButton.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

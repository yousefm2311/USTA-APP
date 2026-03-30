import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_widgets.dart';

class ArtisanVerificationStatusView extends GetView<ArtisanVerificationController> {
  const ArtisanVerificationStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return VerificationScaffold(
      title: AppStrings.kycStatusTitle.tr,
      subtitle: AppStrings.kycStatusSubtitle.tr,
      currentStep: 2,
      child: Obx(() {
        final status = controller.verificationStatus;
        final isVerified = controller.isVerified;
        final remaining = controller.attemptsRemaining;

        IconData icon;
        Color color;
        String headline;
        String description;

        if (isVerified) {
          icon = Icons.verified_user_outlined;
          color = AppColors.success;
          headline = AppStrings.kycVerifiedHeadline.tr;
          description = AppStrings.kycVerifiedBody.tr;
        } else {
          icon = Icons.hourglass_top_rounded;
          color = AppColors.warning;
          headline = AppStrings.kycProcessingHeadline.tr;
          description = status == 'selfie_uploaded'
              ? AppStrings.kycSelfieSubmittedBody.tr
              : AppStrings.kycProcessingBody.tr;
        }

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD7DFEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, size: 34, color: color),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                headline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
              ),
              if (!isVerified) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    AppStrings.kycAttemptsRemaining.trParams({
                      'count': '$remaining',
                    }),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.continueFromStatus,
                  child: Text(
                    isVerified
                        ? AppStrings.kycGoToHome.tr
                        : AppStrings.kycRefreshStatus.tr,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.loadingStatus.value
                      ? null
                      : controller.refreshStatus,
                  child: controller.loadingStatus.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppStrings.kycRefreshStatus.tr),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

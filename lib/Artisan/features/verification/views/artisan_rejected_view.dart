import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_colors.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/verification/controllers/artisan_verification_controller.dart';
import 'package:usta/Artisan/features/verification/views/artisan_verification_ui.dart';

class ArtisanVerificationRejectedView
    extends GetView<ArtisanVerificationController> {
  const ArtisanVerificationRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return VerificationScaffold(
      title: AppStrings.kycRejectedTitle.tr,
      subtitle: AppStrings.kycRejectedSubtitle.tr,
      currentStep: 2,
      child: Obx(() {
        final canRetry = controller.canRetry && !controller.isCooldownActive;
        final retryAction = controller.retryAction;
        final problemType = controller.problemType;
        final reason =
            controller.failureReason ?? AppStrings.kycVerificationFailed.tr;
        final categoryLabel = controller.rejectionCategoryLabel();

        String issueLabel;
        switch (problemType) {
          case 'document_issue':
            issueLabel = AppStrings.kycProblemDocument.tr;
            break;
          case 'selfie_issue':
            issueLabel = AppStrings.kycProblemSelfie.tr;
            break;
          case 'face_mismatch':
            issueLabel = AppStrings.kycProblemFace.tr;
            break;
          default:
            issueLabel = AppStrings.kycProblemUnknown.tr;
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
                  backgroundColor: AppColors.error.withOpacity(0.12),
                  child: const Icon(
                    Icons.gpp_bad_outlined,
                    size: 34,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.kycFailedHeadline.tr,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                reason,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.kycIssueTypeLabel.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categoryLabel.isNotEmpty ? categoryLabel : issueLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.isCooldownActive
                          ? AppStrings.kycRetryCooldown.trParams({
                              'seconds': '${controller.cooldownRemaining}',
                            })
                          : AppStrings.kycAttemptsRemaining.trParams({
                              'count': '${controller.attemptsRemaining}',
                            }),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (controller.isCooldownActive &&
                        controller.retryAvailabilityLabel().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.kycRetryAvailableAt.trParams({
                          'time': controller.retryAvailabilityLabel(),
                        }),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (retryAction == 'documents' || retryAction == 'both')
                VerificationPrimaryButton(
                  label: AppStrings.kycRetryDocuments.tr,
                  onPressed: canRetry ? controller.retryDocuments : null,
                ),
              if (retryAction == 'documents' || retryAction == 'both')
                const SizedBox(height: 10),
              if (retryAction == 'selfie' || retryAction == 'both')
                VerificationSecondaryButton(
                  label: AppStrings.kycRetrySelfie.tr,
                  onPressed: canRetry ? controller.retrySelfie : null,
                ),
              if (retryAction == 'both') ...[
                const SizedBox(height: 10),
                VerificationSecondaryButton(
                  label: AppStrings.kycRetryBoth.tr,
                  onPressed: canRetry ? controller.continueFromRejected : null,
                ),
              ],
              const SizedBox(height: 10),
              VerificationSecondaryButton(
                label: AppStrings.kycRefreshStatus.tr,
                loading: controller.loadingStatus.value,
                onPressed: controller.loadingStatus.value
                    ? null
                    : controller.refreshStatus,
              ),
            ],
          ),
        );
      }),
    );
  }
}

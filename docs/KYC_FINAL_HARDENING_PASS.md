# Usta KYC Final Hardening Pass

Date: 2026-03-30

## Scope

This pass hardened the existing production KYC implementation without changing the current architecture:

- Flutter app: `GetX + Dio`
- Backend: `Node.js + Express + MongoDB`
- Admin panel: existing artisan details flow

No KYC flow was rebuilt from scratch. Existing routes, guards, and screens were preserved and tightened.

## Final Production Audit Additions

This final audit layer focused on production exposure risks and UX edge cases that remained after the hardening pass:

- sanitized KYC responses so self, admin, and public consumers only receive the fields they actually need
- removed internal-only data from API errors and generic artisan payloads
- redacted sensitive log metadata before persistence
- made private file writes atomic to reduce partial writes and orphaned temp files
- polished timeout, offline, session-expiry, back-navigation, and image-preview behavior in the Flutter app
- tightened admin review UX with action loading state and safer verification image rendering

## Backend

### What changed

- Added production-safe rate limiting for:
  - `POST /api/artisan/verification/upload-id`
  - `POST /api/artisan/verification/upload-selfie`
- Unified rejection categories through a normalized enum:
  - `id_blurry`
  - `id_invalid`
  - `face_mismatch`
  - `face_not_clear`
  - `fraud_suspected`
- Added user-safe rejection messages and retry-action mapping based on rejection category.
- Hardened auto-approve logic so high-confidence approval is controlled only by:
  - `KYC_AUTO_APPROVE_HIGH_CONFIDENCE=true`
- Added lightweight KYC event hooks:
  - `id_uploaded`
  - `selfie_uploaded`
  - `verification_approved`
  - `verification_rejected`
- Added a small KYC record service abstraction to prepare future migration to a separate KYC collection without refactoring the whole data model today.
- Improved structured KYC error payloads for:
  - `403`
  - `409`
  - `422`
  - `429`
- Extended admin image audit logging with:
  - `adminId`
  - `artisanId`
  - `imageType`
  - `timestamp`
  - `ipAddress`
- Added audience-aware response sanitization so:
  - public artisan listings do not expose KYC internals
  - artisan self endpoints do not expose internal review notes or storage paths
  - admin endpoints avoid leaking raw storage paths and unnecessary private fields
- Sanitized KYC error `details` payloads before returning them to clients.
- Redacted sensitive values from activity log metadata before writing audit records.
- Switched private upload writes to temp-file-plus-rename semantics to reduce partial-file and overwrite edge cases.
- Enriched KYC event payloads with:
  - `event`
  - `occurredAt`
  - `userId`
  - `previousStatus`
  - `nextStatus`
  - `source`

### Files changed

- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/admin/verifications.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/artisan/artisan.verification.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/errors/apiError.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/middlewares/artisan/kycRateLimit.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/middlewares/artisan/requireVerifiedArtisan.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/middlewares/artisan/verificationUpload.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/models/activityLog.model.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/models/artisan.model.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/routes/admin/admin.routes.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/routes/artisan/artisan.routes.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/services/kyc/faceVerification.service.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/services/kyc/kycEvents.service.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/services/kyc/kycRecord.service.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/artisan/kycRejection.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/artisan/kycResponse.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/artisan/kycState.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/shared/activityLogger.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/shared/privateUploads.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/utils/shared/requestValidation.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/middlewares/shared/error.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/admin/artisans.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/customer/customer.favorites.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/customer/explore.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/src/controllers/artisan/artisan.controller.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/test/auth.validation.test.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/test/faceVerification.test.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/test/kyc.rejection.test.js`
- `/home/yousef/Desktop/Projects/Usta-Backend/test/kyc.state.test.js`

## Flutter App

### What changed

- Extended the KYC client error contract to understand backend `code` and `details`.
- Mapped normalized rejection categories into stable artisan-facing messages.
- Improved blocked/cooldown handling so the app can show:
  - temporary block state
  - cooldown seconds
  - next retry time when provided
- Added explicit handling for:
  - network loss during upload
  - request timeouts
  - expired sessions
  - camera permission failures
- Prevented back-button stack bypass from KYC screens by re-running the existing guard instead of allowing raw pop navigation.
- Added safer image preview fallback when temporary local image files are no longer available after app lifecycle interruptions.
- Preserved the existing KYC screens and routing logic, but made the UI behavior more consistent with the backend response contract.

### Files changed

- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/core/services/network/api_client.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/core/utils/constants/app_strings.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/core/utils/constants/app_translations.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/features/verification/controllers/artisan_verification_controller.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/features/verification/views/artisan_verification_widgets.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/features/verification/views/artisan_id_upload_view.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/features/verification/views/artisan_rejected_view.dart`
- `/home/yousef/Desktop/Projects/Merge-Usta/lib/Artisan/features/verification/views/artisan_selfie_view.dart`

## Admin Panel

### What changed

- Added KYC review support inside the existing artisan details page.
- Loaded verification details from the existing admin verification endpoints.
- Added display for:
  - verification status
  - confidence
  - attempts
  - rejection category
  - rejection reason
  - reviewedBy / reviewedAt
- Added secure image preview for:
  - ID front
  - ID back
  - selfie
- Added admin override controls:
  - approve verification
  - reject verification with category and optional notes
- Improved artisan status display in list/details to reflect KYC stages like:
  - `documents_uploaded`
  - `selfie_uploaded`
  - `under_review`
- Added action-level loading protection to avoid duplicate approve/reject submissions.
- Added a loading placeholder for secure verification image previews so failures and slow responses are handled more gracefully.

### Files changed

- `/home/yousef/Desktop/Projects/usta_admin_panal/lib/widgets/modules/artisans/controllers/artisan_details_controller.dart`
- `/home/yousef/Desktop/Projects/usta_admin_panal/lib/widgets/modules/artisans/services/artisans_service.dart`
- `/home/yousef/Desktop/Projects/usta_admin_panal/lib/widgets/modules/artisans/views/artisan_details_view.dart`
- `/home/yousef/Desktop/Projects/usta_admin_panal/lib/widgets/modules/artisans/views/artisans_list_view.dart`

## Verification

- Backend syntax: `npm run check:syntax` passed
- Backend tests: `npm test` passed, `22` tests passed
- Flutter app analysis: `flutter analyze` passed
- Flutter app tests: `flutter test` passed, `17` tests passed
- Admin targeted analysis: `dart analyze .../lib/widgets/modules/artisans/...` passed with no issues

## Admin Panel Note

`flutter analyze` in the admin panel still reports pre-existing unrelated warnings in files outside the KYC scope, including:

- `lib/core/services/api_exceptions.dart`
- `lib/modules/analytics/controllers/analytics_controller.dart`
- `lib/modules/customers/services/customers_service.dart`
- `lib/modules/customers/views/customer_details_view.dart`
- `lib/modules/marketing/views/rewards_view.dart`
- `tool/scaffold_admin_structure.dart`

No new analyzer problems were left in the KYC admin files touched in this pass.

## Important compatibility note

The admin panel worktree already had a modified `pubspec.lock`. It was left as-is and was not intentionally rewritten as part of this KYC hardening pass.

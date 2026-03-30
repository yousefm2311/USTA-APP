# Usta Artisan KYC Implementation Report

## Overview

This release adds a production-ready artisan-only identity verification flow to the Flutter application while preserving the app's existing architecture and navigation patterns.

Important implementation decision:

- The current Flutter codebase is built around `GetX`, not Riverpod.
- To avoid destabilizing the production app, the KYC feature was implemented in the existing `GetX + Dio` stack instead of introducing a state-management migration mid-release.
- Camera capture is supported through `image_picker` using `ImageSource.camera`, which fits the current app dependencies and lowers integration risk.

## What Was Added

### 1. Artisan-only KYC route resolution

Added a dedicated verification route resolver that decides where the artisan should land:

- `verificationStep = 0` -> ID upload screen
- `verificationStep = 1` -> Selfie screen
- `verificationStep = 2` -> Verification status screen
- `identityVerified = true` -> Home

Files:

- `lib/Artisan/core/utils/kyc/artisan_verification_route.dart`
- `lib/Artisan/main.dart`
- `lib/Artisan/features/auth/controllers/auth_controller.dart`

### 2. New KYC networking support

Added multipart upload support for the artisan app and wired the new backend endpoints:

- `GET /api/artisan/verification/status`
- `POST /api/artisan/verification/upload-id`
- `POST /api/artisan/verification/upload-selfie`

Files:

- `lib/Artisan/core/services/network/api_client.dart`
- `lib/Artisan/core/utils/constants/api_endpoints.dart`
- `lib/Artisan/data/providers/artisan_api.dart`

### 3. KYC controller + screens

Added a dedicated controller and three artisan screens:

- ID upload
- Selfie capture/upload
- Verification status / retry / continue

Files:

- `lib/Artisan/features/verification/controllers/artisan_verification_controller.dart`
- `lib/Artisan/features/verification/views/artisan_id_upload_view.dart`
- `lib/Artisan/features/verification/views/artisan_selfie_view.dart`
- `lib/Artisan/features/verification/views/artisan_verification_status_view.dart`
- `lib/Artisan/features/verification/views/artisan_verification_widgets.dart`

### 4. Route and dependency registration

Wired the new KYC feature into the artisan app bindings and route table.

Files:

- `lib/Artisan/core/utils/bindings/binding.dart`
- `lib/Artisan/core/utils/routes/routes.dart`

### 5. Localization

Added Arabic and English copy for the KYC flow.

Files:

- `lib/Artisan/core/utils/constants/app_strings.dart`
- `lib/Artisan/core/utils/constants/app_translations.dart`

## User Flow

### App start

1. If no artisan session exists -> login
2. If a session exists -> fetch artisan profile
3. If network is unavailable -> fall back to cached profile
4. Route artisan into the correct KYC step or home

### Login

1. Login succeeds
2. Tokens are saved
3. Artisan profile is cached
4. App routes to:
   - ID upload
   - Selfie
   - Status
   - Home

## Error Handling Added

- Upload buttons are disabled during submission
- API failures are shown through the existing app snackbar system
- Cached profile fallback prevents unnecessary session loss when the device is offline
- Verification status is refreshable from the status screen
- Retry logic respects the backend state instead of guessing locally

## Tests Added

Added KYC-specific route tests:

- `test/artisan_verification_route_test.dart`
- Updated `test/session_routing_test.dart` to validate cached-profile KYC resume behavior

## Verification Results

Executed successfully:

- `flutter analyze`
- `flutter test`

Result:

- `flutter analyze` -> no issues found
- `flutter test` -> 16 tests passed

## Setup Notes

No extra Flutter dependency installation was required because the feature was built on the app's existing stack:

- `GetX`
- `Dio`
- `image_picker`
- `flutter_secure_storage`

## Release Notes

- KYC is enforced only for artisans
- Customer flow remains unchanged
- Existing session persistence remains intact
- Offline fallback behavior is preserved

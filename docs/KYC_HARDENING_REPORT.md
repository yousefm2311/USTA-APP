# Usta KYC Hardening Report

## Scope

This hardening pass upgraded the existing artisan KYC system without changing the current architecture:

- Flutter remains `GetX + Dio`
- Backend remains `Node.js + Express + MongoDB`
- Existing auth/session behavior was preserved

## Backend Hardening

### Source of truth

`verificationStatus` is now the canonical verification state.

Supported statuses:

- `pending_documents`
- `documents_uploaded`
- `selfie_uploaded`
- `under_review`
- `approved`
- `rejected`

`identityVerified` is now derived from status and is only `true` when status is `approved`.

### Workflow helper

Added a centralized verification workflow helper to:

- validate status transitions
- derive compatibility `verificationStep`
- normalize retry/cooldown state
- compute retry actions and problem categories

### Attempts logic

`verificationAttempts` now increases only when:

- face verification ends in `rejected`
- admin support explicitly rejects a verification

Added:

- `lastAttemptAt`
- optional cooldown support via env

### Face verification

Confidence flow is now tiered:

- `< 60` -> `rejected`
- `60 - 85` -> `under_review`
- `> 85` -> `approved` automatically by default

This matches the requested business rule: high-confidence match activates the artisan immediately without waiting for admin approval.

### Admin support tools

Added operational admin endpoints:

- `GET /api/admin/verifications`
- `GET /api/admin/verifications/:id`
- `POST /api/admin/verifications/:id/approve`
- `POST /api/admin/verifications/:id/reject`
- `GET /api/admin/verification/:id/image/:type`

These do not block the automatic approval flow. They exist as support/override tools.

### Endpoint protection

Added `requireVerifiedArtisan` middleware and applied it to:

- service mutation endpoints
- pricing mutation endpoint
- request action endpoints
- wallet/earnings/withdraw/payment-method endpoints

### Logging

Added audit logging for:

- ID upload
- selfie upload
- face match outcome
- blocked attempts
- admin approve/reject
- admin image access

## Flutter Hardening

### Status-only routing

The artisan app no longer relies on `verificationStep` for navigation decisions.

Routing is now based on `verificationStatus` only:

- `pending_documents` -> ID upload
- `documents_uploaded` -> selfie
- `selfie_uploaded` / `under_review` -> status
- `approved` -> home
- `rejected` -> rejected screen

### Rejected UX

Added a dedicated rejected screen that shows:

- user-safe rejection reason
- problem type
- retry options for:
  - documents
  - selfie
  - both

### Image optimization

Added client-side image compression before upload:

- higher quality for ID documents
- optimized selfie compression

### Bypass prevention

Added an artisan verification guard service that re-checks access on:

- app start
- login
- token refresh
- route changes
- app resume from background

### API UX improvements

The Flutter KYC controller now handles:

- `403`
- `429`
- `422`
- upload validation failures
- network fallback through cached profile state

## Verification Results

Executed successfully:

- `npm run check:syntax`
- `npm test`
- `flutter analyze`
- `flutter test`

Results:

- backend tests: `19 passed`
- flutter tests: `17 passed`
- flutter analyze: `no issues found`

## Production Checks

Before release, confirm:

1. `AWS_REGION` is configured in production
2. Rekognition IAM permissions allow `DetectFaces` and `CompareFaces`
3. private upload storage is writable
4. `KYC_FACE_REJECT_THRESHOLD`, `KYC_FACE_REVIEW_THRESHOLD`, and `KYC_MAX_ATTEMPTS` are set intentionally
5. `KYC_AUTO_APPROVE_HIGH_CONFIDENCE=true` if immediate activation is desired
6. staging verification is tested with:
   - low-confidence mismatch
   - mid-confidence review
   - high-confidence approval
   - max-attempt block
   - cooldown behavior if enabled

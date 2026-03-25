# Release Hardening Report

## Scope

This pass focused on the shared Flutter app that contains both:

- Customer experience
- Artisan experience

The goal was to improve release readiness, session stability, token persistence,
and automated verification for the most critical login/session flows.

## What Was Fixed

### Session persistence and token storage

- Upgraded the artisan token storage to use secure storage with a local fallback
  instead of relying only on `GetStorage`.
- Kept customer token storage behavior but fixed a bug where an old refresh
  token could stay cached in memory when the backend stopped returning one.
- Added environment/origin tracking for artisan session storage so stale tokens
  are cleared when the backend origin changes.
- Preserved the logged-out flag consistently in both app modes.

### Access token / refresh token handling

- Hardened customer refresh-token flow to avoid forced logout when refresh fails
  because of temporary network issues or timeouts.
- Hardened artisan refresh retry flow so it does not force a logout when the
  refresh attempt fails for transient connectivity reasons.
- Kept logout behavior strict when the session is actually invalid or refresh
  truly fails.

### Logout correctness

- Fixed customer logout order so remote logout can still use the active token
  before local credentials are cleared.

### Cleanup and code quality

- Removed dead null-aware logic in the request route map screen.
- Cleaned the project until `flutter analyze` returned zero issues.

## Automated Tests Added

### Token storage tests

- Customer token storage clears stale refresh tokens correctly.
- Customer token storage migrates legacy box storage into secure storage.
- Customer token storage clears sessions when backend origin changes.
- Artisan token storage persists tokens correctly.
- Artisan token storage migrates fallback storage into secure storage.
- Artisan token storage clears sessions when backend origin changes.

### Session routing tests

- Customer app opens the authenticated home route when a valid session exists.
- Customer app falls back to login after logout.
- Artisan app opens the authenticated home route when a valid session exists.
- Artisan app falls back to login after logout.

## Verification Run

Executed successfully:

```bash
flutter analyze
flutter test
```

Result:

- `flutter analyze`: no issues found
- `flutter test`: all tests passed

## Files Touched

- `lib/app/services/storage_backends.dart`
- `lib/Customer/core/services/token_storage.dart`
- `lib/Artisan/core/services/token_storage.dart`
- `lib/Customer/core/services/network/api_client.dart`
- `lib/Artisan/core/services/network/auth_retry_interceptor.dart`
- `lib/Artisan/core/services/auth_service.dart`
- `lib/Customer/features/auth/controllers/auth_controller.dart`
- `lib/Customer/features/customer/requests/views/request_route_map_view.dart`
- `test/customer_token_storage_test.dart`
- `test/artisan_token_storage_test.dart`
- `test/session_routing_test.dart`
- `test/support/in_memory_storage.dart`

## Notes

- There were already unrelated local changes in `pubspec.lock` and
  `third_party/gallery_saver/pubspec.lock`; they were intentionally left
  untouched.
- This pass improves release readiness significantly around auth/session
  behavior, but production launch should still include manual QA on real devices
  for push notifications, maps, chat, payments, and backend edge cases.

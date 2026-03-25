# Manual Release Checklist

## Goal

This checklist is for final manual QA before publishing the unified app that
contains both:

- Customer flow
- Artisan flow

It is tailored to the current codebase and focuses on the highest-risk areas:

- Auth and session persistence
- Notifications and FCM
- Maps, permissions, and live location
- Chat and realtime sockets
- Wallet and payment-related flows
- App mode switching between customer and artisan

## Test Matrix

Run the checklist on at least:

- Android physical device
- iPhone physical device
- Android with poor network / airplane-mode toggling
- Device with notifications disabled, then re-enabled
- Fresh install
- Upgrade install over an older build

Use at least 2 accounts for customer and 2 accounts for artisan so realtime,
chat, and notification flows can be validated end-to-end.

## Pre-Release Setup

- Confirm production backend URL and socket endpoint are correct.
- Confirm Firebase project, `google-services.json`, and iOS notification setup
  match the release environment.
- Confirm Maps API keys are present and restricted correctly.
- Confirm signing, bundle identifiers, version, and build number are correct.
- Confirm release build is tested, not only debug build.
- Confirm backend test accounts exist with realistic data.

## Core App Launch

- Fresh install opens without crash.
- Splash works and app reaches the user-type chooser.
- Switching to customer opens the customer app shell correctly.
- Switching to artisan opens the artisan app shell correctly.
- Logging out from either mode returns safely to the chooser.
- Killing the app and reopening preserves the correct last session when the user
  is still authenticated.

Acceptance:

- No crash on first launch.
- No stuck loading state.
- No need to log in again after normal app restart when tokens are still valid.

## Customer Auth and Session

- Register a new customer account.
- Verify activation flow.
- Log in using supported credentials.
- Close the app completely and reopen it.
- Confirm the app routes directly into the customer area.
- Force token expiration from backend or use an expired session scenario.
- Confirm refresh happens silently when possible.
- Disable internet during an expired-session scenario.
- Confirm the app does not log the customer out immediately just because refresh
  hit a temporary connectivity issue.
- Log out and confirm reopening the app no longer restores the old session.

Acceptance:

- Session persists across relaunch.
- Silent refresh works.
- Temporary network issues do not cause unnecessary logout.
- Explicit logout always clears session.

## Artisan Auth and Session

- Register a new artisan account.
- Verify activation / approval flow if applicable.
- Log in as artisan.
- Close the app and reopen it.
- Confirm the app routes directly into artisan home.
- Repeat with token-expiry scenario.
- Confirm refresh works without forcing unnecessary logout on transient network
  issues.
- Log out and confirm the artisan session is cleared fully.

Acceptance:

- Artisan session persists across relaunch.
- Refresh behavior is stable.
- Logout returns cleanly to chooser and does not leak into customer mode.

## Mode Switching Between Customer and Artisan

- Log in as customer, close app, reopen, then log out.
- Switch to artisan from chooser and log in.
- Repeat in the opposite order.
- Switch modes multiple times in the same install session.
- Confirm realtime/chat services from the previous mode do not continue leaking
  events into the new mode.

Acceptance:

- No mixed UI state between modes.
- No stale socket notifications from the wrong role.
- No freeze or disabled taps during switching.

## Notifications and FCM

Customer side:

- Allow notification permission on first launch.
- Receive a foreground notification.
- Receive a background notification.
- Tap the notification and confirm deep-link behavior lands in the correct
  screen.
- Deny notification permission, then re-enable from system settings and retry.

Artisan side:

- Log in and verify FCM token sync happens after login.
- Trigger notification types relevant to request updates and chat.
- Verify grouped / list notifications screen behavior.
- Open notification details and confirm navigation target is correct.

Acceptance:

- Notifications arrive in foreground and background.
- Opening notification routes to the intended screen.
- Permission denial is handled gracefully.
- No duplicate notifications after relogin.

## Maps and Location Permissions

Customer flows:

- Create request using current location.
- Deny location permission and confirm user-friendly handling.
- Approve permission and retry.
- Open artisan map / route screen from request details.
- Open live map from explore / artisan details where applicable.

Artisan flows:

- Open location settings screen.
- Save artisan location on map.
- Open active request map.
- Start moving and confirm live updates continue while request is active.
- Test permission denied, denied forever, and location-services-disabled cases.

Acceptance:

- Maps render.
- User permission prompts are handled without crash.
- Fallback messages are clear when location is unavailable.
- Live location updates are visible end-to-end when expected.

## Chat and Realtime

Customer and artisan together:

- Open request chat.
- Send text message both directions.
- Send direct message if supported.
- Send image.
- Send video.
- Mark messages as read.
- Edit a message where supported.
- Delete a message where supported.
- Clear a conversation where supported.
- Put one device in background and confirm delivery on resume.
- Disconnect internet on one side, send from the other, then reconnect.
- Force logout/login and confirm chat reconnects correctly.

Acceptance:

- Messages appear in correct order.
- Read state syncs correctly.
- Media upload works and previews open correctly.
- Realtime reconnect restores subscriptions without duplicate messages.

## Requests Flow

Customer:

- Create request with description and images.
- Create direct request to artisan if supported.
- Track active request.
- Cancel request.
- Confirm completion.
- Submit review.

Artisan:

- Receive new request.
- Accept request.
- Reject request.
- Update timeline/status.
- Open request details and map.
- Complete request.

Acceptance:

- Request status changes are reflected on both sides.
- Timeline and live updates stay in sync.
- No stale request cards after refresh or reconnect.

## Wallet and Payments

Customer:

- Open wallet and load balance.
- Recharge wallet.
- Open wallet history.
- Open payment history.
- Open payment receipt.
- Test invalid amount handling.
- Test network failure during recharge and confirm graceful error state.

Artisan:

- Open wallet.
- Load wallet history.
- Submit withdrawal request.
- Test invalid withdrawal amount.
- Confirm balances and transaction history update after backend success.

Acceptance:

- Screens load without crash.
- Error states are clear and recoverable.
- Amounts, balances, and receipts match backend data.

## Media and Attachments

- Pick image from gallery.
- Pick image from camera if supported.
- Upload multiple request images.
- Upload chat image/video.
- Open image viewer.
- Open video viewer.
- Retry after denying photo/media permissions.

Acceptance:

- Upload completes.
- Media previews render correctly.
- Permission denial does not break the screen.

## Offline / Poor Network Behavior

- Toggle airplane mode while logged in.
- Open screens that depend on API.
- Trigger session refresh scenario while offline.
- Reconnect internet and retry.
- Confirm snackbars / overlays are understandable.

Acceptance:

- App does not crash.
- User is not logged out unnecessarily because of temporary connectivity loss.
- Recovery after network restore works without reinstall.

## Stability Sweep

- Background the app for several minutes, then return.
- Rotate device where supported.
- Open and close heavy screens repeatedly: chat, maps, wallet, notifications.
- Rapidly switch tabs.
- Rapidly switch customer/artisan mode after logout.

Acceptance:

- No obvious memory-related slowdowns.
- No duplicate socket events.
- No black/blank screens after returning from background.

## Final Release Gate

Only ship when all are true:

- `flutter analyze` passes
- `flutter test` passes
- Manual checks above pass on Android and iPhone physical devices
- Notifications verified in foreground and background
- Maps and live location verified on real devices
- Chat verified end-to-end with two accounts
- Wallet/payment flows verified against real backend responses
- Session persistence verified after app kill and reopen
- Logout verified for both customer and artisan

## Suggested Sign-Off Table

Fill this before publishing:

- Build version:
- Backend environment:
- Android tester:
- iPhone tester:
- Customer QA result:
- Artisan QA result:
- Notifications QA result:
- Maps/location QA result:
- Chat/realtime QA result:
- Wallet/payments QA result:
- Final decision:

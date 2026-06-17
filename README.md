# Merge Usta

A full Flutter application for the Usta service platform, combining customer-facing flows, service workflows, realtime communication, location features, media handling, payments UI, and notifications.

## Status

Private pinned candidate. Review secrets and production configuration before making this repository public.

## Key Features

- Service marketplace mobile app foundation
- GetX state management and local storage
- Arabic/RTL-ready localization support
- API integration with Dio and request logging
- Realtime messaging foundation with Socket.IO
- Image, camera, audio, video, and file workflows
- Google Maps, geolocation, and geocoding support
- Firebase Core and Firebase Messaging setup
- Charts, cards, onboarding, OTP, and payment UI components

## Tech Stack

- Flutter
- Dart
- GetX
- Dio
- Socket.IO Client
- Firebase Messaging
- Google Maps Flutter
- Geolocator / Geocoding
- Get Storage / Shared Preferences / Secure Storage
- Camera / Image Picker / File Picker
- Lottie / Google Fonts / Animate Do / fl_chart

## Getting Started

```bash
git clone https://github.com/yousefm2311/Merge-Usta.git
cd Merge-Usta
flutter pub get
flutter run
```

## Environment And Secrets

Before sharing or publishing this repository, review all configuration files and assets carefully.

```env
API_BASE_URL=
SOCKET_URL=
GOOGLE_MAPS_API_KEY=
FIREBASE_PROJECT_ID=
```

Do not expose service-account files, notification keys, production API URLs, auth tokens, or private credentials.

## Screenshots

Add customer flow, service flow, chat, map, and dashboard screenshots before pinning publicly.

```md
![Usta app flow](docs/screenshots/usta-flow.png)
```

## Roadmap

- Add architecture notes for modules and API services
- Document Firebase and notification setup
- Add screenshots for primary user flows
- Add build and release notes for Android/iOS

## Author

Yousef Mohamed

- GitHub: https://github.com/yousefm2311

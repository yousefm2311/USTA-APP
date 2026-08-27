<div align="center">
  <h1>🛠️ Merge Usta (أسطى)</h1>
  <p><strong>A Next-Generation Home Services & Artisan Marketplace App</strong></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="#"><img src="https://img.shields.io/badge/GetX-State_Management-FF6F00?style=for-the-badge" alt="GetX" /></a>
    <a href="https://socket.io"><img src="https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socket.io&logoColor=white" alt="Socket.io" /></a>
    <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" /></a>
  </p>
  
  <p>
    <a href="README_AR.md">🇸🇦 قراءة الوصف باللغة العربية</a>
  </p>
</div>

---

## 📖 Project Overview

**Merge Usta** is a comprehensive, dual-sided Flutter application designed to bridge the gap between service seekers (Customers) and professional service providers (Artisans/Ustas). 

Instead of maintaining two separate codebases, Merge Usta elegantly combines **both Customer and Artisan applications into a single unified bundle** using a smart GetX App Switcher. It features a robust real-time engine for chat and live tracking, advanced media handling, and top-tier security including ML-driven KYC verification.

---

## ✨ Key Features

### 🧑‍💼 Customer App
- **Service Exploration:** Browse various service categories, read reviews, and find top-rated artisans.
- **Real-Time Requests:** Request services, negotiate prices, and get instant responses.
- **Live Map Tracking:** Track your artisan's location in real-time on Google Maps.
- **Live Chat:** Instant messaging with artisans, including image, audio, and video sharing.
- **Digital Wallet & Payments:** Secure in-app wallet and payment gateways.
- **Favorites & Reviews:** Save your trusted artisans and leave feedback after service completion.

### 👨‍🔧 Artisan (Usta) App
- **Earnings Dashboard:** Comprehensive analytics on daily, weekly, and monthly earnings.
- **Real-Time Job Board:** Receive instant push notifications for new nearby requests.
- **Portfolio Management:** Showcase previous work using a built-in media gallery.
- **Secure KYC Verification:** Face detection and identity verification using Google ML Kit.
- **Service Management:** Easily toggle availability and manage active/completed jobs.

### ⚡ Core Technologies
- **Real-Time Engine:** Custom `SocketManager` powering instant chat and live map tracking.
- **State Management:** Reactive programming utilizing `GetX` for routing and state.
- **Push Notifications:** Deeply integrated with Firebase Cloud Messaging (FCM).
- **Localization:** Full RTL support with dynamic Arabic/English switching.
- **Media Processing:** Audio recording, video thumbnails, and local image compression.

---

## 🏗️ Architecture & Tech Stack

Merge Usta follows a clean, feature-first modular architecture separating the two user personas while sharing core utilities.

### 📦 Major Dependencies
| Category | Libraries / Packages |
|----------|----------------------|
| **Core & State** | `flutter`, `get`, `shared_preferences`, `flutter_secure_storage` |
| **Networking** | `dio`, `socket_io_client`, `pretty_dio_logger` |
| **Maps & Location** | `google_maps_flutter`, `geolocator`, `geocoding` |
| **Media & Files** | `image_picker`, `record`, `just_audio`, `video_player`, `file_picker` |
| **UI & Animations** | `lottie`, `fl_chart`, `animate_do`, `simple_splash_view` |
| **Firebase & ML** | `firebase_core`, `firebase_messaging`, `google_mlkit_face_detection` |

---

## 📂 Folder Structure

```text
lib/
├── app/                      # Shared Core App (App Switcher, App Modes)
├── Artisan/                  # Artisan (Usta) Specific App
│   ├── core/                 # Artisan Core Config & Middleware
│   ├── data/                 # Artisan Repositories & Models
│   ├── features/             # Artisan Features (Auth, Home, Wallet, KYC, etc.)
│   └── main.dart             # Artisan Entry Point
├── Customer/                 # Customer Specific App
│   ├── core/                 # Customer Core (Socket Engine, Theme, Config)
│   ├── data/                 # Customer Repositories & API integration
│   ├── features/             # Customer Features (Explore, Requests, Map, Chat)
│   └── main.dart             # Customer Entry Point
└── main.dart                 # Global Entry Point (Initializes App Switcher)
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.9.2 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code
- A valid Google Maps API Key
- Firebase Project Setup (`google-services.json` & `GoogleService-Info.plist`)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yousefm2311/Merge-Usta.git
   cd Merge-Usta
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Ensure you have your API keys and Base URLs configured. You may need to create an `.env` file or update the `config` files in `lib/Customer/core/config/` and `lib/Artisan/core/config/`.
   
   *Required Keys:*
   - `API_BASE_URL`
   - `SOCKET_URL`
   - `GOOGLE_MAPS_API_KEY`

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📱 Screenshots

*(Add your high-quality screenshots here to showcase the UI)*

| Customer Home | Artisan Dashboard | Live Map Tracking | Real-Time Chat |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/customer_home.png" width="200" alt="Customer Home" /> | <img src="docs/screenshots/artisan_dash.png" width="200" alt="Artisan Dash" /> | <img src="docs/screenshots/map_tracking.png" width="200" alt="Map Tracking" /> | <img src="docs/screenshots/chat_screen.png" width="200" alt="Chat" /> |

---

## 🤝 Contributing
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🛡️ License
This project is private and confidential. All rights reserved.

<div align="center">
  <p>Made with ❤️ by <strong>Yousef Mohamed</strong></p>
</div>

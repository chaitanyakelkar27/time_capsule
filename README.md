# TimeCapsule

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-blue.svg)](#-installation)

## Description

TimeCapsule is a cross-platform Flutter application that lets users create digital capsules containing messages, photos, or videos that unlock in the future by time or by location. It solves the problem of preserving meaningful moments and delivering them with intentional timing, while adding AI-assisted writing and real-time updates.

Live web app: https://time-capsule-c4c2a.web.app

## Features

- Secure authentication with Firebase Auth (email/password)
- Time-based and location-based capsule unlock rules
- Capsule creation with text, image, or video content
- AI-powered message suggestion and enhancement (Groq API)
- Real-time sent/received capsule updates via Cloud Firestore
- Push notifications and unlock alerts with Firebase Cloud Messaging
- Reaction video workflow for recipients
- Mobile and web support from a single Flutter codebase

## Technical Highlights

- Modular layered frontend structure:
  - UI in `screens` and reusable `widgets`
  - State management via `provider`
  - Integration/business logic in `services`
  - Typed domain objects in `models`
- Event-driven backend with Firebase Cloud Functions v2:
  - Scheduled unlock processing (`checkMaturedCapsules`)
  - Firestore trigger for unlock notifications (`onCapsuleUnlocked`)
  - Callable function for geofence unlock checks (`checkLocationUnlock`)
- Real-time data flow using Firestore streams for responsive UI updates
- Configuration-driven AI integration using runtime `--dart-define` variables
- Security-aware setup using Firebase rules for Firestore and Storage

## Concepts Used

- Reactive state management with Provider and ChangeNotifier
- Event-driven backend workflows using scheduled, trigger-based, and callable Cloud Functions
- Real-time UI synchronization through Firestore stream listeners
- Service-oriented app design with clear separation between UI, state, and integrations
- Configuration-driven runtime behavior using `--dart-define` and environment-specific values
- Auth-aware data access patterns reinforced by Firestore and Storage security rules

## Installation

### For Users (Install APK)

1. Obtain the latest APK from the project maintainer.
2. On Android, enable Install unknown apps for your file manager/browser.
3. Open the APK file and tap Install.
4. Launch TimeCapsule and grant required permissions (notifications, camera, location).

If an older build is already installed and install fails, uninstall the old app first, then install the new APK.

### For Developers (Build from Source)

Prerequisites:
- Flutter SDK
- Node.js and npm
- Firebase CLI
- Firebase project configured for Auth, Firestore, Storage, Functions, and Hosting

1. Clone the repository:

```bash
git clone <your-repository-url>
cd time_capsule
```

2. Install Flutter dependencies:

```bash
cd frontend
flutter pub get
```

3. Install and build Cloud Functions:

```bash
cd ../backend/functions
npm install
npm run build
```

4. Run app in development mode:

```bash
cd ../../frontend
flutter run -d chrome --dart-define-from-file=.env.local
```

5. Build release APK:

```bash
cd frontend
flutter build apk --release --dart-define-from-file=.env.local
```

If Flutter reports APK detection issues, use Gradle directly:

```bash
cd frontend/android
.\gradlew.bat app:assembleRelease
```

APK output paths:
- `frontend/android/build/app/outputs/flutter-apk/app-release.apk`
- `frontend/android/build/app/outputs/apk/release/app-release.apk`

## Tech Stack

- Flutter (Dart)
- Provider (state management)
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions v2 (TypeScript)
- Firebase Cloud Messaging
- Firebase Hosting
- Groq Chat Completions API
- Android Gradle toolchain

## Project Structure

```text
time_capsule/
├── frontend/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── theme/
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
├── backend/
│   ├── functions/
│   │   ├── src/
│   │   └── package.json
│   ├── firebase.json
│   ├── firestore.rules
│   └── storage.rules
└── README.md
```

## Contributing & License

Contributions are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Commit focused, well-documented changes.
4. Open a pull request with a clear summary and testing notes.

This project is licensed under the MIT License. See `LICENSE` for details.

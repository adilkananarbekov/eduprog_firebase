# Eduprog_firebase

Eduprog_firebase is a Flutter-based education management app with admin and parent flows.
This repository also includes a separate `EduOps Web design` folder that looks
like a React/Vite design prototype rather than the main production app.

## Flutter App

- State management: Riverpod
- Routing: GoRouter
- Data backend: Firebase Auth + Firestore for active app flows
- Platforms: Android, iOS, web, desktop

## Setup

1. Install Flutter and run `flutter pub get`
2. For the new Firebase-backed auth and managed user flow, follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
3. To rebuild the project with a coherent fake Firebase dataset and known passwords, run:
   `powershell -ExecutionPolicy Bypass -File .\tool\reseed_firebase_data.ps1 -Apply`
4. Start the app with the default Firebase-backed flow:
   `flutter run`
5. Override the legacy REST backend URL only if you still need it for compatibility work:
   `flutter run --dart-define=EDUOPS_BASE_URL=http://136.116.64.6`
6. To point at a temporary local backend explicitly:
   `flutter run --dart-define=EDUOPS_BASE_URL=http://localhost:8080`
7. If your backend uses a different API prefix:
   `flutter run --dart-define=EDUOPS_API_PREFIX=/api`

## Security Notes

- Quick-login test credentials are available only in debug builds.
- The current backend URL uses plain HTTP. Android and iOS include cleartext exceptions so the app can reach `136.116.64.6`.
- Move the backend to HTTPS for production use.

## Useful Commands

- `flutter analyze`
- `flutter test`
- `flutter run`

## Current State

- Auth, managed users, schedules, grades, attendance, and announcements run from Firebase
- Admin-only user creation is enforced through Cloud Functions
- The included Firebase config is still web-only until platform-specific Firebase apps are added

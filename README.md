# Eduprog

Eduprog is a Flutter app for running classes. Staff get an admin workspace
for users, groups, schedules, attendance and reports. Students and parents
get a separate area with their schedule, grades, attendance and announcements.
The app is branded **EduOps** in its UI.

> **Status: in development.** The Firebase configuration in this repo covers
> the web platform only, so the app currently runs as a Flutter web build.
> There are no released Android, iOS or desktop builds.

## Features

### Sign-in and roles

- Email and password sign-in with Firebase Auth. There is no self-registration:
  an administrator creates every teacher and student account.
- GoRouter sends each user to their own area after sign-in. Admin and teacher
  accounts open the admin workspace (`/admin`). Student accounts open the
  parent area (`/parent`); the role value `PARENT` maps to the same role.
- `lib/core/security/role_access.dart` restricts routes on the client. Firestore
  security rules and Cloud Functions enforce the permissions on the server.

### Admin workspace

- **Dashboard:** counts of students, teachers, active groups and announcements,
  plus today's lessons and attendance coverage.
- **Managed users:** administrators create, edit, deactivate and delete teacher
  and student accounts. These actions call Cloud Functions, which check that
  the caller is an active administrator. The functions then update the Firebase
  Auth user and the matching Firestore profile.
- **Students and groups:** a student list that can be narrowed to one group,
  student profiles with grades and attendance, and class group creation.
- **Schedule:** a schedule page with day and week views, plus a week schedule
  that can be browsed by group, teacher or subject.
- **Attendance:** attendance marking for each lesson.
- **Reports:** attendance and performance analytics, with CSV export to the
  clipboard.
- **Announcements:** a feed of announcements.
- **Settings:** account management and a light, dark or system theme.

### Parent area

- Dashboard with shortcuts to the schedule, records and updates.
- Weekly schedule.
- Records: grades and attendance.
- Announcements.
- Settings.

## Tech stack

| Layer | Technology |
| --- | --- |
| App | Flutter, Dart (SDK `^3.10.4`) |
| State management | Riverpod (`flutter_riverpod`) |
| Routing | GoRouter, with role-based redirects |
| Authentication | Firebase Auth (email/password) |
| Database | Cloud Firestore, protected by the rules in `firestore.rules` |
| Server logic | Cloud Functions for Firebase, written in TypeScript (`functions/src/index.ts`) |
| Local storage | `flutter_secure_storage` |
| CI | GitHub Actions workflow `deploy-web.yml`: builds Flutter web and publishes it to the `gh-pages` branch |

The Cloud Functions are `createManagedUser`, `updateManagedUser` and
`deleteManagedUser`.

The Firestore collections are `users`, `class_groups`, `subjects`, `schedules`,
`grades`, `attendance`, `announcements` and `metadata`.

## Project structure

```
lib/
  main.dart               App entry point: Firebase init, EduOpsApp
  firebase_options.dart   Firebase options, web config only (written by hand)
  core/
    api/                  Legacy REST client from an earlier backend
    models/               Users, groups, subjects, schedule, grades, attendance, announcements
    providers/            Riverpod providers, auth and theme state
    router/               GoRouter configuration
    security/             Client-side role and route access
    services/             Firebase-backed services: auth, admin, schedule, grades, attendance, announcements
    storage/              Secure storage wrapper
    theme/                Colors, typography, light and dark themes
    utils/                Helpers
  layouts/                Admin and parent app shells
  pages/admin/            Dashboard, students, groups, schedule, attendance, reports, settings
  pages/parent/           Dashboard, schedule, records, announcements, settings
  widgets/                Shared UI components
functions/                Cloud Functions (TypeScript)
firestore.rules           Firestore security rules
firestore.indexes.json    Firestore indexes
firebase.json             Firebase CLI config
test/                     Unit and widget tests
tool/                     PowerShell helpers (demo data, running on an Android device)
web/                      Flutter web shell
EduOps Web design/        A separate React + Vite UI prototype exported from Figma. The Flutter app does not use it.
```

The `lib/core/api/` client and the `EDUOPS_BASE_URL` / `EDUOPS_API_PREFIX`
dart-defines belong to the earlier REST backend. The current data flows go
through Firebase. `API_DOCUMENTATION.md` and `BACKEND_STRUCTURE.md` describe
that earlier backend. `PRODUCTION_READINESS.md` lists the open release
blockers.

## Getting started

### Prerequisites

- Flutter SDK (stable channel)
- A Firebase project you control
- [Firebase CLI](https://firebase.google.com/docs/cli) and
  [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)
- npm, to build the Cloud Functions

### 1. Install dependencies

```bash
git clone https://github.com/adilkananarbekov/eduprog_firebase.git
cd eduprog_firebase
flutter pub get
```

### 2. Connect your Firebase project

The committed `lib/firebase_options.dart` points to the author's Firebase
project and contains only a web configuration. To generate a config for your
own project, run:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id> --platforms=web
```

Then, in the Firebase Console, open **Authentication → Sign-in method** and
enable **Email/Password**.

### 3. Deploy rules, indexes and Cloud Functions

```bash
firebase login
firebase use <your-project-id>
cd functions
npm install
npm run build
cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

### 4. Create the first administrator

Self-registration is disabled, so you create the first admin by hand:

1. In **Authentication → Users**, add a user with your own email and password.
2. In Firestore, create the document `users/<AUTH_UID>`:

   ```json
   {
     "id": 1,
     "uid": "<AUTH_UID>",
     "email": "<your admin email>",
     "firstName": "System",
     "lastName": "Admin",
     "role": "ADMIN",
     "isActive": true,
     "classGroupId": null,
     "classGroupName": null,
     "subjectIds": [],
     "subjects": []
   }
   ```

3. Create the document `metadata/counters` with
   `{ "nextUserId": 1, "nextClassGroupId": 0 }`.

After that, sign in as the admin and create teachers and students from the app.

### 5. Run

```bash
flutter run -d chrome
```

Other useful commands:

```bash
flutter analyze
flutter test
```

### Optional: demo data

`tool/reseed_firebase_data.ps1` seeds a demo dataset: class groups, subjects,
schedules, grades, attendance, announcements, and demo teacher and student
accounts. **Set your own credentials** before you run it:

- pass `-ProjectId` and `-ApiKey` for your project;
- replace the demo account credentials defined in the script with your own.

The script is Windows PowerShell and uses your Firebase CLI login.

- Without `-Apply`, it backs up Firestore and the Auth users to
  `tool/firebase-backups/<timestamp>/` (git-ignored) and prints a summary.
- With `-Apply`, it deletes and rewrites the seeded collections, disables Auth
  accounts that are not in the seed list, and resets the demo accounts. Only
  run it against a project you are prepared to wipe.

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\reseed_firebase_data.ps1 -ProjectId <your-project-id> -ApiKey <your-web-api-key> -Apply
```

## Status and known limitations

- In development.
- The published Firebase configuration is web-only. Android, iOS, macOS and
  Windows each need their own Firebase app registration and platform files
  (`flutterfire configure`) before they can run against Firebase.
- Creating schedule entries, grades and announcements is implemented in the
  service layer, but the UI does not offer it yet.
- Android still uses the template application ID and debug signing for release
  builds. `PRODUCTION_READINESS.md` lists this and the other release blockers.

## Author

Built by Adilkan Anarbekov, a web and Flutter developer from Bishkek,
Kyrgyzstan: [adilkan.com](https://adilkan.com) ·
[GitHub](https://github.com/adilkananarbekov)

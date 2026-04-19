# Firebase Setup

This app now uses Firebase for authentication and the active school data flows.

## What Was Added

- Firebase Auth for sign-in
- Firestore `users`, `class_groups`, `subjects`, `schedules`, `grades`, `attendance`, and `announcements`
- Cloud Functions for admin-only account creation, update, and deletion
- Firestore rules that block self-registration and protect role-based reads/writes for school data

## Important Limitation

The Firebase config currently included in the Flutter app is the **web app config only**:

- `projectId`: `eduops-25a60`
- `appId`: `1:796694555251:web:a609003dc00df9f3f2d806`

That means the app is ready for Firebase-backed **Flutter web** runs. Android, iOS, macOS, and Windows still need their own Firebase app registrations and platform files before you can run them against Firebase.

## 1. Enable Email/Password Login

In Firebase Console:

1. Open `eduops-25a60`
2. Go to `Authentication`
3. Open `Sign-in method`
4. Enable `Email/Password`

## 2. Deploy Rules and Functions

Install the Firebase CLI if needed:

```bash
npm install -g firebase-tools
```

From the repo root:

```bash
firebase login
firebase use eduops-25a60
cd functions
npm install
npm run build
cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## 2.1 Seed Fake Data

To inspect the live Firebase data without changing it:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\reseed_firebase_data.ps1
```

To back up the current project, rebuild Firestore, and reset the fake login passwords:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\reseed_firebase_data.ps1 -Apply
```

The script stores backups under `tool/firebase-backups/<timestamp>/`.

After seeding:

- Admin: `admin@eduops.kg` / `Admin123!`
- Teachers: `teacher1@eduops.kg` through `teacher5@eduops.kg` / `Teacher123!`
- Students: `student1@eduops.kg` through `student20@eduops.kg` / `Student123!`

The seeded dataset includes:

- 26 managed users
- 4 class groups
- 5 subjects
- 40 schedule entries
- 80 grades
- 120 attendance records
- 4 announcements

## 3. Bootstrap the First Admin

Because self-registration is intentionally disabled, the first admin must be created manually.

### Create the admin auth account

In Firebase Console:

1. Go to `Authentication`
2. Open `Users`
3. Click `Add user`
4. Create your admin email/password

### Create the matching Firestore profile

In Firestore, create a document at:

`users/<AUTH_UID>`

Use fields like:

```json
{
  "id": 1,
  "uid": "<AUTH_UID>",
  "email": "admin@your-school.com",
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

Also create:

`metadata/counters`

with:

```json
{
  "nextUserId": 1,
  "nextClassGroupId": 0
}
```

After that, sign in as the admin and create teachers/students from the app.

## Firestore Collections

### `users`

- `id`: numeric internal id
- `uid`: Firebase Auth uid
- `email`
- `firstName`
- `lastName`
- `role`: `ADMIN`, `TEACHER`, `STUDENT`
- `isActive`
- `classGroupId`
- `classGroupName`
- `subjectIds`
- `subjects`
- `createdAt`
- `updatedAt`

### `class_groups`

- `id`
- `name`
- `grade`
- `monthlyFee`
- `createdAt`
- `updatedAt`

### `metadata/counters`

- `nextUserId`
- `nextClassGroupId`

## Supported Account Management Flow

- Teachers and students cannot register themselves.
- Admins sign in normally.
- Admins create teacher/student accounts from the app.
- Cloud Functions create the Firebase Auth user and matching Firestore profile.
- Admins can edit or delete teacher/student accounts from the settings screen.

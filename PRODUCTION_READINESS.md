# EduOps Production Readiness

## Changes Applied In Flutter

- Added refresh-token support so expired access tokens can be refreshed and the original request retried.
- Stopped autofilling the last saved password on the login screen. The app now remembers only the last used email.
- Restricted Android cleartext HTTP to the debug manifest instead of the main production manifest.
- Removed misleading editable monthly-fee input from the groups create dialog and stopped rendering fake `₸0/month` values when the backend does not provide a fee.

## Remaining Blockers Before Production

1. Android release identity and signing are not production-ready.
   `android/app/build.gradle.kts` still uses `com.example.eduprog` and debug signing for release builds.

2. iOS still allows insecure transport to a raw backend IP.
   `ios/Runner/Info.plist` should move to HTTPS and the temporary ATS exception should be removed before release.

3. Group creation is not fully aligned with the backend domain model.
   The backend `StudentGroup` create/update flow depends on `faculty` and `university`, but the Flutter app only collects name/year.

4. Schedule management is still incomplete.
   The backend exposes create/generate schedule endpoints, but the current Flutter UI is mostly read-only and does not provide a real lesson creation flow.

5. Announcement publishing is incomplete in Flutter.
   The backend supports admin announcement creation and deletion, but the current app only reads announcements.

6. Some backend-aware admin flows still need contract review.
   Example: `/api/v1/admin/students/unassigned` requires `universityId`, while the current Flutter service does not send it.

7. Release operations are not set up yet.
   Missing items include environment-specific configs, store assets, privacy/legal copy, crash reporting, analytics policy, and CI/CD for signed release builds.

## Recommended Next Implementation Order

1. Finalize release config: package IDs, signing, HTTPS backend URL, and environment separation.
2. Finish admin write flows: create/edit groups with faculty and university context, create schedules, create announcements.
3. Add real release QA: Android/iOS physical-device testing, backend smoke tests, and regression coverage for each role.
4. Add operational tooling: crash reporting, release CI, secrets handling, and deployment runbooks.

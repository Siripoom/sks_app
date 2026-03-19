# Firebase Setup

This project has been migrated to Firebase-backed services for:
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging

## What is already implemented

- Flutter app wiring for Firebase-backed auth, data, storage, and device-token registration
- Firebase App Check activation in the Flutter app for Android and iOS
- Seed script for Firestore data and seeded test accounts
- Cloud Function source that sends FCM notifications when `notifications` documents are created
- Android package id updated to `com.sks.aapp`
- iOS bundle id updated to `com.sks.app`
- Android Firebase config installed at `android/app/google-services.json`
- iOS Firebase config installed at `ios/Runner/GoogleService-Info.plist`
- Android/iOS runtime values are now wired in `lib/firebase_options.dart`
- iOS entitlements added for App Attest

## What is still needed from Firebase Console / FlutterFire

Android and iOS are now configured with real Firebase app credentials from project `sks-app-d980c`.

Web is still using placeholder `--dart-define` values because no Web app registration / generated FlutterFire config has been added yet.

## Recommended next steps

1. Register Android in Firebase App Check with `Play Integrity`.
2. Register iOS in Firebase App Check with `App Attest`.
3. For each developer/test device using debug builds, run the app once and safelist the emitted App Check debug token in Firebase Console.
4. Roll out enforcement gradually for `Cloud Functions`, then `Cloud Storage`, then `Cloud Firestore`.
5. Do not enable `Firebase Auth` enforcement in the first rollout.
6. Register the Web app in project `sks-app-d980c` if browser support is required.
7. Generate real FlutterFire config for Web and replace the temporary web section in `lib/firebase_options.dart`.
8. Install backend dependencies:

```bash
cd functions
npm install
```

9. Seed Firestore/Auth using a service account:

```bash
cd functions
set FIREBASE_SERVICE_ACCOUNT_PATH=path\to\service-account.json
set FIREBASE_STORAGE_BUCKET=sks-app-d980c.firebasestorage.app
npm run seed
```

10. Deploy the Cloud Function:

```bash
firebase deploy --only functions
```

## Runtime notes

- Flutter debug builds use the App Check debug provider on Android and iOS.
- Flutter profile/release builds use `Play Integrity` on Android and `App Attest` with `DeviceCheck` fallback on iOS.
- iOS App Attest requires the `Runner` target entitlement to stay set to `production`.
- Android release currently signs with the debug signing config in `android/app/build.gradle.kts`; switch to a real release keystore and register its SHA-256 before enabling enforcement for production users.
- If Firebase Console enforcement is enabled before the updated client is deployed and registered, calls to `Cloud Functions`, `Cloud Firestore`, or `Cloud Storage` can be rejected.
- School, bus, child, and trip edits continue to use the direct Firestore workaround in the admin flow.
- Managed user actions such as creating or updating parent/teacher/driver/admin accounts still use Cloud Functions.

# Career Connect employee frontend

## Run

```powershell
cd C:\Users\punel\portal\employee
flutter run
```

The Android app uses Firebase Authentication for email/password registration and login, Google sign-in, phone OTP, password reset, and sign-out. Existing Firebase sessions restore Home at startup. Email/password registration verifies the mobile number before linking email sign-in and opening Personal Details. Profile forms and other app data still use local preview state; they are not stored in Firebase.

## Firebase Android setup

The Android package is `com.example.employee`. Its Firebase configuration belongs at `android/app/google-services.json`. Enable Email/Password, Google, and Phone in Firebase Authentication. In Project settings, select the Android app and add the signing certificate SHA-1 and SHA-256; download the updated configuration afterward.

From the `employee/` directory, get the fingerprints for your local debug build:

```powershell
cd android
.\gradlew.bat signingReport
```

Use the SHA-1 and SHA-256 listed under `Variant: debug`.

For release builds, register the actual release / Google Play app-signing certificates too. Google sign-in needs an Android OAuth client matching the package and signing fingerprint and a web OAuth client (the latter supplies the server client ID through `google-services.json`).

Phone sign-in and registration display `+91` and ask users to enter their 10-digit Indian mobile number. Use Firebase Authentication's configured test phone numbers and codes on an emulator. For real SMS, configure the Firebase project's billing and SMS region policy; quotas and charges apply.

Only Android Firebase configuration is supplied. Web/iOS require their own Firebase app configuration before authentication can run there. Never use real account credentials in automated tests. Tests inject a fake authentication service and do not contact Firebase.

After changing plugins or configuration, stop the app and rebuild with `flutter run` (hot reload is insufficient).

## Source organization

- `lib/main.dart`: entry point
- `lib/app.dart` and `lib/theme.dart`: application configuration and theme
- `lib/employee_shell.dart`: navigation and screen selection
- `lib/state/employee_controller.dart`: shared preview state
- `lib/screens/`: separate Dart files for all 21 screens, including login, registration, six profile forms, and the main app screens
- `lib/widgets/`: shared form fields, layouts, post card, and create-post sheet

The top-right grid opens the screen menu after login. Profile includes Sign out. Registration validates fields and matching passwords, then opens Personal Details with the entered name and contact details. Profile changes are kept in memory until the application restarts.

Reference artwork is represented by native Flutter graphics; backend services and original illustration assets are not included.

## Check

```powershell
flutter analyze
flutter test
```

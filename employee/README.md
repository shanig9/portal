# Career Connect employee frontend

## Run

```powershell
cd C:\Users\punel\portal\employee
flutter run
```

The Android app uses Firebase Authentication for email/password registration and login, Google sign-in, phone OTP, password reset, and sign-out. Existing Firebase sessions restore Home at startup. A successful email registration opens Personal Details. Profile forms and other app data still use local preview state; they are not stored in Firebase.

## Firebase Android setup

The Android package is `com.example.employee`. Its Firebase configuration belongs at `android/app/google-services.json`. Enable Email/Password, Google, and Phone in Firebase Authentication. In Project settings, select the Android app and add the signing certificate SHA-1 and SHA-256; download the updated configuration afterward.

For this machine's debug keystore:

```text
SHA-1: C0:B3:4C:94:20:2B:95:E9:7E:39:9B:02:A3:62:92:7A:0A:6C:FA:31
SHA-256: 0F:40:B8:35:45:C5:14:C8:56:BF:46:EC:42:29:4F:09:65:25:1F:D6:FF:0A:FA:35:2D:BE:AF:DC:C2:47:07:18
```

For release builds, register the actual release / Google Play app-signing certificates too. Google sign-in needs an Android OAuth client matching the package and signing fingerprint and a web OAuth client (the latter supplies the server client ID through `google-services.json`).

Phone sign-in expects an international number such as `+919876543210`. Use Firebase Authentication's configured test phone numbers and codes on an emulator. For real SMS, configure the Firebase project's billing and SMS region policy; quotas and charges apply. Phone numbers entered during email registration are contact details only, not verified phone credentials. Signing in separately with a phone can create a separate Firebase account; account linking is not implemented.

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

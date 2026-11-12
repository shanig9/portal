# Career Connect HR frontend

Flutter frontend based on the nine images in `hr screen/`.

## Preview

```powershell
cd C:\Users\punel\portal\hr
flutter run
```

The Android app uses Firebase Authentication. Choose **Login as Employer**, then select **Email** or **Phone OTP**. Registration supports either an email/password account or phone verification. Existing Firebase sessions restore the dashboard; **Profile → Sign out** clears the session and navigation history. Password reset sends an email through Firebase.

## Firebase configuration

The Android package is `com.example.hr`; its configuration belongs in `android/app/google-services.json`. Enable Email/Password and Phone in the Firebase project's Authentication settings. Register this machine's signing fingerprints under the **HR Android app**, separately from the employee app:

```text
SHA-1: C0:B3:4C:94:20:2B:95:E9:7E:39:9B:02:A3:62:92:7A:0A:6C:FA:31
SHA-256: 0F:40:B8:35:45:C5:14:C8:56:BF:46:EC:42:29:4F:09:65:25:1F:D6:FF:0A:FA:35:2D:BE:AF:DC:C2:47:07:18
```

Download the refreshed configuration after registering fingerprints. Release builds need their actual app-signing fingerprints too. Stop and rebuild the app after changing plugins or Android configuration; hot reload is insufficient.

Phone authentication requires an international number including its country code, such as `+919876543210`. On an emulator, use configured Firebase test phone numbers and codes. Real SMS depends on the project's billing, quotas, and SMS region policy. OTPs must verify successfully with Firebase before the dashboard opens; arbitrary codes are not accepted. Resending has a 60-second cooldown.

Company phone/email fields are contact details; email registration does not verify the company phone, and phone registration does not verify the company email. Separately signing in with email and phone may create separate Firebase identities; account linking is not implemented. The shared Firebase project authenticates identity only: employer roles and server authorization are not implemented.

Only Android Firebase configuration is supplied. Web and iOS need their own Firebase app configuration before authentication can run there.

## Screens

- Employer welcome, email/password login, registration, phone OTP, and password reset
- Applications dashboard, searchable/filterable application list, candidate details
- Detailed and quick job posting forms, date pickers, skill chips, draft saving, preview
- Job details, editing, active/closed status, and delete confirmation
- Employer profile and validated profile editor

The bottom navigation opens Home, Post Job, and Profile. The dashboard's Your Jobs section opens each job's details and editing controls.

Authentication is connected to Firebase and its session persists across restarts. Company profile edits, jobs, and applications still use local preview data; they reset when the app restarts. Messaging and uploads are not connected. The welcome illustration, logo, and candidate avatars use Flutter-drawn artwork and initials in place of original artwork and photos.

## Validation

```powershell
flutter analyze
flutter test
```

Widget tests use an injected fake authentication service and never send real SMS or create Firebase users. They cover authentication success/failure, registration validation, OTP verification and resend, password reset, sign-out, restored sessions, dashboard navigation, job workflows, and layouts at 320, 390, and 768 logical pixels. Live email and phone sign-in still require device testing against the configured Firebase project.

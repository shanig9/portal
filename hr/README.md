# Career Connect HR frontend

Flutter frontend based on the nine images in `hr screen/`.

## Preview

```powershell
cd C:\Users\punel\portal\hr
flutter run
```

For a browser preview, use `flutter run -d chrome`.

Start with **Explore frontend preview** to open the dashboard, or use the employer login/registration screens. The OTP screen accepts any six digits in this frontend demo.

## Screens

- Employer welcome, mobile login, registration, and OTP preview
- Applications dashboard, searchable/filterable application list, candidate details
- Detailed and quick job posting forms, date pickers, skill chips, draft saving, preview
- Job details, editing, active/closed status, and delete confirmation
- Employer profile and validated profile editor

The bottom navigation opens Home, Post Job, and Profile. The dashboard's Your Jobs section opens each job's details and editing controls.

All changes are held in memory and reset when the app restarts. No authentication, messaging, uploads, or backend services are connected. The welcome illustration, logo, and candidate avatars use Flutter-drawn artwork and initials in place of original artwork and photos.

## Validation

```powershell
flutter analyze
flutter test
```

Widget tests cover login validation, dashboard navigation, draft saving, cancelled profile edits, job preview/publish/edit/delete, and screen layouts at 320, 390, and 768 logical pixels.

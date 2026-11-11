# Career Connect employee frontend

## Run

```powershell
cd C:\Users\punel\portal\employee
flutter run
```

The app starts on **Login**. Select **Register** for the separate registration screen, or **Explore the preview** to open Home without credentials. Login, registration, social sign-in, and password reset are frontend demos; no account is created or authenticated by a server.

## Source organization

- `lib/main.dart`: entry point
- `lib/app.dart` and `lib/theme.dart`: application configuration and theme
- `lib/employee_shell.dart`: navigation and screen selection
- `lib/state/employee_controller.dart`: shared preview state
- `lib/screens/`: separate Dart files for all 21 screens, including login, registration, six profile forms, and the main app screens
- `lib/widgets/`: shared form fields, layouts, post card, and create-post sheet

The top-right grid opens the screen menu. Profile also links to Login. Registration validates fields and matching passwords, then opens Personal Details with the entered name and contact details. Changes are kept in memory until the application restarts.

Reference artwork is represented by native Flutter graphics; backend services and original illustration assets are not included.

## Check

```powershell
flutter analyze
flutter test
```

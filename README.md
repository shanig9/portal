# Career Connect

A job portal with separate Flutter frontends for employees and HR teams.

- [Employee app](employee/README.md): job discovery, career feed, profile setup, applications, messages, login, and registration.
- [HR app](hr/README.md): employer onboarding, application review, job management, and company profiles.
- `server/`: initial Node.js package with Express installed; backend implementation is pending.

The applications currently use local preview data. Authentication, uploads, messaging, and persistent storage will be connected after frontend completion.

## Run an app

Install Flutter, then run one of:

```sh
cd employee
flutter pub get
flutter run
```

```sh
cd hr
flutter pub get
flutter run
```

Use `flutter run -d chrome` for a browser preview.

## Checks

Run `flutter analyze` and `flutter test` from each Flutter app directory.

Design reference images are included in each app's screen-reference folder. Generated builds, dependency folders, local SDK paths, and credentials are excluded from version control.

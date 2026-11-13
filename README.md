# Career Connect

A job portal with separate Flutter frontends for employees and HR teams.

- [Employee app](employee/README.md): job discovery, career feed, profile setup, applications, messages, login, and registration.
- [HR app](hr/README.md): employer onboarding, application review, job management, and company profiles.
- `server/`: Express API for authenticated Cloudinary image and video uploads and a paginated reels feed. See [media API setup](server/README.md).

Most application screens use local preview data. The employee app includes Firebase authentication and an API-backed reels feed with image uploads and videos up to 60 seconds. Configure Firebase, Cloudinary, and `API_BASE_URL` using the media API setup guide to enable uploads and playback. Messaging remains preview data.

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

Document uploads and job application records can be persisted in Supabase through the Firebase-authenticated API. See [Supabase setup](supabase/README.md) for the schema, private bucket, and server-key configuration.

Run `flutter analyze` and `flutter test` from each Flutter app directory.

Design reference images are included in each app's screen-reference folder. Generated builds, dependency folders, local SDK paths, and credentials are excluded from version control.

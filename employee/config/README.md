# Career Connect API configuration

The default API origin is `https://portal-server-go1e.vercel.app` in debug and release builds. `API_BASE_URL` overrides this when supplied. Select **Career Connect employee (deployed server)** in VS Code to use the deployed backend without USB port forwarding. Rebuild/restart the app after changing its API configuration.

`local-usb.json` supplies the employee app's compile-time `API_BASE_URL`. It applies to both reels and application/document services. Putting this variable only in `server/.env` does not configure Flutter.

Connect one Android phone by USB, enable USB debugging, and accept its authorization prompt. Start the API with `npm start` from `server/`. From the repository root, choose **Career Connect employee (USB phone)** in VS Code's Run and Debug menu. Its pre-launch task forwards the phone's port 3000 to this computer's port 3000.

Alternatively, in PowerShell:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
cd C:\Users\admin\portal\employee
flutter run --dart-define-from-file=config/local-usb.json
```

For an installable local debug APK:

```powershell
flutter build apk --debug --dart-define-from-file=config/local-usb.json
```

USB debugging and ADB forwarding must remain available while testing. Re-run `adb reverse` after reconnecting the device. If multiple Android devices are attached, use `adb -s DEVICE_SERIAL reverse tcp:3000 tcp:3000` manually rather than the automatic task.

For Wi-Fi or a deployed app, supply a reachable server address using a separate configuration file or `--dart-define=API_BASE_URL=https://YOUR_SERVER_HOST`. The USB localhost configuration is for local debug testing; production builds need a reachable HTTPS backend. Fully restart/rebuild the app after changing compile-time configuration.

## Production HTTPS backend

After deploying the API, copy the production template from the employee directory:

```powershell
Copy-Item config/production.example.json config/production.json
```

The template uses `https://portal-server-go1e.vercel.app`. Do not append `/api`; services append their endpoint paths. `production.json` is ignored by Git. The API URL is public configuration, not a secret; never put Firebase private keys or Supabase server keys in these Flutter files.

Check the deployed server's `/health` endpoint, then build from `employee/`:

```powershell
flutter build appbundle --release --dart-define-from-file=config/production.json
```

For an APK instead:

```powershell
flutter build apk --release --dart-define-from-file=config/production.json
```

Production builds do not need a USB connection or `adb reverse`. Changing a server environment variable on Vercel does not change an already-built Android app; build again when its API URL changes. Configure release signing before distributing a store build; the existing Android release configuration uses the debug signing key.

## Vercel deployment prerequisites

This template configures the Android app's server address. It does not deploy the backend or make its existing storage/upload design suitable for Vercel.

- Deploy the API with `server/` as the Vercel project root. Confirm `/health` responds after deployment.
- Configure Firebase Admin credentials and server-only environment variables on the hosting platform. A Windows `GOOGLE_APPLICATION_CREDENTIALS` file path cannot be used on Vercel. The current backend uses `applicationDefault()`; hosted credential provisioning needs to be configured before startup can succeed.
- Configure Supabase document/application storage and the server's `SUPABASE_URL` and `SUPABASE_SECRET_KEY`.
- Migrate reel metadata from `server/data/reels.json` to durable shared storage. Vercel Functions do not provide durable writable application storage; `/tmp` is temporary and is not a database.
- Replace large multipart uploads through the function with authenticated direct-to-storage uploads and server-side validation/publication. The existing 10 MB document and 50 MB reel upload allowances exceed Vercel's 4.5 MB function request-body limit.
- For Flutter Web deployments, set `CORS_ORIGINS` to the actual frontend origins. Android does not use browser CORS enforcement.

References: [Express on Vercel](https://vercel.com/docs/frameworks/backend/express), [function payload limits](https://vercel.com/docs/functions/limitations), [filesystem support](https://vercel.com/docs/functions/runtimes).

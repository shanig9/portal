# Career Connect HR configuration

These files mirror the employee app's local USB and production API configuration. Use the same deployed backend origin for both apps. The current HR job publishing and chat features connect directly to Firebase; no current HR API client reads `API_BASE_URL`. These definitions prepare a consistent build configuration for future API-backed HR features. They do not redirect Firebase traffic through the API.

## Local USB phone

Start the backend with `npm start` from `server/`. Connect your Android phone, enable USB debugging, and accept authorization. From the repository root, select **Career Connect HR (USB phone)** in VS Code Run and Debug, or run:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
cd C:\Users\admin\portal\hr
flutter run --dart-define-from-file=config/local-usb.json
```

For an installable local debug APK, run from `hr/`:

```powershell
flutter build apk --debug --dart-define-from-file=config/local-usb.json
```

Re-run port forwarding after reconnecting the phone. With multiple devices, use `adb -s DEVICE_SERIAL reverse tcp:3000 tcp:3000` for each phone instead of the automatic launch task. Firebase features still require internet connectivity and deployed Firestore rules.

## Production

From `hr/`, copy the template:

```powershell
Copy-Item config/production.example.json config/production.json
```

Replace `https://api.example.com` with the real HTTPS backend origin, matching the employee configuration. Do not append `/api`. The example is a placeholder. `production.json` is ignored by Git. Never add server secrets or service-account credentials to either Flutter configuration.

Build from `hr/`:

```powershell
flutter build appbundle --release --dart-define-from-file=config/production.json
```

Or build an APK:

```powershell
flutter build apk --release --dart-define-from-file=config/production.json
```

Production builds do not need USB forwarding. Configure production Android signing before store distribution; the current release configuration uses the debug signing key. See `employee/config/README.md` for shared Vercel backend prerequisites and upload/storage limitations. These configuration files do not deploy that backend.

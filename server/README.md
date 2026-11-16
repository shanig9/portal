# Career Connect media API

Copy `.env.example` to `.env` and fill in your Cloudinary API secret and Firebase project ID. Set `GOOGLE_APPLICATION_CREDENTIALS` to an absolute path to a Firebase service-account JSON file outside this repository. Use the same Firebase project as the employee app. Never embed either credential in Flutter.

Run `npm install`, then `npm start` from `server/`.

The local API uses port `3000` (`PORT=3000` in `server/.env`) and prints `http://localhost:3000` when it starts. From the repository root you can also run `npm start` or `npm run dev`. On PowerShell systems that block npm scripts, use `npm.cmd start`. Check `http://localhost:3000/health` to confirm it is running.

## Deploy the API to Vercel

Set the Vercel project's **Root Directory** to `server` and **Framework Preset** to `Express`. Leave the Build Command and Output Directory overrides disabled; this backend does not generate a static output directory. Vercel detects the direct Express import in `index.js` and imports its exported app. Local `npm start` still listens on port 3000.

In Vercel Settings > Environment Variables, configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`, `FIREBASE_PROJECT_ID`, `SUPABASE_URL`, and `SUPABASE_SECRET_KEY`. Set `FIREBASE_SERVICE_ACCOUNT_JSON` to the complete private service-account JSON object, kept only in the server's environment settings. Use a current, unexposed key. Do not set `GOOGLE_APPLICATION_CREDENTIALS` to a Windows path on Vercel. Set `CORS_ORIGINS` to the actual Flutter web origins if applicable. The service account still needs Firestore and Firebase Authentication access.

Push the changed server files and lockfile, redeploy, and check `https://YOUR_DEPLOYMENT_HOST/health`. Then rebuild Flutter with `--dart-define=API_BASE_URL=https://YOUR_DEPLOYMENT_HOST`. There is no `:3000` suffix in the public HTTPS URL. Chat creation uses Vercel's `waitUntil` so it can complete after returning the saved application.

Vercel Functions limit request bodies to 4.5 MB, including multipart overhead. The existing 50 MB reel and 10 MB PDF upload endpoints therefore cannot accept their full advertised sizes on Vercel. Supporting larger uploads there requires direct-to-provider uploads; alternatively host this API on a regular Node.js server with adequate request limits. See [Express on Vercel](https://vercel.com/docs/frameworks/backend/express) and [function limits](https://vercel.com/docs/functions/limitations).

- `GET /health`: health check.
- `GET /api/reels?limit=10&cursor=<last-id>`: public feed, newest first, with `items` and `nextCursor`.
- `POST /api/reels`: multipart `file` and optional `caption` (500 characters maximum). Requires `Authorization: Bearer <Firebase ID token>`. Returns the published reel.

Accepts JPEG, PNG, WebP, MP4, MOV and WebM, up to 50 MB. Cloudinary metadata is checked before publication: videos must have a visual track and duration greater than zero and no longer than 60 seconds. Rejected media is deleted. The entire file is uploaded before duration validation; invalid videos may still incur provider usage. Uploads are limited to 10 requests per IP per 15 minutes.

From `employee/`, run:

```sh
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

For an Android emulator use `http://10.0.2.2:3000`; for a physical device use your server's reachable HTTPS address. Android release builds should use HTTPS. Add your web app's exact origin to `CORS_ORIGINS` (comma separated). The player starts muted to support browser autoplay; use its speaker button for audio.

Debug builds of the employee reels screen default to `http://10.0.2.2:3000` on Android and `http://localhost:3000` on web/desktop when `API_BASE_URL` is omitted. Start this API before opening Reels. Debug Android builds allow local HTTP traffic. Physical phones and release builds require an explicit reachable `API_BASE_URL`; localhost on a phone refers to the phone itself. For example, build with `flutter build apk --dart-define=API_BASE_URL=https://YOUR_REACHABLE_API_HOST` after deploying the API. Hot reload does not change build defines; restart/rebuild the app.

Reel files stay on Cloudinary; metadata is stored in the hosted Supabase `career_reels` table. Run `supabase/schemas/reels.sql` once in your Supabase project's SQL Editor, then configure `SUPABASE_URL` and `SUPABASE_SECRET_KEY` in `server/.env`. Use the server secret key, never the anon/publishable key. Restart the API after changing configuration. The server does not fall back to local JSON storage. Existing `server/data/reels.json` records are not automatically imported. The feed is public: uploads should contain only content intended for public viewing. Cloudinary is file hosting here, not live broadcasting.

`npm test` verifies duration validation, authentication, rejected-media cleanup, persistence, and pagination without real credentials. Live Cloudinary uploads require your configured account.

To publish supplied MP4 files as Career Connect library reels, first create `career_reels` using `supabase/schemas/reels.sql`, then run `node import-reels.js "C:/path/to/clip.mp4" [...]` from `server/`. This trusted server command uploads to Cloudinary and saves feed records in Supabase. It normalizes clips to Android-compatible H.264/AAC and trims only footage beyond 59.9 seconds to stay within the 60-second limit after frame/audio rounding. Source files remain unchanged. Content hashes prevent duplicate imports; failed database writes trigger media cleanup. No Firebase user identity is impersonated and the authenticated user-upload API remains protected.

Run `node check-cloudinary.js` to verify media-provider access without printing credentials. If the local network has a working IPv6 route but IPv4 uploads time out, set `CLOUDINARY_IP_FAMILY=6` in the local `server/.env` and restart the API. Leave this setting empty on normal networks and hosted deployments. `4` is also supported when explicitly needed.

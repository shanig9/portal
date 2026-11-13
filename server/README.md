# Career Connect media API

Copy `.env.example` to `.env` and fill in your Cloudinary API secret and Firebase project ID. Set `GOOGLE_APPLICATION_CREDENTIALS` to an absolute path to a Firebase service-account JSON file outside this repository. Use the same Firebase project as the employee app. Never embed either credential in Flutter.

Run `npm install`, then `npm start` from `server/`.

- `GET /health`: health check.
- `GET /api/reels?limit=10&cursor=<last-id>`: public feed, newest first, with `items` and `nextCursor`.
- `POST /api/reels`: multipart `file` and optional `caption` (500 characters maximum). Requires `Authorization: Bearer <Firebase ID token>`. Returns the published reel.

Accepts JPEG, PNG, WebP, MP4, MOV and WebM, up to 50 MB. Cloudinary metadata is checked before publication: videos must have a visual track and duration greater than zero and no longer than 60 seconds. Rejected media is deleted. The entire file is uploaded before duration validation; invalid videos may still incur provider usage. Uploads are limited to 10 requests per IP per 15 minutes.

From `employee/`, run:

```sh
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

For an Android emulator use `http://10.0.2.2:3000`; for a physical device use your server's reachable HTTPS address. Android release builds should use HTTPS. Add your web app's exact origin to `CORS_ORIGINS` (comma separated). The player starts muted to support browser autoplay; use its speaker button for audio.

The API currently stores feed metadata in `server/data/reels.json`. Keep that directory on a persistent disk, run one server process, and back it up. This is a starter implementation; use a shared database before running multiple API instances. Media files remain on Cloudinary. The feed is public: uploads should contain only content intended for public viewing. Cloudinary is file hosting here, not live broadcasting.

`npm test` verifies duration validation, authentication, rejected-media cleanup, persistence, and pagination without real credentials. Live Cloudinary uploads require your configured account.

# Career Connect documents and applications

Target project: `https://jnsipuxlafjbgxbgvnth.supabase.co`.

## First-time hosted setup

1. In the project's SQL Editor, review and run [schemas/records.sql](schemas/records.sql) once. This creates two tables and a private `career-documents` bucket. It deliberately rejects repeated setup rather than silently changing existing tables. This repository starts with a declarative schema; future changes should be generated and reviewed with the Supabase CLI's schema diff workflow.
2. In Project Settings > API Keys, create or copy a server secret key (`sb_secret_...`). Add it to the ignored `server/.env` as `SUPABASE_SECRET_KEY`. Never put it in Flutter, source control, or chat. The project URL has already been configured locally.
3. Keep the existing Firebase server credentials configured. Firebase login identifies the user, and the API uses the verified UID for every record operation. No Supabase Auth migration or Firebase third-party integration is required for this server-mediated setup.
4. From `server/`, run `node check-supabase.js`. It checks both tables and confirms the bucket is private without reading document contents. Then restart `npm start`.
5. Launch the employee app with the same `API_BASE_URL` used for reels. For Chrome: `flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000`.

The project connection is not complete until the SQL has been applied and the verification script succeeds. A dashboard URL alone does not grant database access.

## Behavior and access model

- Upload PDF resumes and supporting documents up to 10 MB. Files and metadata persist across sessions; lists show the latest 100 records.
- The API checks PDF MIME type, extension, and file signature. If metadata insertion fails, it attempts to remove the uploaded object.
- Applying asks for confirmation and attaches the latest uploaded document. Use Resume to upload the intended resume before applying.
- Applications persist in `career_applications`; the database prevents duplicate submissions by the same user and job key and enforces ownership of attached documents.
- My Applications loads saved records and actual status values. New records start at `submitted`.
- Files are private. Downloads require owner verification and use signed links that expire after 60 seconds. An issued link remains usable by its holder until expiration.
- RLS is enabled on both tables with no frontend policies or grants. Only the API holds the secret key. That key bypasses RLS, so API ownership checks are required; do not replace it with the publishable key.
- No bucket policies grant public access. Do not make the bucket public or add broad storage policies.

Current jobs in the employee app are still preview data. Applications store their title/company/location snapshot and a company/title key; this is not yet a trusted HR job catalog. HR job publishing, employer access to applications, status updates, and document retention/deletion are separate work. The API does not expose applications or documents to other users, including HR, yet.

## API

Every route below requires a Firebase ID token in `Authorization: Bearer <token>`:

- `GET /api/documents`: the current user's latest documents.
- `POST /api/documents`: multipart field `file`, one PDF up to 10 MB.
- `GET /api/documents/:id/download`: owner-only signed URL.
- `GET /api/applications`: the current user's latest applications.
- `POST /api/applications`: JSON `jobKey`, `jobTitle`, `company`, `location`, `documentId`. Identity and status cannot be set by the caller.

`npm test` verifies authentication, ownership isolation, PDF validation, metadata failure cleanup, and reels regression tests with mocked providers. `node check-supabase.js` is the separate live connectivity check.

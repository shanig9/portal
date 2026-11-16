# Career Connect application chat

Both apps share `chat/`: recruiter-owned published jobs, application conversations, live text messages, and persistent history. Every registered user can use their own account; no per-job UID configuration is required.

## How it works

1. An HR user signs in and publishes a job. Firestore records their Firebase UID as its immutable owner. Draft and archived jobs stay out of the employee feed.
2. The employee sees published openings, uploads a PDF resume, and applies. The existing API verifies the saved job, takes its title/company/location from Firestore, and stores the application in Supabase.
3. The server provisions one private conversation per application with the employee and job owner as participants. HR can send the first message through the portal's Messages icon; the employee can send first through My Applications ? Message HR or the Messages tab.
4. Both apps listen to Firestore for messages. History survives app restarts. Messages load newest 50 first, with an earlier-messages button. Unsent writes show Sending. Server rules reject forged senders and non-participants.

## What the project owner needs to configure

1. Create the default Cloud Firestore database in Firebase project `job-portal-54254` using Production mode. Both Android configuration files must belong to that project.
2. Publish `firebase/firestore.rules` in Firebase Console ? Firestore Database ? Rules. Review and merge with any existing rules for unrelated collections. The repository's rules define `career_jobs` and `career_chats`. Alternatively, from the repository root:

   ```powershell
   firebase deploy --only firestore:rules --project job-portal-54254
   ```

3. Keep the existing records API and Supabase document/application tables and private bucket configured. The server reads `SUPABASE_URL` and **`SUPABASE_SECRET_KEY`** (that exact variable name). Configure Firebase Admin using `GOOGLE_APPLICATION_CREDENTIALS` pointing to a private service-account file on the server; never put it in either app. This server identity needs Firestore access in the same project.
4. Restart/deploy the updated API. The employee build needs `--dart-define=API_BASE_URL=https://YOUR_REACHABLE_API_HOST` pointing to this server. The HR chat/job feed connects directly to Firebase.
5. Run `flutter pub get` in both apps and rebuild. Create separate employee and HR accounts for testing. Do not share passwords or service-account keys.

No UID mapping, public user directory, or manual conversation creation is needed. Signing into the HR app lets an account publish openings; this release does not verify company identity or establish a platform-approved recruiter role. A company approval process is separate work if required.

## Acceptance test before calling chat live

For a physical Android phone connected by USB, start the API and run `./run-phone.ps1` from `employee/`. This configures `adb reverse` and builds the app with `API_BASE_URL=http://127.0.0.1:3000`. Keep USB connected; rerun the script after disconnecting. The emulator default `10.0.2.2` is not a physical phone address. For Wi-Fi testing, explicitly use the computer's LAN IP and allow access to its API port.

The server also checks Firebase login revocation. Its service account needs `firebaseauth.users.get`, included in Firebase Authentication Viewer (`roles/firebaseauth.viewer`), in addition to Firestore access. Run `node check-application-dependencies.js` from `server/` to check credential acquisition, Auth access, job reads, and the application database separately. No application or user records are created by this diagnostic.

If applying times out, run `node check-firebase.js` from `server/` to verify the server's job lookup. `GOOGLE_APPLICATION_CREDENTIALS` must point to an existing private service-account JSON file on this machine. A `PERMISSION_DENIED` result requires Firestore IAM access for that service account in `job-portal-54254` (Cloud Datastore User, `roles/datastore.user`, supports the job reads and chat writes). Firebase client security rules do not grant the Admin SDK this access. After correcting IAM or the credential path, restart the API. The API returns an error if job verification stalls; saved applications no longer wait for optional chat provisioning.

- Publish a job in the HR app and verify the employee app sees it.
- Upload a resume and apply with a separate employee account.
- In HR ? Messages, send the first message; verify the employee receives and replies.
- Repeat with employee sending first on a second application.
- Restart both apps and confirm history remains.
- Confirm a third account cannot access either conversation, impersonate a sender, or change job ownership.
- Confirm drafts, closed openings, future openings, and expired openings cannot receive new applications.
- Check error recovery without a network connection.

## Existing records and limitations

Old local sample jobs have no real recruiter owner and are not automatically migrated. HR must publish real openings; new applications use those canonical job IDs. Old applications against sample titles cannot be assigned safely and must not be connected to an arbitrary HR account. Existing conversations retain their original participants if job information changes.

Application submission attempts room provisioning automatically. A chat outage does not discard an accepted application; the employee's Message HR action retries provisioning using their saved application. Deleting a job archives it and preserves ownership for existing applications.

This stage provides text chat and saved history. Push notifications, unread counts, attachments, read receipts, moderation, and a verified employer approval process are follow-up features. Rules have not been deployed and live device-to-device delivery has not been verified by the local code checks.

References: [Firestore Flutter setup](https://firebase.google.com/docs/firestore/quickstart?platform=flutter), [Firestore access rules](https://firebase.google.com/docs/firestore/security/rules-conditions).

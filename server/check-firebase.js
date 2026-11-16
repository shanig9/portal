const path = require('node:path');
const fs = require('node:fs');
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const deadline = setTimeout(() => {
  console.error('Firestore connection timed out. Check server credentials, Firestore access, and network connectivity.');
  process.exit(1);
}, 30000);

(async () => {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    fs.accessSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, fs.constants.R_OK);
    const account = JSON.parse(fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
    console.log('Credential identity:', account.client_email || account.type);
  }
  console.log('Target project:', process.env.FIREBASE_PROJECT_ID);
  if (process.env.FIRESTORE_EMULATOR_HOST) console.log('Firestore emulator:', process.env.FIRESTORE_EMULATOR_HOST);
  const credential = applicationDefault();
  initializeApp({ credential, projectId: process.env.FIREBASE_PROJECT_ID });
  if (process.argv.includes('--iam')) {
    const permissions = ['datastore.entities.get', 'datastore.entities.list',
      'datastore.entities.create', 'datastore.databases.get', 'firebaseauth.users.get'];
    const { access_token } = await credential.getAccessToken();
    const response = await fetch(`https://cloudresourcemanager.googleapis.com/v3/projects/${encodeURIComponent(process.env.FIREBASE_PROJECT_ID)}:testIamPermissions`, {
      method: 'POST', headers: { Authorization: `Bearer ${access_token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ permissions }), signal: AbortSignal.timeout(10000),
    });
    const result = await response.json();
    if (response.ok) {
      for (const permission of permissions) {
        console.log(`${permission}: ${result.permissions?.includes(permission) ? 'granted' : 'not granted at project scope'}`);
      }
    } else {
      console.log('IAM permission check unavailable:', response.status,
        result.error?.details?.find((detail) => detail.reason)?.reason || result.error?.status);
    }
    if (process.argv.includes('--iam-only')) {
      clearTimeout(deadline);
      return;
    }
  }
  const db = getFirestore();
  if (process.argv.includes('--rest')) db.settings({ preferRest: true });
  try {
    const started = Date.now();
    await db.collection('career_jobs').limit(1).get();
    console.log(`Career Connect Firestore job lookup: connected (${Date.now() - started} ms)`);
  } finally {
    clearTimeout(deadline);
    await db.terminate();
  }
})().catch((error) => {
  clearTimeout(deadline);
  console.error('Firestore connection failed:', error.code || error.name,
    error.message?.replace(/-----BEGIN[\s\S]*?-----END[^-]*-----/g, '[redacted]'));
  process.exitCode = 1;
});

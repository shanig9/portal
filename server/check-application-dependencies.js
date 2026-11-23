const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const { initializeApp } = require('firebase-admin/app');
const { firebaseOptions } = require('./firebase-config');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { createClient } = require('@supabase/supabase-js');

async function stage(name, action) {
  const started = Date.now();
  let timer;
  try {
    await Promise.race([action(), new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error('timed out after 12 seconds')), 12000);
    })]);
    console.log(`${name}: connected (${Date.now() - started} ms)`);
  } catch (error) {
    console.error(`${name}: ${error.code || error.name}: ${error.message}`);
    process.exitCode = 1;
  } finally { clearTimeout(timer); }
}

(async () => {
  const options = firebaseOptions();
  const credential = options.credential;
  initializeApp(options);
  await stage('Firebase credential token', () => credential.getAccessToken());
  await stage('Firebase Auth account lookup', async () => {
    try { await getAuth().getUser('career-connect-connectivity-check'); }
    catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
  });
  const db = getFirestore();
  if (process.argv.includes('--rest')) db.settings({ preferRest: true });
  await stage('Firestore job document lookup', () => db.collection('career_jobs').doc('career-connect-connectivity-check').get());
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  for (const [table, owner] of [['career_applications', 'applicant_uid'], ['career_documents', 'owner_uid']]) {
    await stage(`Supabase ${table}`, async () => {
      const result = await client.from(table).select('id').eq(owner, 'career-connect-connectivity-check').limit(1);
      if (result.error) throw result.error;
    });
  }
  await stage('Supabase career-documents bucket', async () => {
    const result = await client.storage.getBucket('career-documents');
    if (result.error) throw result.error;
    if (result.data.public) throw new Error('career-documents bucket must be private');
  });
  // SDK retries can outlive the diagnostic deadline. No records are written.
  process.exit(process.exitCode || 0);
})().catch((error) => { console.error(error.code || error.name); process.exit(1); });

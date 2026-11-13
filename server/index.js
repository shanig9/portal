require('dotenv').config();
const path = require('node:path');
const { v2: cloudinary } = require('cloudinary');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { createApp, createStore } = require('./reels');
const { createClient } = require('@supabase/supabase-js');
const { createRecordsRepository } = require('./records');

for (const key of ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'FIREBASE_PROJECT_ID']) {
  if (!process.env[key]) throw new Error(`Missing ${key}. See server/.env.example.`);
}
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});
initializeApp({ credential: applicationDefault(), projectId: process.env.FIREBASE_PROJECT_ID });
const app = createApp({
  recordsRepository: process.env.SUPABASE_URL && process.env.SUPABASE_SECRET_KEY
    ? createRecordsRepository(createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
      { auth: { persistSession: false, autoRefreshToken: false } })) : undefined,
  cloudinary,
  verifyToken: (token) => getAuth().verifyIdToken(token, true),
  store: createStore(path.resolve(process.env.REELS_DATA_FILE || 'data/reels.json')),
  origins: (process.env.CORS_ORIGINS || 'http://localhost:8080').split(',').map((value) => value.trim()),
});
app.listen(process.env.PORT || 3000, () => console.log('Career Connect API is running.'));

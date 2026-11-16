const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
// Export a handler even when a dependency or configuration fails at cold start.
const app = express();
app.disable('x-powered-by');
let startupStage = 'loading dependencies';
let startupFailure;
app.use((req, res, next) => {
  if (startupFailure) return res.status(503).set('Cache-Control', 'no-store').json(startupFailure);
  next();
});
try {
const { waitUntil } = require('@vercel/functions');
const { v2: cloudinary } = require('cloudinary');
const { initializeApp, getApps } = require('firebase-admin/app');
const { firebaseOptions } = require('./firebase-config');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { createChatPublisher, createJobResolver } = require('./chat');
const { createApp } = require('./reels');
const { createReelsStore } = require('./reels-store');
const { createClient } = require('@supabase/supabase-js');
const { createRecordsRepository } = require('./records');

startupStage = 'checking environment variables';
for (const key of ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET', 'FIREBASE_PROJECT_ID', 'SUPABASE_URL', 'SUPABASE_SECRET_KEY']) {
  if (!process.env[key]) throw new Error(`Missing ${key}. See server/.env.example.`);
}
startupStage = 'configuring Cloudinary';
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});
startupStage = 'initializing Firebase credentials';
if (!getApps().length) initializeApp(firebaseOptions());
startupStage = 'initializing Firestore';
const publishChat = createChatPublisher(getFirestore());
const resolveJob = createJobResolver(getFirestore());
startupStage = 'initializing Supabase';
const database = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
  { auth: { persistSession: false, autoRefreshToken: false } });
startupStage = 'registering API routes';
createApp({
  app,
  recordsRepository: createRecordsRepository(database, publishChat, resolveJob, {
    scheduleBackgroundTask: process.env.VERCEL ? waitUntil : () => {},
  }),
  cloudinary,
  verifyToken: (token) => getAuth().verifyIdToken(token, true),
  store: createReelsStore(database),
  origins: (process.env.CORS_ORIGINS || 'http://localhost:8080').split(',').map((value) => value.trim()),
});
} catch (error) {
  // Arbitrary SDK errors can contain secrets. Report only controlled diagnostics.
  const required = ['CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET',
    'FIREBASE_PROJECT_ID', 'SUPABASE_URL', 'SUPABASE_SECRET_KEY'];
  if (process.env.VERCEL) required.push('FIREBASE_SERVICE_ACCOUNT_JSON');
  const diagnostic = {
    app: 'Career Connect', status: 'unavailable', code: 'STARTUP_FAILED',
    stage: startupStage,
    missingVariables: required.filter((key) => !process.env[key]?.trim()),
  };
  console.error('Career Connect startup failed:', JSON.stringify(diagnostic));
  startupFailure = diagnostic;
  if (!process.env.VERCEL) throw error;
}
module.exports = app;

// Vercel imports the handler; local `node index.js` starts a normal HTTP server.
if (require.main === module && !process.env.VERCEL) {
  const port = Number(process.env.PORT || 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be a number between 1 and 65535.');
  }
  const server = app.listen(port, '0.0.0.0');
  server.once('listening', () => {
    console.log(`Career Connect API is running at http://localhost:${port}`);
  });
  server.on('error', (error) => {
    console.error(error.code === 'EADDRINUSE'
      ? `Port ${port} is already in use. Stop the existing server or change PORT in server/.env.`
      : `Career Connect API could not start: ${error.message}`);
    process.exitCode = 1;
  });
}

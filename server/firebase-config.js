const fs = require('node:fs');
const { applicationDefault, cert } = require('firebase-admin/app');

function firebaseOptions(env = process.env) {
  const projectId = env.FIREBASE_PROJECT_ID;
  if (env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim()) {
    let account;
    try { account = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON); }
    catch { throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON must contain the complete service-account JSON object.'); }
    if (account?.type !== 'service_account' ||
        !['client_email', 'private_key', 'project_id'].every((field) => typeof account[field] === 'string' && account[field])) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is missing required service-account fields.');
    }
    if (projectId && account.project_id !== projectId) {
      throw new Error('The Firebase service account must belong to FIREBASE_PROJECT_ID.');
    }
    // Handles JSON copied with literal escaped line breaks as well as normal JSON.
    account.private_key = account.private_key.replace(/\\n/g, '\n');
    let credential;
    try { credential = cert(account); }
    catch { throw new Error('The Firebase service-account private key is invalid. Use the complete downloaded JSON.'); }
    return { projectId: projectId || account.project_id, credential };
  }
  if (env.VERCEL) {
    throw new Error('Set FIREBASE_SERVICE_ACCOUNT_JSON in Vercel environment variables. A local credential file path cannot be used there.');
  }
  if (env.GOOGLE_APPLICATION_CREDENTIALS) {
    fs.accessSync(env.GOOGLE_APPLICATION_CREDENTIALS, fs.constants.R_OK);
  }
  return { projectId, credential: applicationDefault() };
}

module.exports = { firebaseOptions };

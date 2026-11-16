const path = require('node:path');
const fs = require('node:fs');
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const { firebaseOptions } = require('./firebase-config');

async function main() {
  const options = firebaseOptions();
  const account = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim() ||
    fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'));
  if (account.type !== 'service_account' || account.project_id !== options.projectId) {
    throw new Error('The server service account must match FIREBASE_PROJECT_ID.');
  }
  const command = `gcloud projects add-iam-policy-binding ${options.projectId} --member="serviceAccount:${account.client_email}" --role="roles/firebaseauth.viewer"`;
  const deadline = setTimeout(() => {
    console.error('Cloud permission check timed out. A project owner can run in Cloud Shell:\n' + command);
    process.exit(1);
  }, 30000);
  try {
    const { access_token } = await options.credential.getAccessToken();
    async function call(method, body) {
      const response = await fetch(`https://cloudresourcemanager.googleapis.com/v1/projects/${encodeURIComponent(options.projectId)}:${method}`, {
        method: 'POST', headers: { Authorization: `Bearer ${access_token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body), signal: AbortSignal.timeout(12000),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(`Google Cloud rejected ${method} (${response.status}, ${result.error?.status}).`);
      return result;
    }
    const needed = ['firebaseauth.users.get', 'resourcemanager.projects.getIamPolicy', 'resourcemanager.projects.setIamPolicy'];
    const { permissions = [] } = await call('testIamPermissions', { permissions: needed });
    console.log('Server account:', account.client_email);
    if (permissions.includes('firebaseauth.users.get')) {
      console.log('Firebase Authentication user-read permission is already effective. No IAM changes made.');
      return;
    }
    if (!needed.slice(1).every((permission) => permissions.includes(permission))) {
      throw new Error('The server cannot read Firebase users and cannot change project IAM. A project owner must run in Google Cloud Shell:\n' + command);
    }
    const policy = await call('getIamPolicy', { options: { requestedPolicyVersion: 3 } });
    const member = `serviceAccount:${account.client_email}`;
    const role = 'roles/firebaseauth.viewer';
    policy.bindings ||= [];
    let binding = policy.bindings.find((item) => item.role === role && !item.condition);
    if (!binding) { binding = { role, members: [] }; policy.bindings.push(binding); }
    if (!binding.members.includes(member)) binding.members.push(member);
    // Preserve existing bindings, conditions, and etag; do not overwrite concurrent changes.
    await call('setIamPolicy', { policy });
    console.log('Granted Firebase Authentication Viewer to the server account. Allow time for IAM propagation.');
  } finally { clearTimeout(deadline); }
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; });

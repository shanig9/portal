const { test } = require('node:test');
const assert = require('node:assert/strict');
const { generateKeyPairSync } = require('node:crypto');
const { spawnSync } = require('node:child_process');
const { firebaseOptions } = require('./firebase-config');

// Disposable test credential. Never reads or contacts a real Firebase account.
const { privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});
const account = {
  type: 'service_account', project_id: 'career-connect-test',
  client_email: 'server@example.com', private_key: privateKey,
};

test('hosted startup failure returns safe diagnostics instead of crashing the function', () => {
  const result = spawnSync(process.execPath, ['-e', `
    const assert = require('node:assert/strict');
    const app = require('./index');
    const server = app.listen(0, '127.0.0.1', async () => {
      try {
        const response = await fetch('http://127.0.0.1:' + server.address().port + '/health');
        assert.equal(response.status, 503);
        assert.equal(response.headers.get('cache-control'), 'no-store');
        const body = await response.json();
        assert.equal(body.code, 'STARTUP_FAILED');
        assert.equal(body.stage, 'checking environment variables');
        assert.ok(body.missingVariables.includes('CLOUDINARY_API_SECRET'));
        assert.ok(!JSON.stringify(body).includes('private_key'));
      } catch (error) { console.error(error); process.exitCode = 1; }
      finally { server.close(); }
    });
  `], {
    cwd: __dirname, encoding: 'utf8', timeout: 15000,
    env: { ...process.env, VERCEL: '1', CLOUDINARY_API_SECRET: '' },
  });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
});

test('hosted Firebase JSON works without a local credential file', () => {
  const options = firebaseOptions({
    FIREBASE_PROJECT_ID: account.project_id, VERCEL: '1',
    GOOGLE_APPLICATION_CREDENTIALS: 'C:/does-not-exist.json',
    FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify(account),
  });
  assert.equal(options.projectId, account.project_id);
  assert.equal(typeof options.credential.getAccessToken, 'function');
});

test('hosted credentials fail clearly for missing, malformed, or wrong-project JSON', () => {
  assert.throws(() => firebaseOptions({ VERCEL: '1' }), /Set FIREBASE_SERVICE_ACCOUNT_JSON/);
  assert.throws(() => firebaseOptions({ FIREBASE_SERVICE_ACCOUNT_JSON: 'bad' }), /complete service-account JSON/);
  assert.throws(() => firebaseOptions({ FIREBASE_SERVICE_ACCOUNT_JSON: '{}' }), /required service-account fields/);
  assert.throws(() => firebaseOptions({
    FIREBASE_PROJECT_ID: 'another-project', FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify(account),
  }), /must belong/);
});

test('Vercel entrypoint exports an Express handler without binding a local port', () => {
  const source = `
    const assert = require('node:assert/strict');
    const net = require('node:net');
    const listen = net.Server.prototype.listen;
    net.Server.prototype.listen = () => { throw new Error('Entrypoint opened a port'); };
    const app = require('./index');
    assert.equal(typeof app, 'function');
    net.Server.prototype.listen = listen;
    const server = app.listen(0, '127.0.0.1', async () => {
      try {
        const response = await fetch('http://127.0.0.1:' + server.address().port + '/health');
        assert.equal(response.status, 200);
        assert.equal((await response.json()).app, 'Career Connect');
        console.log('HOSTED_HANDLER_OK');
      } catch (error) { console.error(error.message); process.exitCode = 1; }
      finally { server.close(); }
    });
  `;
  const result = spawnSync(process.execPath, ['-e', source], {
    cwd: __dirname, encoding: 'utf8', timeout: 15000,
    env: {
      ...process.env, VERCEL: '1', PORT: 'not-a-port',
      FIREBASE_PROJECT_ID: account.project_id,
      FIREBASE_SERVICE_ACCOUNT_JSON: JSON.stringify(account),
      GOOGLE_APPLICATION_CREDENTIALS: 'C:/does-not-exist.json',
      CLOUDINARY_CLOUD_NAME: 'test', CLOUDINARY_API_KEY: 'test', CLOUDINARY_API_SECRET: 'test',
      SUPABASE_URL: 'https://example.com', SUPABASE_SECRET_KEY: 'test-key',
    },
  });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
  assert.match(result.stdout, /HOSTED_HANDLER_OK/);
});

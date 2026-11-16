const { test } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');

test('Firebase Auth loads and JWKS verification works without synchronous ESM support', () => {
  const result = spawnSync(process.execPath, ['--no-experimental-require-module', '-e', `
    const assert = require('node:assert/strict');
    const { generateKeyPairSync, sign, verify } = require('node:crypto');
    const { getAuth } = require('firebase-admin/auth');
    const jwks = require('jwks-rsa');
    assert.equal(typeof getAuth, 'function');
    const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
    const key = { ...publicKey.export({ format: 'jwk' }), kid: 'test-key', use: 'sig', alg: 'RS256' };
    const client = jwks({ cache: false, jwksUri: 'https://example.com/keys',
      fetcher: async () => ({ keys: [key] }) });
    client.getSigningKey('test-key').then((signingKey) => {
      const payload = Buffer.from('Career Connect signing-key compatibility');
      const signature = sign('RSA-SHA256', payload, privateKey);
      assert.ok(verify('RSA-SHA256', payload, signingKey.getPublicKey(), signature));
      assert.equal(verify('RSA-SHA256', Buffer.from('tampered'), signingKey.getPublicKey(), signature), false);
    }).catch((error) => { console.error(error); process.exitCode = 1; });
  `], { cwd: __dirname, encoding: 'utf8', timeout: 15000 });
  assert.equal(result.status, 0, result.stderr || result.error?.message);
});

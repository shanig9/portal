const { test } = require('node:test');
const assert = require('node:assert/strict');
const { authenticate } = require('./authentication');

test('authentication bounds stalled checks while keeping revocation verification enabled', async () => {
  await assert.rejects(authenticate(() => new Promise(() => {}), 'token', { timeoutMs: 10 }), { status: 503 });
  assert.deepEqual(await authenticate(async () => ({ uid: 'employee-1' }), 'token'), { uid: 'employee-1' });
});

test('server permission errors do not incorrectly expire a valid user session', async () => {
  await assert.rejects(authenticate(async () => {
    throw Object.assign(new Error('Denied'), { code: 'auth/insufficient-permission' });
  }, 'token'), { status: 503 });
  await assert.rejects(authenticate(async () => {
    throw Object.assign(new Error('Revoked'), { code: 'auth/id-token-revoked' });
  }, 'token'), { status: 401 });
});

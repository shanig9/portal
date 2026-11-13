const { test } = require('node:test');
const assert = require('node:assert/strict');
const { mkdtemp, rm } = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { createApp, createStore, validateMedia } = require('./reels');

test('media validation rejects long videos, audio-only uploads and accepts the 60-second boundary', () => {
  const media = { resource_type: 'video', format: 'mp4', width: 720, height: 1280, bytes: 100, duration: 60 };
  assert.equal(validateMedia(media), null);
  assert.match(validateMedia({ ...media, duration: 60.01 }), /60 seconds/);
  assert.match(validateMedia({ ...media, width: undefined }), /Choose/);
  assert.match(validateMedia({ ...media, duration: undefined }), /60 seconds/);
});

test('authenticated upload publishes media; rejected videos are deleted; feed paginates', async (t) => {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'career-connect-'));
  const store = createStore(path.join(directory, 'reels.json'));
  let duration = 60;
  let deleted = 0;
  const cloudinary = { url: () => 'https://example.com/thumb.jpg', uploader: {
    upload_stream: (_, callback) => ({ end: () => callback(null, {
      resource_type: 'video', format: 'mp4', width: 720, height: 1280,
      bytes: 10, duration, public_id: 'test', secure_url: 'https://example.com/reel.mp4',
    }) }),
    destroy: async () => { deleted++; },
  } };
  const app = createApp({ cloudinary, store, verifyToken: async (token) => {
    if (token !== 'valid') throw Error('invalid');
    return { uid: 'employee-1', name: 'Test Member' };
  } });
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(async () => { await new Promise((resolve) => server.close(resolve)); await rm(directory, { recursive: true }); });
  const url = `http://127.0.0.1:${server.address().port}/api/reels`;
  assert.equal((await fetch(url, { method: 'POST' })).status, 401);
  assert.equal((await fetch(url, { method: 'POST', headers: { Authorization: 'Bearer invalid' } })).status, 401);
  async function upload() {
    const form = new FormData();
    form.append('file', new Blob(['video'], { type: 'video/mp4' }), 'test.mp4');
    form.append('caption', 'Career Connect');
    return fetch(url, { method: 'POST', headers: { Authorization: 'Bearer valid' }, body: form });
  }
  const response = await upload();
  assert.equal(response.status, 201);
  assert.equal((await response.json()).ownerId, 'employee-1');
  duration = 61;
  assert.equal((await upload()).status, 400);
  assert.equal(deleted, 1);
  assert.equal((await store.read()).length, 1);
  await store.add({ id: 'second' });
  const first = await (await fetch(`${url}?limit=1`)).json();
  assert.equal(first.items[0].id, 'second');
  const next = await (await fetch(`${url}?limit=1&cursor=${first.nextCursor}`)).json();
  assert.equal(next.items.length, 1);
  assert.equal(next.nextCursor, null);
});

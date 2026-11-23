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
  duration = 30;
  store.add = async () => { throw new Error('Database unavailable'); };
  assert.equal((await upload()).status, 500);
  assert.equal(deleted, 2, 'media is removed when metadata cannot be saved');
});

test('direct reel upload signs an owner-scoped ID and publishes verified media once', async (t) => {
  const published = [];
  const media = new Map();
  const removed = [];
  const store = {
    findByPublicId: async (id) => published.find((reel) => reel.publicId === id),
    add: async (reel) => published.push(reel),
  };
  const cloudinary = {
    config: () => ({ cloud_name: 'test', api_key: 'key', api_secret: 'test-secret' }),
    utils: { api_sign_request: () => 'signature' },
    url: () => 'https://example.com/thumb.jpg',
    api: { resource: async (id, options) => {
      assert.equal(options.media_metadata, true);
      if (!media.has(id)) throw { http_code: 404 };
      return media.get(id);
    } },
    uploader: { destroy: async (id) => { removed.push(id); media.delete(id); } },
  };
  const app = createApp({ cloudinary, store, verifyToken: async (uid) => ({ uid }) });
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const url = 'http://127.0.0.1:' + server.address().port + '/api/reels';
  function post(route, uploadId, uid = 'owner') {
    return fetch(url + route, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(uid && { Authorization: 'Bearer ' + uid }) },
      body: JSON.stringify({ uploadId, caption: 'Test reel' }),
    });
  }
  assert.equal((await post('/upload-ticket', 'local-1', '')).status, 401);
  assert.equal((await post('/upload-ticket', 'bad-id')).status, 400);
  const ticket = await (await post('/upload-ticket', 'local-1')).json();
  assert.equal(ticket.url, 'https://api.cloudinary.com/v1_1/test/video/upload');
  assert.equal(ticket.fields.overwrite, false);
  assert.equal(ticket.fields.signature, 'signature');
  assert.equal(ticket.fields.api_secret, undefined);
  const id = ticket.fields.public_id;
  assert.equal((await post('/complete-upload', 'local-1')).status, 409);
  media.set(id, {
    public_id: id, resource_type: 'video', format: 'mp4',
    secure_url: 'https://example.com/reel.mp4', width: 720, height: 1280,
    bytes: 8 * 1024 * 1024, media_metadata: { duration: 25 },
  });
  assert.equal((await post('/complete-upload', 'local-1', 'other-account')).status, 409);
  const response = await post('/complete-upload', 'local-1');
  assert.equal(response.status, 201);
  const reel = await response.json();
  assert.equal(reel.duration, 25);
  assert.equal(reel.ownerId, 'owner');
  assert.equal((await (await post('/complete-upload', 'local-1')).json()).id, reel.id);
  assert.equal((await (await post('/upload-ticket', 'local-1')).json()).reel.id, reel.id);
  assert.equal(published.length, 1);
  const longVideo = await (await post('/upload-ticket', 'local-2')).json();
  const longId = longVideo.fields.public_id;
  media.set(longId, { ...media.get(id), public_id: longId, duration: 61 });
  assert.equal((await post('/complete-upload', 'local-2')).status, 422);
  assert.deepEqual(removed, [longId]);
  assert.equal(published.length, 1);
});

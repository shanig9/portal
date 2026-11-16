const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createClient } = require('@supabase/supabase-js');
const { createReelsStore } = require('./reels-store');

const first = {
  id: '00000000-0000-4000-8000-000000000003', owner_uid: 'employee-1',
  author: 'Career Connect member', caption: 'Interview tips', type: 'video',
  url: 'https://example.com/reel.mp4', public_id: 'career-connect/reels/first',
  thumbnail_url: 'https://example.com/thumb.jpg', duration: 30,
  created_at: '2026-11-16T10:00:00+00:00',
};

function fixture(responses) {
  const requests = [];
  const client = createClient('https://example.com', 'test-server-key', {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { fetch: async (url, options) => {
      requests.push({ url: new URL(url), options });
      assert.ok(responses.length, 'unexpected database request');
      const response = responses.shift();
      return new Response(JSON.stringify(response.body), {
        status: response.status || 200, headers: { 'Content-Type': 'application/json' },
      });
    } },
  });
  return { store: createReelsStore(client), requests };
}

test('database feed uses bounded pages and a stable timestamp/id cursor', async () => {
  const second = { ...first, id: '00000000-0000-4000-8000-000000000002' };
  const { store, requests } = fixture([
    { body: [first, second] }, { body: first }, { body: [second] },
  ]);
  const page = await store.list({ limit: 1 });
  assert.equal(page.items[0].ownerId, 'employee-1');
  assert.equal(page.items[0].thumbnailUrl, first.thumbnail_url);
  assert.equal(page.nextCursor, first.id);
  assert.equal(requests[0].url.searchParams.get('limit'), '2');
  assert.equal(requests[0].url.searchParams.get('order'), 'created_at.desc,id.desc');
  const next = await store.list({ limit: 1, cursor: page.nextCursor });
  assert.equal(next.items[0].id, second.id);
  assert.equal(next.nextCursor, null);
  assert.match(requests[2].url.searchParams.get('or'), /created_at\.lt\./);
  assert.match(requests[2].url.searchParams.get('or'), /id\.lt\./);
});

test('database inserts reel metadata and propagates failure instead of saving locally', async () => {
  const { store, requests } = fixture([
    { body: null }, { status: 500, body: { message: 'database unavailable' } },
  ]);
  const reel = {
    id: first.id, ownerId: first.owner_uid, author: first.author, caption: first.caption,
    type: first.type, url: first.url, publicId: first.public_id,
    thumbnailUrl: first.thumbnail_url, duration: first.duration, createdAt: first.created_at,
  };
  await store.add(reel);
  assert.deepEqual(JSON.parse(requests[0].options.body), first);
  await assert.rejects(store.add(reel), { message: 'database unavailable' });
});

test('database feed rejects invalid or missing cursors', async () => {
  const { store, requests } = fixture([{ body: null }]);
  await assert.rejects(store.list({ limit: 10, cursor: 'invalid' }), { status: 400 });
  assert.equal(requests.length, 0);
  await assert.rejects(store.list({ limit: 10, cursor: first.id }), { status: 400 });
});

test('import lookup belongs to the store and returns only reel fields', async () => {
  const { store, requests } = fixture([{ body: first }, { body: null }]);
  const found = await store.findByPublicId(first.public_id);
  assert.equal(found.id, first.id);
  assert.equal(found.publicId, first.public_id);
  assert.equal(found.findByPublicId, undefined);
  assert.equal(requests[0].url.searchParams.get('public_id'), `eq.${first.public_id}`);
  assert.equal(await store.findByPublicId('missing'), null);
});

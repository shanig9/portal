const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { randomUUID } = require('node:crypto');
const { importReel, reelIdentity } = require('./import-reels');

async function fixture(t) {
  const filename = path.join(os.tmpdir(), `career-connect-reel-${randomUUID()}.mp4`);
  await fs.writeFile(filename, 'test clip');
  t.after(() => fs.unlink(filename));
  const rows = new Map();
  let uploads = 0, deleted = 0;
  const cloudinary = {
    url: () => 'https://example.com/thumb.jpg',
    uploader: {
      upload: async (_, options) => {
        uploads++;
        assert.equal(options.transformation[0].video_codec, 'h264');
        return {
          resource_type: 'video', format: 'mp4', width: 720, height: 1280,
          bytes: 100, duration: 59.92, public_id: options.public_id,
          secure_url: 'https://example.com/reel.mp4',
        };
      },
      destroy: async () => { deleted++; },
    },
  };
  const store = {
    findByPublicId: async (id) => rows.get(id) || null,
    add: async (reel) => { rows.set(reel.publicId, reel); },
  };
  return { filename, store, cloudinary, rows, counts: () => ({ uploads, deleted }) };
}

test('import publishes each source clip once with a stable identity', async (t) => {
  const setup = await fixture(t);
  const first = await importReel({ ...setup, caption: 'Career Connect reel' });
  assert.equal(first.skipped, false);
  assert.equal(first.reel.author, 'Career Connect');
  assert.equal(first.reel.ownerId, 'career-connect-library');
  assert.equal(first.reel.type, 'video');
  const retry = await importReel({ ...setup, caption: 'Another caption' });
  assert.equal(retry.skipped, true);
  assert.equal(retry.reel.id, first.reel.id);
  assert.deepEqual(setup.counts(), { uploads: 1, deleted: 0 });
  assert.equal(setup.rows.size, 1);
  assert.match(reelIdentity(Buffer.from('test clip')).id, /^[0-9a-f-]{36}$/);
});

test('import removes provider media if metadata cannot be saved', async (t) => {
  const setup = await fixture(t);
  setup.store.add = async () => { throw new Error('Database unavailable'); };
  await assert.rejects(importReel({ ...setup, caption: '' }), /Database unavailable/);
  assert.deepEqual(setup.counts(), { uploads: 1, deleted: 1 });
  assert.equal(setup.rows.size, 0);
});

test('import refuses an invalid provider video before publication', async (t) => {
  const setup = await fixture(t);
  const upload = setup.cloudinary.uploader.upload;
  setup.cloudinary.uploader.upload = async (...args) => ({ ...await upload(...args), duration: 61 });
  await assert.rejects(importReel({ ...setup, caption: '' }), /60 seconds/);
  assert.equal(setup.rows.size, 0);
  assert.deepEqual(setup.counts(), { uploads: 1, deleted: 1 });
});

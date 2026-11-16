const path = require('node:path');
const fs = require('node:fs/promises');
const { createHash } = require('node:crypto');
const { validateMedia, MAX_BYTES } = require('./reels');

function reelIdentity(bytes) {
  const hash = createHash('sha256').update(bytes).digest('hex');
  const id = Buffer.from(hash.slice(0, 32), 'hex');
  id[6] = (id[6] & 15) | 64;
  id[8] = (id[8] & 63) | 128;
  const hex = id.toString('hex');
  return {
    id: `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`,
    publicId: `career-connect/reels/library-${hash}`,
  };
}

// Trusted server administration: creates Career Connect library posts, not user uploads.
async function importReel({ filename, caption, cloudinary, store }) {
  const stat = await fs.stat(filename);
  if (!stat.isFile() || stat.size === 0 || stat.size > MAX_BYTES || path.extname(filename).toLowerCase() !== '.mp4') {
    throw new Error('Choose an MP4 video between 1 byte and 50 MB.');
  }
  const identity = reelIdentity(await fs.readFile(filename));
  const existing = await store.findByPublicId(identity.publicId);
  if (existing) return { reel: existing, skipped: true };

  const media = await cloudinary.uploader.upload(filename, {
    resource_type: 'video', public_id: identity.publicId, overwrite: false,
    format: 'mp4', timeout: 180000,
    // H.264/AAC is supported by Android. Leave room for audio/frame rounding.
    transformation: [{ end_offset: 59.9, video_codec: 'h264', audio_codec: 'aac' }],
  });
  const invalid = validateMedia(media);
  if (invalid) {
    await cloudinary.uploader.destroy(media.public_id, { resource_type: 'video' });
    throw new Error(invalid);
  }
  const reel = {
    id: identity.id, ownerId: 'career-connect-library', author: 'Career Connect',
    caption, type: 'video', url: media.secure_url, publicId: media.public_id,
    thumbnailUrl: cloudinary.url(media.public_id, {
      secure: true, resource_type: 'video', format: 'jpg',
      transformation: [{ width: 720, crop: 'limit' }],
    }),
    duration: media.duration, createdAt: new Date().toISOString(),
  };
  try { await store.add(reel); }
  catch (error) {
    // An overlapping import may have already committed this same clip.
    const saved = await store.findByPublicId(identity.publicId).catch(() => null);
    if (saved) return { reel: saved, skipped: true };
    await cloudinary.uploader.destroy(media.public_id, { resource_type: 'video' });
    throw error;
  }
  return { reel, skipped: false };
}

async function main(files) {
  require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
  if (!files.length) throw new Error('Usage: node import-reels.js "path/to/clip.mp4" [...]');
  for (const key of ['SUPABASE_URL', 'SUPABASE_SECRET_KEY', 'CLOUDINARY_CLOUD_NAME', 'CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET']) {
    if (!process.env[key]) throw new Error(`Missing ${key} in server/.env.`);
  }
  const { createClient } = require('@supabase/supabase-js');
  const { v2: cloudinary } = require('cloudinary');
  const { createReelsStore } = require('./reels-store');
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  const preflight = await client.from('career_reels').select('id').limit(1);
  if (preflight.error) {
    throw new Error(`Reels table is not ready (${preflight.error.code || 'connection error'}). Run supabase/schemas/reels.sql before importing. No media uploaded.`);
  }
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
  const store = createReelsStore(client);
  let failed = false;
  for (const [index, filename] of files.entries()) {
    try {
      const { reel, skipped } = await importReel({
        filename, caption: `Career Connect reel ${index + 1}`, cloudinary, store,
      });
      console.log(`${skipped ? 'Already published' : 'Published'}: ${path.basename(filename)} (${reel.duration.toFixed(2)} seconds)`);
    } catch (error) {
      failed = true;
      // Provider errors may contain signed upload details. Keep CLI output minimal.
      console.error(`Failed: ${path.basename(filename)} (${error.http_code || error.code || 'upload/database error'})`);
    }
  }
  if (failed) process.exitCode = 1;
}

if (require.main === module) {
  main(process.argv.slice(2)).catch((error) => { console.error(error.message); process.exitCode = 1; });
}

module.exports = { importReel, reelIdentity };

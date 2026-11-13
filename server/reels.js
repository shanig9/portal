const express = require('express');
const multer = require('multer');
const cors = require('cors');
const { rateLimit } = require('express-rate-limit');
const { randomUUID } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');

const MAX_BYTES = 50 * 1024 * 1024;
const formats = { image: ['jpg', 'jpeg', 'png', 'webp'], video: ['mp4', 'mov', 'webm'] };

function validateMedia(media) {
  if (!formats[media.resource_type]?.includes(media.format) || !media.width || !media.height) {
    return 'Choose a JPEG, PNG, WebP image or MP4, MOV, WebM video.';
  }
  if (media.bytes > MAX_BYTES) return 'Files must be 50 MB or smaller.';
  if (media.resource_type === 'video' &&
      (!Number.isFinite(media.duration) || media.duration <= 0 || media.duration > 60)) {
    return 'Videos must be no longer than 60 seconds.';
  }
  return null;
}

function createStore(filename) {
  let queue = Promise.resolve();
  async function read() {
    try { return JSON.parse(await fs.readFile(filename, 'utf8')); }
    catch (error) { if (error.code === 'ENOENT') return []; throw error; }
  }
  return {
    read,
    add(reel) {
      const operation = queue.then(async () => {
        const reels = await read();
        reels.unshift(reel);
        await fs.mkdir(path.dirname(filename), { recursive: true });
        const temporary = `${filename}.tmp`;
        await fs.writeFile(temporary, JSON.stringify(reels));
        await fs.rename(temporary, filename);
      });
      queue = operation.catch(() => {});
      return operation;
    },
  };
}

function createApp({ cloudinary, verifyToken, store, origins = [] }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: origins }));
  app.get('/health', (_, res) => res.json({ app: 'Career Connect', status: 'ok' }));
  app.get('/api/reels', async (req, res) => {
    const limit = Math.min(30, Math.max(1, Number(req.query.limit) || 10));
    const reels = await store.read();
    const cursor = req.query.cursor;
    const start = cursor ? reels.findIndex((reel) => reel.id === cursor) + 1 : 0;
    const items = reels.slice(start, start + limit);
    res.json({ items, nextCursor: start + limit < reels.length ? items.at(-1).id : null });
  });
  const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: MAX_BYTES, files: 1, fields: 1, fieldSize: 2000 },
    fileFilter: (_, file, done) => {
      if (!/^(image\/(jpeg|png|webp)|video\/(mp4|quicktime|webm))$/.test(file.mimetype)) {
        return done(Object.assign(new Error('Unsupported image or video type.'), { status: 400 }));
      }
      done(null, true);
    },
  });
  app.post('/api/reels', rateLimit({ windowMs: 15 * 60 * 1000, limit: 10 }), async (req, res, next) => {
    const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
    if (!token) return res.status(401).json({ error: 'Sign in to upload a reel.' });
    try { req.account = await verifyToken(token); }
    catch { return res.status(401).json({ error: 'Your session expired. Sign in again.' }); }
    next();
  }, upload.single('file'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'Choose an image or video.' });
    const caption = (req.body.caption || '').trim();
    if (caption.length > 500) return res.status(400).json({ error: 'Captions must be 500 characters or fewer.' });
    const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
    let media;
    try {
      media = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({
          resource_type: type, folder: 'career-connect/reels', public_id: randomUUID(),
          allowed_formats: formats[type],
        }, (error, result) => error ? reject(error) : resolve(result)).end(req.file.buffer);
      });
    } catch {
      return res.status(502).json({ error: 'Media upload failed. Please try again.' });
    }
    async function cleanup() {
      await cloudinary.uploader.destroy(media.public_id, { resource_type: media.resource_type });
    }
    const invalid = validateMedia(media);
    if (invalid) {
      await cleanup();
      return res.status(400).json({ error: invalid });
    }
    const reel = {
      id: randomUUID(), ownerId: req.account.uid,
      author: req.account.name || 'Career Connect member', caption,
      type: media.resource_type, url: media.secure_url, publicId: media.public_id,
      thumbnailUrl: cloudinary.url(media.public_id, {
        secure: true, resource_type: media.resource_type, format: 'jpg',
        transformation: [{ width: 720, crop: 'limit' }],
      }),
      duration: media.duration || null, createdAt: new Date().toISOString(),
    };
    try { await store.add(reel); }
    catch (error) { await cleanup(); throw error; }
    res.status(201).json(reel);
  });
  app.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
      return res.status(400).json({ error: error.code === 'LIMIT_FILE_SIZE'
        ? 'Files must be 50 MB or smaller.' : 'Upload one file and a caption only.' });
    }
    res.status(error.status || 500).json({ error: error.status ? error.message : 'Unable to complete the request. Please try again.' });
  });
  return app;
}

module.exports = { createApp, createStore, validateMedia, MAX_BYTES };

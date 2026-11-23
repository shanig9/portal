const express = require('express');
const multer = require('multer');
const cors = require('cors');
const { rateLimit } = require('express-rate-limit');
const { createHash, randomUUID } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { authenticate } = require('./authentication');
const { cloudinaryNetworkOptions } = require('./cloudinary-network');

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
    async findByPublicId(publicId) {
      return (await read()).find((reel) => reel.publicId === publicId) ?? null;
    },
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

function createApp({ cloudinary, verifyToken, store, origins = [], recordsRepository, app = express() }) {
  app.disable('x-powered-by');
  app.use(cors({ origin: origins }));
  app.get('/', (_, res) => res.json({
    app: 'Career Connect',
    status: 'ok',
    message: 'Career Connect API is running.',
    health: '/health',
    reels: '/api/reels',
  }));
  app.use('/api', require('./records').recordsRouter({ verifyToken, repository: recordsRepository }));
  app.get('/health', (_, res) => res.json({ app: 'Career Connect', status: 'ok' }));
  app.get('/api/reels', async (req, res) => {
    const limit = Math.min(30, Math.max(1, Math.floor(Number(req.query.limit) || 10)));
    if (store.list) return res.json(await store.list({ limit, cursor: req.query.cursor }));
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
  async function requireAccount(req, res, next) {
    const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
    if (!token) return res.status(401).json({ error: 'Sign in to upload a reel.' });
    try { req.account = await authenticate(verifyToken, token); }
    catch (error) { return res.status(error.status).json({ error: error.message }); }
    next();
  }
  function reelRecord(media, account, caption) {
    return {
      id: randomUUID(), ownerId: account.uid,
      author: account.name || 'Career Connect member', caption,
      type: media.resource_type, url: media.secure_url, publicId: media.public_id,
      thumbnailUrl: cloudinary.url(media.public_id, {
        secure: true, resource_type: media.resource_type, format: 'jpg',
        transformation: [{ width: 720, crop: 'limit' }],
      }),
      duration: media.duration || null, createdAt: new Date().toISOString(),
    };
  }
  function destroyMedia(media) {
    return cloudinary.uploader.destroy(media.public_id, {
      resource_type: media.resource_type, ...cloudinaryNetworkOptions(),
    });
  }
  function uploadPublicId(req) {
    const id = req.body?.uploadId;
    if (typeof id !== 'string' || !/^local-\d{1,20}$/.test(id)) {
      throw Object.assign(new Error('Invalid reel upload ID.'), { status: 400 });
    }
    const key = createHash('sha256').update(JSON.stringify([req.account.uid, id])).digest('hex');
    return 'career-connect/reels/' + key;
  }
  const json = express.json({ limit: '4kb' });
  app.post('/api/reels/upload-ticket', rateLimit({
    windowMs: 15 * 60 * 1000, limit: 20, message: { error: 'Too many reel uploads. Try again later.' },
  }), requireAccount, json, async (req, res) => {
    res.set('Cache-Control', 'no-store');
    const publicId = uploadPublicId(req);
    const reel = await store.findByPublicId(publicId);
    if (reel) return res.json({ reel });
    const config = cloudinary.config();
    const params = {
      timestamp: Math.floor(Date.now() / 1000),
      public_id: publicId,
      allowed_formats: formats.video.join(','),
      overwrite: false,
    };
    res.json({
      url: 'https://api.cloudinary.com/v1_1/' + encodeURIComponent(config.cloud_name) + '/video/upload',
      fields: {
        ...params, api_key: config.api_key,
        signature: cloudinary.utils.api_sign_request(params, config.api_secret),
      },
    });
  });
  app.post('/api/reels/complete-upload', rateLimit({
    windowMs: 15 * 60 * 1000, limit: 30, message: { error: 'Too many reel uploads. Try again later.' },
  }), requireAccount, json, async (req, res) => {
    const publicId = uploadPublicId(req);
    const caption = req.body?.caption ?? '';
    if (typeof caption !== 'string' || caption.length > 500) {
      return res.status(400).json({ error: 'Captions must be 500 characters or fewer.' });
    }
    const published = await store.findByPublicId(publicId);
    if (published) return res.json(published);
    let media;
    try {
      media = await cloudinary.api.resource(publicId, {
        resource_type: 'video', type: 'upload', media_metadata: true,
        ...cloudinaryNetworkOptions(),
      });
    } catch (error) {
      const status = error.http_code ?? error.error?.http_code;
      return res.status(status === 404 ? 409 : 502).json({
        error: status === 404 ? 'Cloudinary is still processing this video. Try again shortly.'
          : 'Cloudinary could not verify the video. Try again shortly.',
      });
    }
    media.duration = Number(media.duration ?? media.media_metadata?.duration);
    const invalid = validateMedia(media);
    if (invalid) {
      await destroyMedia(media);
      return res.status(422).json({ error: invalid });
    }
    const reel = reelRecord(media, req.account, caption.trim());
    try {
      await store.add(reel);
    } catch (error) {
      const existing = await store.findByPublicId(publicId);
      if (existing) return res.json(existing);
      throw error;
    }
    res.status(201).json(reel);
  });
  app.post('/api/reels', rateLimit({ windowMs: 15 * 60 * 1000, limit: 10 }), requireAccount, upload.single('file'), async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'Choose an image or video.' });
    const caption = (req.body.caption || '').trim();
    if (caption.length > 500) return res.status(400).json({ error: 'Captions must be 500 characters or fewer.' });
    const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
    let media;
    try {
      media = await new Promise((resolve, reject) => {
        cloudinary.uploader.upload_stream({
          ...cloudinaryNetworkOptions(),
          resource_type: type, folder: 'career-connect/reels', public_id: randomUUID(),
          allowed_formats: formats[type],
        }, (error, result) => error ? reject(error) : resolve(result)).end(req.file.buffer);
      });
    } catch {
      return res.status(502).json({ error: 'Media upload failed. Please try again.' });
    }
    const invalid = validateMedia(media);
    if (invalid) {
      await destroyMedia(media);
      return res.status(400).json({ error: invalid });
    }
    const reel = reelRecord(media, req.account, caption);
    try { await store.add(reel); }
    catch (error) { await destroyMedia(media); throw error; }
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

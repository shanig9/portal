const express = require('express');
const multer = require('multer');
const { rateLimit } = require('express-rate-limit');
const { randomUUID } = require('node:crypto');

const BUCKET = 'career-documents';
const DOCUMENT_FIELDS = 'id,filename,mime_type,size_bytes,created_at';
const APPLICATION_FIELDS = 'id,job_key,job_title,company,location,document_id,status,created_at';
function badRequest(message, status = 400) { return Object.assign(new Error(message), { status }); }
function check(result) { if (result.error) throw result.error; return result.data; }

function createRecordsRepository(client) {
  return {
    async documents(uid) {
      return check(await client.from('career_documents').select(DOCUMENT_FIELDS)
        .eq('owner_uid', uid).order('created_at', { ascending: false }).limit(100));
    },
    async upload(uid, file) {
      const id = randomUUID();
      const storagePath = `${encodeURIComponent(uid)}/${id}.pdf`;
      check(await client.storage.from(BUCKET).upload(storagePath, file.buffer,
        { contentType: 'application/pdf', upsert: false }));
      try {
        return check(await client.from('career_documents').insert({
          id, owner_uid: uid, filename: file.originalname.replace(/[\\/\x00-\x1f]/g, '_').slice(0, 200),
          storage_path: storagePath, mime_type: 'application/pdf', size_bytes: file.size,
        }).select(DOCUMENT_FIELDS).single());
      } catch (error) {
        const cleanup = await client.storage.from(BUCKET).remove([storagePath]);
        if (cleanup.error) console.error('Document cleanup failed; remove orphan by ID:', id);
        throw error;
      }
    },
    async download(uid, id) {
      const document = check(await client.from('career_documents').select('storage_path')
        .eq('owner_uid', uid).eq('id', id).maybeSingle());
      if (!document) throw badRequest('Document not found.', 404);
      return check(await client.storage.from(BUCKET).createSignedUrl(document.storage_path, 60));
    },
    async applications(uid) {
      return check(await client.from('career_applications').select(APPLICATION_FIELDS)
        .eq('applicant_uid', uid).order('created_at', { ascending: false }).limit(100));
    },
    async apply(uid, input) {
      const document = check(await client.from('career_documents').select('id')
        .eq('owner_uid', uid).eq('id', input.documentId).maybeSingle());
      if (!document) throw badRequest('Select one of your uploaded documents.');
      // Current jobs are local previews; store a snapshot until persisted HR jobs supply canonical IDs.
      const result = await client.from('career_applications').insert({
        applicant_uid: uid, job_key: input.jobKey, job_title: input.jobTitle,
        company: input.company, location: input.location, document_id: document.id,
      }).select(APPLICATION_FIELDS).single();
      if (result.error?.code === '23505') throw badRequest('You already applied for this job.', 409);
      return check(result);
    },
  };
}

function recordsRouter({ verifyToken, repository }) {
  const router = express.Router();
  router.use((req, res, next) => /^\/(documents|applications)(\/|$)/.test(req.path) ? next() : next('router'));
  router.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 100 }));
  router.use(async (req, res, next) => {
    const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
    if (!token) return res.status(401).json({ error: 'Sign in to access your documents and applications.' });
    try { req.account = await verifyToken(token); }
    catch { return res.status(401).json({ error: 'Your session expired. Sign in again.' }); }
    if (!repository) return res.status(503).json({ error: 'Document and application storage is not configured yet.' });
    next();
  });
  const upload = multer({ storage: multer.memoryStorage(),
    limits: { files: 1, fields: 0, fileSize: 10 * 1024 * 1024 },
  });
  router.get('/documents', async (req, res) => res.json({ items: await repository.documents(req.account.uid) }));
  router.post('/documents', upload.single('file'), async (req, res) => {
    const file = req.file;
    if (!file || !/\.pdf$/i.test(file.originalname) || file.mimetype !== 'application/pdf' ||
        file.buffer.subarray(0, 5).toString() !== '%PDF-') {
      throw badRequest('Choose a PDF document, up to 10 MB.');
    }
    res.status(201).json(await repository.upload(req.account.uid, file));
  });
  router.get('/documents/:id/download', async (req, res) => {
    if (!isUuid(req.params.id)) throw badRequest('Invalid document ID.');
    res.json(await repository.download(req.account.uid, req.params.id));
  });
  router.get('/applications', async (req, res) => res.json({ items: await repository.applications(req.account.uid) }));
  router.post('/applications', express.json({ limit: '8kb' }), async (req, res) => {
    const input = req.body;
    if (!input || !isUuid(input.documentId) ||
        !['jobKey', 'jobTitle', 'company', 'location'].every((key) =>
          typeof input[key] === 'string' && input[key].trim().length > 0 && input[key].length <= 200)) {
      throw badRequest('A job and an uploaded resume are required.');
    }
    res.status(201).json(await repository.apply(req.account.uid, input));
  });
  router.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
      return res.status(400).json({ error: 'Upload one PDF file, up to 10 MB.' });
    }
    res.status(error.status || 500).json({ error: error.status ? error.message : 'Storage request failed. Please try again.' });
  });
  return router;
}
function isUuid(value) { return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value); }
module.exports = { recordsRouter, createRecordsRepository };

const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { recordsRouter, createRecordsRepository } = require('./records');

test('records API verifies identity, validates PDFs and uses verified owner for every operation', async (t) => {
  const calls = [];
  const repository = {
    documents: async (uid) => { calls.push(['documents', uid]); return []; },
    applications: async (uid) => { calls.push(['applications', uid]); return []; },
    upload: async (uid, file) => { calls.push(['upload', uid]); return { id: 'document', filename: file.originalname }; },
    apply: async (uid) => { calls.push(['apply', uid]); return { id: 'application' }; },
    download: async (uid) => { calls.push(['download', uid]); return { signedUrl: 'https://example.com/private' }; },
  };
  const app = express();
  app.use('/api', recordsRouter({ repository, verifyToken: async (token) => {
    if (token !== 'member') throw Error('bad token');
    return { uid: 'verified-owner' };
  } }));
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const url = `http://127.0.0.1:${server.address().port}/api`;
  assert.equal((await fetch(`${url}/documents`)).status, 401);
  const headers = { Authorization: 'Bearer member' };
  assert.equal((await fetch(`${url}/documents`, { headers })).status, 200);
  assert.equal((await fetch(`${url}/applications`, { headers })).status, 200);
  async function upload(content, name = 'resume.pdf') {
    const form = new FormData();
    form.append('file', new Blob([content], { type: 'application/pdf' }), name);
    return fetch(`${url}/documents`, { method: 'POST', headers, body: form });
  }
  assert.equal((await upload('not a pdf')).status, 400);
  assert.equal((await upload('%PDF-1.7 test')).status, 201);
  assert.equal((await fetch(`${url}/documents/not-uuid/download`, { headers })).status, 400);
  assert.equal((await fetch(`${url}/documents/00000000-0000-4000-8000-000000000001/download`, { headers })).status, 200);
  assert.equal((await fetch(`${url}/applications`, { method: 'POST', headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ jobKey: 'career-connect::developer', jobTitle: 'Developer', company: 'Career Connect', location: 'Pune',
      documentId: '00000000-0000-4000-8000-000000000001', applicant_uid: 'attacker' }) })).status, 201);
  assert.ok(calls.every((call) => call[1] === 'verified-owner'));
  assert.equal((await fetch(`${url}/reels`)).status, 404); // Records auth must not intercept other APIs.
});

function fakeQuery(result, calls) {
  const builder = { then: (resolve, reject) => Promise.resolve(result).then(resolve, reject) };
  for (const name of ['select', 'eq', 'order', 'limit', 'insert', 'single', 'maybeSingle']) {
    builder[name] = (...args) => { calls.push([name, ...args]); return builder; };
  }
  return builder;
}

test('repository prevents cross-user document download and application attachment', async () => {
  const calls = [];
  const client = { from: (table) => { calls.push(['from', table]); return fakeQuery({ data: null }, calls); },
    storage: { from: () => { throw Error('Storage must not be reached'); } } };
  const repository = createRecordsRepository(client);
  await assert.rejects(repository.download('owner-a', 'someone-elses-document'), { status: 404 });
  await assert.rejects(repository.apply('owner-a', { documentId: 'someone-elses-document' }), { status: 400 });
  assert.equal(calls.filter((call) => call[0] === 'eq' && call[1] === 'owner_uid' && call[2] === 'owner-a').length, 2);
  assert.ok(!calls.some((call) => call[0] === 'insert'));
});

test('failed metadata insert cleans up uploaded document', async () => {
  let removed = false;
  const client = { from: () => fakeQuery({ error: new Error('database unavailable') }, []),
    storage: { from: () => ({ upload: async () => ({ data: {} }),
      remove: async (paths) => { removed = paths.length === 1; return {}; } }) } };
  await assert.rejects(createRecordsRepository(client).upload('owner', {
    originalname: 'resume.pdf', buffer: Buffer.from('%PDF-'), size: 5,
  }), /database unavailable/);
  assert.equal(removed, true);
});

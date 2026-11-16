const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createChatPublisher, createJobResolver } = require('./chat');
const { createRecordsRepository } = require('./records');

const application = {
  id: 'application-1', applicant_uid: 'employee-1', job_key: 'published-job-1',
  job_title: 'Developer', company: 'Career Connect', created_at: '2026-11-15T10:00:00Z',
};

function database() {
  const rooms = new Map();
  const jobs = new Map([[application.job_key, {
    ownerUid: 'hr-1', title: 'Developer', company: 'Career Connect', location: 'Pune',
    active: true, draft: false, live: 0, expiry: Date.now() + 1000000,
  }]]);
  const snapshot = (ref) => ({ exists: (ref.collection === 'career_chats' ? rooms : jobs).has(ref.id),
    data: () => (ref.collection === 'career_chats' ? rooms : jobs).get(ref.id) });
  return {
    rooms, jobs,
    collection: (collection) => ({ doc: (id) => {
      const ref = { collection, id }; return { ...ref, get: async () => snapshot(ref) };
    } }),
    runTransaction: async (operation) => operation({
      get: async (ref) => snapshot(ref),
      create: (ref, data) => { assert.ok(!rooms.has(ref.id)); rooms.set(ref.id, data); },
    }),
  };
}

test('application creates one chat for the trusted HR owner; retries preserve participants', async () => {
  const db = database();
  const publish = createChatPublisher(db);
  assert.deepEqual(await publish(application), { chatId: application.id });
  assert.deepEqual(db.rooms.get(application.id).participantIds, ['employee-1', 'hr-1']);
  db.jobs.get(application.job_key).ownerUid = 'hr-2';
  await createChatPublisher(db)(application);
  assert.equal(db.rooms.size, 1);
  assert.equal(db.rooms.get(application.id).hrUid, 'hr-1');
});

test('unassigned jobs and self-chat never provision a conversation', async () => {
  const db = database();
  await assert.rejects(createChatPublisher(db)({ ...application, job_key: 'missing' }), { status: 409 });
  db.jobs.get(application.job_key).ownerUid = 'employee-1';
  await assert.rejects(createChatPublisher(db)(application), { status: 409 });
  assert.equal(db.rooms.size, 0);
});

test('application snapshots come from the published job, and closed, future and self-owned jobs reject', async () => {
  const db = database();
  const resolve = createJobResolver(db);
  assert.deepEqual(await resolve(application.job_key, 'employee-1'), {
    jobKey: application.job_key, jobTitle: 'Developer', company: 'Career Connect', location: 'Pune',
  });
  await assert.rejects(resolve('fake::job', 'employee-1'), { status: 400 });
  await assert.rejects(resolve(application.job_key, 'hr-1'), { status: 409 });
  db.jobs.get(application.job_key).draft = true;
  await assert.rejects(resolve(application.job_key, 'employee-1'), { status: 409 });
  db.jobs.get(application.job_key).draft = false;
  db.jobs.get(application.job_key).live = Date.now() + 1000000;
  await assert.rejects(resolve(application.job_key, 'employee-1'), { status: 409 });
});

test('another employee cannot provision chat for someone else\'s application', async () => {
  let published = false;
  const filters = [];
  const query = { select() { return this; }, eq(key, value) { filters.push([key, value]); return this; },
    maybeSingle: async () => ({ data: null }) };
  const repository = createRecordsRepository({ from: () => query }, async () => { published = true; });
  await assert.rejects(repository.chat('employee-2', application.id), { status: 404 });
  assert.ok(filters.some(([key, value]) => key === 'applicant_uid' && value === 'employee-2'));
  assert.equal(published, false);
});

test('stalled job verification fails promptly without accepting an unverified opening', async () => {
  const db = { collection: () => ({ doc: () => ({ get: () => new Promise(() => {}) }) }) };
  await assert.rejects(createJobResolver(db, { timeoutMs: 10 })('published-job-1', 'employee-1'), { status: 503 });
});

test('application success does not wait for stalled chat creation', async () => {
  const saved = { ...application, document_id: 'resume-1' };
  const query = {
    select() { return this; }, eq() { return this; }, insert() { return this; },
    maybeSingle: async () => ({ data: { id: 'resume-1' } }),
    single: async () => ({ data: saved }),
  };
  const repository = createRecordsRepository({ from: (table) => table === 'career_documents' ? query : {
    ...query, maybeSingle: async () => ({ data: null }),
  } }, () => new Promise(() => {}));
  const result = await repository.apply('employee-1', { documentId: 'resume-1' });
  assert.equal(result.id, application.id);
});

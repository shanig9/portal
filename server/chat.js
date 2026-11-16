// Resolve recipients from persisted job ownership, never client-supplied UIDs.
function createChatPublisher(db) {
  return async function publish(application) {
    const room = db.collection('career_chats').doc(application.id);
    await db.runTransaction(async (transaction) => {
      const existing = await transaction.get(room);
      // Preserve existing participants and history on retries.
      if (existing.exists) return;
      const job = await transaction.get(db.collection('career_jobs').doc(application.job_key));
      if (!job.exists || typeof job.data().ownerUid !== 'string') {
        throw Object.assign(new Error('This application has no published recruiter-owned job. Apply to a published opening to start chat.'), { status: 409 });
      }
      const hrUid = job.data().ownerUid;
      if (hrUid === application.applicant_uid) {
        throw Object.assign(new Error('You cannot apply to your own job.'), { status: 409 });
      }
      transaction.create(room, {
        participantIds: [application.applicant_uid, hrUid],
        employeeUid: application.applicant_uid,
        hrUid,
        applicationId: application.id,
        jobTitle: application.job_title,
        company: application.company,
        createdAt: new Date(application.created_at),
      });
    });
    return { chatId: application.id };
  };
}

function createJobResolver(db, { timeoutMs = 15000 } = {}) {
  return async function resolveJob(id, uid) {
    if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(id)) {
      throw Object.assign(new Error('Choose a published job.'), { status: 400 });
    }
    let deadline;
    let snapshot;
    try {
      snapshot = await Promise.race([
        db.collection('career_jobs').doc(id).get(),
        new Promise((_, reject) => {
          deadline = setTimeout(() => reject(Object.assign(
            new Error('Job verification is temporarily unavailable. Please try again.'),
            { status: 503 })), timeoutMs);
        }),
      ]);
    } catch (error) {
      if (error.status) throw error;
      console.error('Job verification failed:', error.code || error.name);
      throw Object.assign(new Error('Unable to verify this opening. Please try again shortly.'), { status: 503 });
    } finally {
      clearTimeout(deadline);
    }
    const job = snapshot.data();
    if (!job || !job.active || job.draft || job.expiry < Date.now() || job.live > Date.now()) {
      throw Object.assign(new Error('This opening is no longer accepting applications.'), { status: 409 });
    }
    if (job.ownerUid === uid) throw Object.assign(new Error('You cannot apply to your own job.'), { status: 409 });
    return { jobKey: id, jobTitle: job.title, company: job.company, location: job.location };
  };
}
module.exports = { createChatPublisher, createJobResolver };

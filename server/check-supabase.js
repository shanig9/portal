const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { createClient } = require('@supabase/supabase-js');
(async () => {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SECRET_KEY) {
    throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY in server/.env first.');
  }
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  for (const table of ['career_documents', 'career_applications']) {
    const result = await client.from(table).select('id')
      .eq('id', '00000000-0000-0000-0000-000000000000').limit(1);
    if (result.error) throw new Error(`Cannot query ${table}: ${result.error.message}`);
    console.log(`${table}: connected`);
  }
  let { data, error } = await client.storage.getBucket('career-documents');
  if (error?.message === 'Bucket not found' && process.argv.includes('--create-missing-bucket')) {
    const created = await client.storage.createBucket('career-documents', {
      public: false, fileSizeLimit: 10 * 1024 * 1024,
      allowedMimeTypes: ['application/pdf'],
    });
    if (created.error) throw new Error(created.error.message);
    console.log('career-documents: created private PDF bucket (10 MB limit)');
    ({ data, error } = await client.storage.getBucket('career-documents'));
  }
  if (error) throw new Error(error.message);
  if (data.public) throw new Error('career-documents bucket must be private.');
  console.log('career-documents: private bucket connected');
})().catch((error) => { console.error(error.message); process.exitCode = 1; });

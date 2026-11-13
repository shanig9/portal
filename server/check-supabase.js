require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');
(async () => {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SECRET_KEY) {
    throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY in server/.env first.');
  }
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  for (const table of ['career_documents', 'career_applications']) {
    const result = await client.from(table).select('id', { count: 'exact', head: true }).limit(1);
    if (result.error) throw new Error(`Cannot query ${table}: ${result.error.message}`);
    console.log(`${table}: connected`);
  }
  const { data, error } = await client.storage.getBucket('career-documents');
  if (error) throw new Error(error.message);
  if (data.public) throw new Error('career-documents bucket must be private.');
  console.log('career-documents: private bucket connected');
})().catch((error) => { console.error(error.message); process.exitCode = 1; });

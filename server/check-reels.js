const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const { createClient } = require('@supabase/supabase-js');

async function main() {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SECRET_KEY) {
    throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY in server/.env.');
  }
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SECRET_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } });
  const { error } = await client.from('career_reels').select('id').limit(1);
  if (error) throw new Error(`Reels database check failed (${error.code || 'connection error'}). Apply supabase/schemas/reels.sql and verify server credentials.`);
  console.log('Career Connect reels database is reachable.');
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });

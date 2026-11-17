// src/config/supabase.js
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in environment variables');
}

// Keep database/admin operations on a dedicated service-role client. Auth
// sign-in mutates a Supabase client's in-memory session even when
// persistSession is false; reusing that client for table queries would send
// the signed-in user's JWT instead of the service-role key.
const createServiceClient = () => createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const supabase = createServiceClient();
// Auth operations get their own client so they cannot replace the service
// credentials used by database queries in controllers and middleware.
supabase.authClient = createServiceClient();

module.exports = supabase;

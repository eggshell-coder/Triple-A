// src/middleware/adminAuth.js
// Guards admin-only routes by verifying the Supabase JWT and confirming
// the caller has a matching row in the `admins` table.

const supabase = require('../config/supabase');

const requireAdmin = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];

    // Verify the JWT via Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ success: false, message: 'Invalid or expired token' });
    }

    // Confirm this user is in the admins table
    const { data: adminProfile, error: profileError } = await supabase
      .from('admins')
      .select('id, full_name, email, role')
      .eq('email', user.email)
      .single();

    if (profileError || !adminProfile) {
      return res.status(403).json({ success: false, message: 'Access denied – not an admin account' });
    }

    req.user  = user;
    req.admin = adminProfile;
    next();
  } catch (err) {
    next(err);
  }
};

module.exports = { requireAdmin };

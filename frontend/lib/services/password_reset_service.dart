// lib/services/password_reset_service.dart
//
// Password-reset flow backed by Supabase Auth.
//
// Flow:
//   1. sendResetEmail()      → Supabase emails a link to the account owner
//   2. user clicks the link  → browser lands on our app with a recovery
//                              session in the URL
//   3. updatePassword()      → swaps the password on that session
//
// Why Supabase handles step 1 instead of our backend:
// the reset link must be signed by Supabase and expire on their schedule.
// Minting our own token would mean storing password-reset state ourselves,
// which is strictly more work and strictly more dangerous.

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_redirects.dart';

/// Who is resetting. Used for the success copy and the redirect path.
enum ResetAudience {
  admin('Admin', '/admin/login'),
  customer('Customer', '/login');

  const ResetAudience(this.label, this.loginPath);

  final String label;
  final String loginPath;
}

class PasswordResetService {
  const PasswordResetService();

  SupabaseClient get _auth => Supabase.instance.client;

  /// The URL Supabase sends the user back to after clicking the email link.
  ///
  /// This is the BARE origin plus a flow marker — never a hash route. See
  /// AuthRedirects for why: with a hash-router app, anything Supabase
  /// appends lands in the fragment and `?code=` becomes unreachable.
  ///
  /// Must be allow-listed under Authentication → URL Configuration.
  static String get redirectTo => AuthRedirects.resetPassword;

  /// Emails a reset link. Returns null on success.
  ///
  /// Throws [AuthException] with a human-readable message on failure.
  Future<void> sendResetEmail(String email) async {
    await _auth.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// True when the app was opened with a valid recovery session — i.e. the
  /// user actually clicked the emailed link.
  ///
  /// Supabase delivers the link's tokens in the URL (implicit flow puts them
  /// in the fragment, PKCE in `?code=`). When the app boots on that URL there
  /// may be no session yet, so we exchange the URL for one first.
  Future<bool> hasRecoverySession() async {
    var session = _auth.auth.currentSession;

    if (session == null) {
      try {
        // Read the URL captured before GoRouter cleared the fragment, not
        // Uri.base — by the time this runs the address bar no longer has it.
        final res = await _auth.auth.getSessionFromUrl(AuthRedirects.callbackUri());
        session = res.session;
      } catch (_) {
        return false;
      }
    }

    // Past this point a session exists: either it was already set, or
    // getSessionFromUrl just created one.
    // Confirm it is still live server-side rather than merely cached.
    try {
      await _auth.auth.getUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Applies the new password to the current recovery session.
  Future<void> updatePassword(String newPassword) async {
    await _auth.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Signs out the recovery session so the recovery link cannot be replayed.
  Future<void> endSession() async {
    try {
      await _auth.auth.signOut();
    } catch (_) {
      // Already signed out — nothing to clean up.
    }
  }
}

const passwordResetService = PasswordResetService();

/// Password rules mirrored from the backend validator, so users get told
/// immediately instead of after a round trip.
///
/// ⚠️ These MUST match three places or signup breaks in confusing ways:
///   1. this file
///   2. backend/src/routes/auth.routes.js (the signup validator)
///   3. Supabase → Authentication → Sign In / Providers → Email
///      → "Minimum password length"
///
/// Supabase is the authority: if its minimum is higher than ours, users get
/// rejected server-side after passing our form.
const kMinPasswordLength = 6;

const passwordRules = <String>[
  'At least $kMinPasswordLength characters',
];

String? validateNewPassword(String value) {
  if (value.isEmpty) return 'Password is required';
  if (value.length < kMinPasswordLength) return passwordRules[0];
  return null;
}

String? validateConfirmation(String password, String confirm) {
  if (confirm.isEmpty) return 'Please confirm your new password';
  if (password != confirm) return 'Passwords do not match';
  return null;
}
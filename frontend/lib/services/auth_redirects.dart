// lib/services/auth_redirects.dart
//
// Where Supabase sends the user back to after clicking an emailed link.
//
// WHY THIS FILE EXISTS — the hash-router trap
// -------------------------------------------
// This app uses go_router's HASH strategy, so its URLs look like
// `https://app/#/cart`. Supabase, however, delivers its token by APPENDING a
// query string to whatever redirect URL you give it:
//
//   redirectTo = https://app/#/reset-password   (what we used to do)
//   Supabase appends -> https://app/#/reset-password?code=ABC
//
// Everything after the first `#` is the FRAGMENT, not the query. So
// `Uri.base.queryParameters` is empty, `?code=ABC` is buried inside the
// fragment, and `getSessionFromUrl()` fails with
// "No code detected in query parameters".
//
// The fix is to never put a path in the redirect URL. Send the user to the
// bare origin with a marker telling us which flow they came from:
//
//   redirectTo = https://app/?flow=reset
//   Supabase appends -> https://app/?flow=reset&code=ABC
//                        ^^^^^^^^^^^^^^^^^^ query params parse correctly
//
// The app boots at "/" and [detect] reroutes to the right screen. Note that
// go_router navigating to `/reset-password` afterwards only rewrites the
// fragment, so `Uri.base.queryParameters` (and therefore the `code`) survives
// until `getSessionFromUrl` consumes it.

class AuthRedirects {
  const AuthRedirects._();

  static const String flowParam = 'flow';

  /// Which emailed flow the user is completing.
  static const String flowReset = 'reset';
  static const String flowSignup = 'signup';

  /// Used when the app is not served over http(s) — e.g. a release build
  /// opened from the filesystem, where `Uri.base.origin` throws.
  static const String _fallbackOrigin = 'http://localhost';

  /// The bare origin, with the current scheme when it is http(s).
  static String get origin {
    final base = Uri.base;
    final scheme = base.scheme;
    return (scheme == 'http' || scheme == 'https') ? base.origin : _fallbackOrigin;
  }

  static String get resetPassword => '$origin/?$flowParam=$flowReset';

  static String get confirmEmail => '$origin/?$flowParam=$flowSignup';

  /// Holds the callback URL captured before GoRouter consumed it.
  ///
  /// Supabase's token arrives in the fragment, which GoRouter's hash
  /// strategy would overwrite on boot. main() stashes the URL here and
  /// clears the address bar; the reset/confirm screens read it back out.
  static Uri? pendingCallback;

  /// The URL the screens should hand to `getSessionFromUrl`.
  static Uri callbackUri() => pendingCallback ?? Uri.base;

  /// True when this page was opened from an email link.
  static bool isAuthCallback(Uri uri) => detect(uri) != null;

  /// True when the fragment carries Supabase's tokens, which is the case
  /// GoRouter must not be allowed to parse as a route.
  static bool hasFragmentTokens(Uri uri) {
    final frag = uri.fragment;
    return frag.contains('access_token=') ||
        frag.contains('refresh_token=') ||
        frag.contains('error_description=') ||
        frag.contains('token_hash=');
  }

  /// The route this callback should land on, or null if it is a normal visit.
  ///
  /// [uri] must be the real browser location (Uri.base), because the tokens
  /// live there rather than in go_router's fragment.
  ///
  /// Two signals are used, most reliable first:
  ///   1. `?flow=` — our own marker. Best, but Supabase STRIPS the query
  ///      string unless the full URL (query included) is in the Redirect
  ///      URLs allow-list. Without that entry it silently falls back to the
  ///      Site URL, so this signal is often absent in practice.
  ///   2. `type=` inside Supabase's fragment — `signup` for a confirmation
  ///      email, `recovery` for a password reset. Always present, so this is
  ///      what actually decides the route in local development.
  static String? detect(Uri uri) {
    final flow = uri.queryParameters[flowParam];
    if (flow == flowReset) return '/reset-password';
    if (flow == flowSignup) return '/email-confirmed';

    final frag = uri.fragment.toLowerCase();

    if (frag.contains('error_description=')) return '/reset-password';
    // Order matters: check signup before the generic token checks so a
    // confirmation link never gets mistaken for a password reset.
    if (frag.contains('type=signup') ||
        frag.contains('type=invite') ||
        frag.contains('type=email_change')) {
      return '/email-confirmed';
    }
    if (frag.contains('type=recovery') ||
        frag.contains('access_token=') ||
        frag.contains('refresh_token=') ||
        frag.contains('token_hash=')) {
      return '/reset-password';
    }
    return null;
  }
}
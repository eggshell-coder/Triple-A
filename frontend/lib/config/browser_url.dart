// lib/config/browser_url.dart
// Clears the browser URL before GoRouter starts.
//
// THE COLLISION THIS SOLVES
// ------------------------
// Supabase delivers its token in the URL *fragment*:
//     http://localhost:3000/#access_token=eyJ...&type=signup
//
// GoRouter's HASH strategy also owns the fragment:
//     http://localhost:3000/#/login
//
// On boot GoRouter reads the fragment as a route path, fails to match
// "#access_token=..." , fires onException, and navigates to /login — which
// REWRITES the hash and destroys the token before any screen can read it.
//
// So the fragment must be captured and removed before runApp(). The token
// is kept in [AuthCallbackStore] and the screens read it from there.
//
// dart:html is web-only, hence the conditional import: unit tests run on the
// Dart VM where it does not exist.

export 'browser_url_stub.dart'
    if (dart.library.html) 'browser_url_web.dart';
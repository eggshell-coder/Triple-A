// Web implementation of clearUrlFragment().
import 'dart:html' as html;

/// Removes the fragment (and a stale auth query) from the address bar
/// WITHOUT reloading, so GoRouter starts from a clean route and the
/// Supabase token survives in AuthCallbackStore.
void clearUrlFragment() {
  final loc = html.window.location;
  // history.replaceState replaces the current entry — no navigation, no
  // reload, so the already-parsed URL keeps working.
  // Note: dart:html's Location exposes `pathname`, not `path`.
  html.window.history.replaceState(
    null,
    '',
    '${loc.origin}${loc.pathname}',
  );
}
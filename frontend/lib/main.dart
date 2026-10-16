// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'config/browser_url.dart';
import 'services/api_service.dart';
import 'services/auth_redirects.dart';

const _supabaseUrl = 'https://ejuhfwqidjkxahbtvwps.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdWhmd3FpZGpreGFoYnR2d3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjA3NjUsImV4cCI6MjA5MTI5Njc2NX0.8DG1RR0pF1HCsW3kGw1LCIWcAsx6gb9-wMb4Klxeuqw';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      // Supabase's emailed links deliver the session in the URL FRAGMENT
      // (#access_token=...&type=signup). The default PKCE flow only looks for
      // ?code= in the query string, so getSessionFromUrl() would fail with
      // "No code detected in query parameters" and nobody could ever confirm
      // an email or reset a password. Implicit is what our links use.
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // Restore persisted admin token so upload/API calls work after page refresh
  await apiService.restoreAdminToken();

  // If we were opened from an emailed link, Supabase put its token in the
  // URL fragment. GoRouter's hash strategy would parse that fragment as a
  // route, fail, and rewrite the hash — destroying the token before any
  // screen can read it. So capture it and clear the address bar FIRST.
  final initialLocation = AuthRedirects.detect(Uri.base);
  if (AuthRedirects.hasFragmentTokens(Uri.base)) {
    AuthRedirects.pendingCallback = Uri.base;
    clearUrlFragment();
  }

  runApp(ProviderScope(
    child: TripleAApp(initialLocation: initialLocation),
  ));
}

class TripleAApp extends ConsumerWidget {
  final String? initialLocation;
  const TripleAApp({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider(initialLocation));
    return MaterialApp.router(
      title: 'Triple A – Clothing Store',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
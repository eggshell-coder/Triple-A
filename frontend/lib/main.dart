// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'services/api_service.dart';

const _supabaseUrl = 'https://ejuhfwqidjkxahbtvwps.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdWhmd3FpZGpreGFoYnR2d3BzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjA3NjUsImV4cCI6MjA5MTI5Njc2NX0.8DG1RR0pF1HCsW3kGw1LCIWcAsx6gb9-wMb4Klxeuqw';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // Restore persisted admin token so upload/API calls work after page refresh
  await apiService.restoreAdminToken();

  runApp(const ProviderScope(child: TripleAApp()));
}

class TripleAApp extends ConsumerWidget {
  const TripleAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Triple A – Clothing Store',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

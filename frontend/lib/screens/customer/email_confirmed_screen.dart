// lib/screens/customer/email_confirmed_screen.dart
//
// Landing page for the link inside the confirmation email.
//
// Supabase redirects here with a short-lived session in the URL. This
// screen trades that session for one of our own, stores it, and sends the
// user to the homepage already signed in.
//
// If the link is missing, expired, or the network is down, it explains
// that and offers the manual path rather than showing a blank screen.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_redirects.dart';
import '../../providers/user_provider.dart';

class EmailConfirmedScreen extends ConsumerStatefulWidget {
  const EmailConfirmedScreen({super.key});

  @override
  ConsumerState<EmailConfirmedScreen> createState() => _EmailConfirmedScreenState();
}

enum _State { working, ok, noSession, failed }

class _EmailConfirmedScreenState extends ConsumerState<EmailConfirmedScreen> {
  _State _state = _State.working;
  String? _message;

  /// Address that was confirmed — shown so the user can see it matched.
  String _emailOrGuest = '';

  /// Counts down to the automatic redirect. Visible so the user is not
  /// yanked away mid-read.
  static const int _redirectSeconds = 3;
  int _countdown = _redirectSeconds;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _finishSignIn();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  /// Schedules the jump to the homepage once the user is signed in.
  void _scheduleRedirect() {
    _redirectTimer?.cancel();
    _countdown = _redirectSeconds;
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_countdown <= 1) {
        t.cancel();
        context.go('/');
        return;
      }
      setState(() => _countdown--);
    });
  }

  Future<void> _finishSignIn() async {
    try {
      // The confirmation link puts tokens in the URL. Supabase only turns
      // them into a session here, so this is the step that signs the user in.
      var session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        // An expired, tampered or already-used link THROWS here rather than
        // returning null — that is the common case, so it deserves its own
        // message instead of the generic failure text.
        try {
          final res = await Supabase.instance.client.auth
              .getSessionFromUrl(AuthRedirects.callbackUri());
          session = res.session;
        } on AuthException catch (e) {
          setState(() {
            _state = _State.noSession;
            _message =
                '${e.message} This link may have expired or already been used.';
          });
          return;
        }
      }

      // Exchange the Supabase session for our own customer profile. This
      // also flips email_confirmed_at in the database.
      final data = await apiService.customerSession(session.accessToken);
      final user = data['user'] as Map<String, dynamic>?;

      if (user == null) {
        setState(() {
          _state = _State.failed;
          _message = 'We could not find a customer account for this email.';
        });
        return;
      }

      await ref.read(userProvider.notifier).login(
            session.accessToken,
            user,
          );

      if (mounted) {
        setState(() => _emailOrGuest = (user['email'] ?? '').toString());
      }

      if (mounted) {
        setState(() => _state = _State.ok);
        _scheduleRedirect();
      }
    } on AuthException catch (e) {
      setState(() {
        _state = _State.noSession;
        _message = e.message;
      });
    } catch (_) {
      setState(() {
        _state = _State.failed;
        _message = 'Something went wrong while confirming your email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _build(),
          ),
        ),
      ),
    );
  }

  Widget _build() {
    switch (_state) {
      case _State.working:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 24),
            Text(
              'Confirming your email…',
              style: TextStyle(fontSize: 15, color: AppColors.onSurfaceVariant),
            ),
          ],
        );

      case _State.ok:
        return _panel(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.completed,
          title: 'Email confirmed',
          body: 'You are signed in as ${_emailOrGuest}.\n'
              'Redirecting to the store in $_countdown…',
          action: FilledButton(
            onPressed: () {
              _redirectTimer?.cancel();
              context.go('/');
            },
            child: const Text('GO TO STORE NOW'),
          ),
        );

      case _State.noSession:
        return _panel(
          icon: Icons.link_off_outlined,
          iconColor: AppColors.secondary,
          title: 'This link is no longer valid',
          body: _message ??
              'Confirmation links expire quickly and work only once. '
                  'Sign in with your email and password to continue.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('GO TO SIGN IN'),
          ),
          secondary: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text('FORGOT PASSWORD'),
          ),
        );

      case _State.failed:
        return _panel(
          icon: Icons.error_outline,
          iconColor: AppColors.secondary,
          title: 'Could not sign you in',
          body: _message ??
              'Your email may be confirmed, but we could not finish signing you in.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('GO TO SIGN IN'),
          ),
        );
    }
  }

  Widget _panel({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required Widget action,
    Widget? secondary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 44, color: iconColor),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.newsreader(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.6,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        action,
        if (secondary != null) ...[const SizedBox(height: 8), secondary],
      ],
    );
  }
}
// lib/screens/auth/reset_password_screen.dart
//
// Step 2 of the reset flow. The user arrived here by clicking the emailed
// link, which gives the app a short-lived recovery session. This screen
// swaps the password on that session.
//
// Security note: we never read a password from a URL and never email a
// password. The emailed link proves only "this inbox owns the account".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../services/password_reset_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/visible_password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final ResetAudience audience;
  const ResetPasswordScreen({super.key, this.audience = ResetAudience.customer});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// null while still checking, then true/false once known.
  bool? _checkingSession = true;
  bool _hasSession = false;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifySession();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifySession() async {
    // Only accept the form once we know the recovery link worked. Without
    // this, opening /reset-password directly would show a form that always
    // fails on submit.
    bool ok;
    try {
      ok = await passwordResetService.hasRecoverySession();
    } on AuthException {
      ok = false;
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _hasSession = ok;
      _checkingSession = false;
    });
  }

  Future<void> _submit() async {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    final passwordError = validateNewPassword(password);
    if (passwordError != null) {
      setState(() => _error = passwordError);
      return;
    }
    final confirmError = validateConfirmation(password, confirm);
    if (confirmError != null) {
      setState(() => _error = confirmError);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await passwordResetService.updatePassword(password);
      // Kill the recovery session so the emailed link cannot be reused.
      await passwordResetService.endSession();
      if (mounted) {
        setState(() {
          _done = true;
          _loading = false;
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not update your password. The link may have expired — request a new one.';
        _loading = false;
      });
    }
  }

  Future<void> _requestNewLink() async {
    await passwordResetService.endSession();
    if (mounted) {
      context.go('/forgot-password?audience=${widget.audience.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.audience == ResetAudience.admin;
    final dark = isAdmin;

    return Scaffold(
      backgroundColor: dark ? AppColors.primary : AppColors.surface,
      appBar: dark ? null : const AppNavBar(showBack: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _body(dark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool dark) {
    // _checkingSession is bool? (null = not yet known), so compare
    // explicitly — Dart will not accept a nullable bool as an if condition.
    if (_checkingSession == true) {
      return Center(
        child: CircularProgressIndicator(
          color: dark ? Colors.white : AppColors.primary,
        ),
      );
    }

    if (_done) return _donePanel(dark);

    if (!_hasSession) return _invalidLinkPanel(dark);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose a new password',
            style: GoogleFonts.newsreader(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              height: 1.15,
              color: dark ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pick something you have not used before.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          if (_error != null) ...[
            _errorBanner(_error!),
            const SizedBox(height: 20),
          ],

          VisiblePasswordField(
            controller: _passwordCtrl,
            label: 'New password',
            enabled: !_loading,
            helperText: passwordRules.join(' · '),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 20),

          VisiblePasswordField(
            controller: _confirmCtrl,
            label: 'Confirm new password',
            enabled: !_loading,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: _submit,
          ),

          // Live match indicator, so the user sees the two fields agree
          // before they hit the button.
          if (_confirmCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    _passwordCtrl.text == _confirmCtrl.text
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 15,
                    color: _passwordCtrl.text == _confirmCtrl.text
                        ? (dark ? Colors.white70 : AppColors.completed)
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _passwordCtrl.text == _confirmCtrl.text
                        ? 'Passwords match'
                        : 'Passwords do not match',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: _passwordCtrl.text == _confirmCtrl.text
                          ? (dark ? Colors.white70 : AppColors.completed)
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: dark ? Colors.white : AppColors.primary,
                foregroundColor: dark ? AppColors.primary : Colors.white,
              ),
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: dark ? AppColors.primary : Colors.white,
                      ),
                    )
                  : const Text('UPDATE PASSWORD'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _donePanel(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 40,
          color: dark ? Colors.white : AppColors.completed,
        ),
        const SizedBox(height: 20),
        Text(
          'Password updated',
          style: GoogleFonts.newsreader(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: dark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your password has been changed. Sign in with the new one.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(widget.audience.loginPath),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: dark ? Colors.white : AppColors.primary,
              foregroundColor: dark ? AppColors.primary : Colors.white,
            ),
            child: Text(widget.audience == ResetAudience.admin
                ? 'BACK TO ADMIN LOGIN'
                : 'BACK TO SIGN IN'),
          ),
        ),
      ],
    );
  }

  Widget _invalidLinkPanel(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.link_off_outlined,
          size: 40,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 20),
        Text(
          'This link is no longer valid',
          style: GoogleFonts.newsreader(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: dark ? Colors.white : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Reset links expire after a short time and can only be used once. '
          'Request a fresh link to continue.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestNewLink,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: dark ? Colors.white : AppColors.primary,
              foregroundColor: dark ? AppColors.primary : Colors.white,
            ),
            child: const Text('REQUEST A NEW LINK'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.go(widget.audience.loginPath),
            child: Text(
              '← Back to login',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFFFEBEE),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
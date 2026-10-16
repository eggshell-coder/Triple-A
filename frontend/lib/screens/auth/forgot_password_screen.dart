// lib/screens/auth/forgot_password_screen.dart
//
// Step 1 of the reset flow: collect the email and send a reset link.
// One screen serves both admin and customer — only the copy and where the
// user returns to differ.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../services/password_reset_service.dart';
import '../../widgets/shared_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final ResetAudience audience;
  const ForgotPasswordScreen({super.key, this.audience = ResetAudience.customer});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await passwordResetService.sendResetEmail(_emailCtrl.text);
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not send the reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.audience == ResetAudience.admin;
    final dark = isAdmin;

    return Scaffold(
      backgroundColor: dark ? AppColors.primary : AppColors.surface,
      appBar: dark
          ? null
          : const AppNavBar(showBack: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _header(dark),
                    const SizedBox(height: 32),

                    if (_sent)
                      _sentPanel(dark)
                    else ...[
                      if (_error != null) ...[
                        _errorBanner(_error!),
                        const SizedBox(height: 20),
                      ],
                      _emailField(dark),
                      const SizedBox(height: 28),
                      _submitButton(dark),
                      const SizedBox(height: 16),
                      _backLink(dark),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool dark) {
    final title = dark ? 'Reset admin password' : 'Forgot your password?';
    final sub = dark
        ? 'Enter your admin email and we will send you a link to choose a new password.'
        : 'Enter the email on your account and we will send you a reset link.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_reset_outlined,
          size: 34,
          color: dark ? Colors.white : AppColors.primary,
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: GoogleFonts.newsreader(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: dark ? Colors.white : AppColors.onSurface,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sub,
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _emailField(bool dark) {
    return TextFormField(
      controller: _emailCtrl,
      enabled: !_loading,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.manrope(
        fontSize: 14,
        color: dark ? Colors.white : AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: 'Email address',
        prefixIcon: const Icon(Icons.alternate_email, size: 18),
        labelStyle: TextStyle(color: dark ? Colors.white70 : null),
      ),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
      onFieldSubmitted: (_) => _send(),
    );
  }

  Widget _submitButton(bool dark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _send,
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
            : const Text('SEND RESET LINK'),
      ),
    );
  }

  Widget _backLink(bool dark) {
    return Center(
      child: TextButton(
        onPressed: _loading ? null : () => context.go(widget.audience.loginPath),
        child: Text(
          widget.audience == ResetAudience.admin
              ? '← Back to admin login'
              : '← Back to sign in',
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _sentPanel(bool dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? AppColors.primaryContainer : AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 20,
                color: dark ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Check your inbox',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'If an account exists for ${_emailCtrl.text.trim()}, a reset link is on its way. '
            'The link opens this app with a form to choose a new password.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              color: dark ? Colors.white70 : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Check spam if it does not arrive within a few minutes.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: dark ? Colors.white54 : AppColors.outline,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _sent = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dark ? Colors.white : AppColors.primary,
                    side: BorderSide(
                      color: dark ? Colors.white38 : AppColors.outlineVariant,
                    ),
                  ),
                  child: const Text('RESEND'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go(widget.audience.loginPath),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark ? Colors.white : AppColors.primary,
                    foregroundColor: dark ? AppColors.primary : Colors.white,
                  ),
                  child: const Text('BACK TO LOGIN'),
                ),
              ),
            ],
          ),
        ],
      ),
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
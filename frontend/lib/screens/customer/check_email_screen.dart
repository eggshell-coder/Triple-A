// lib/screens/customer/check_email_screen.dart
//
// Shown after signup when Supabase requires the user to click a
// confirmation link. Unlike a throwaway dialog, this is a real page: it
// survives a refresh, can be reached from a bookmark, and can resend.
//
// Shows the exact address the link went to — the single most common
// support question is "which email did I use?"

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class CheckEmailScreen extends StatefulWidget {
  /// Address the confirmation link was sent to.
  final String email;

  /// True when the backend had no session at signup, i.e. verification is
  /// genuinely outstanding.
  final bool confirmationRequired;

  const CheckEmailScreen({
    super.key,
    required this.email,
    this.confirmationRequired = true,
  });

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  static const int _cooldownSeconds = 45;

  int _secondsLeft = 0;
  Timer? _cooldown;
  bool _resending = false;
  String? _resendNote;
  String? _resendError;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendError = null;
      _resendNote = null;
    });

    try {
      final message = await apiService.resendConfirmation(widget.email);
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendNote = message;
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _icon(),
                const SizedBox(height: 24),
                Text(
                  widget.confirmationRequired
                      ? 'Confirm your email'
                      : 'Check your email',
                  style: GoogleFonts.newsreader(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _addressCard(),
                const SizedBox(height: 20),
                _steps(),
                const SizedBox(height: 28),
                _resendButton(),
                const SizedBox(height: 20),
                _signInButton(),
                const SizedBox(height: 12),
                _helpText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon() {
    final color = widget.confirmationRequired
        ? AppColors.tertiary
        : AppColors.completed;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.confirmationRequired
            ? Icons.mark_email_unread_outlined
            : Icons.mark_email_read_outlined,
        size: 28,
        color: color,
      ),
    );
  }

  /// Shows the literal address the link was sent to.
  Widget _addressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email, size: 18, color: AppColors.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmation link sent to',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                // A plain Text inside SelectionArea, not SelectableText: SelectableText
// does not publish its text to the semantics tree, so the address was
// invisible to screen readers and to anything inspecting the tree.
                SelectionArea(
                  child: Text(
                    widget.email,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What happens next',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.tertiary,
          ),
        ),
        const SizedBox(height: 12),
        _step(
          '1',
          'Open the email we sent.',
          'Check your spam or junk folder if it is not in your inbox.',
        ),
        const SizedBox(height: 12),
        _step(
          '2',
          'Click the confirmation link.',
          'It opens Triple A and signs you in automatically.',
        ),
        const SizedBox(height: 12),
        _step(
          '3',
          'You are signed in.',
          'If the link has expired, request a new one below.',
        ),
      ],
    );
  }

  Widget _step(String n, String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resendButton() {
    if (_resendError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFFFFEBEE),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.secondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _resendError!,
                  style: GoogleFonts.manrope(fontSize: 13, color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_resendNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.completed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resendNote!,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.completed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _resending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _secondsLeft > 0
                        ? 'RESEND IN ${_secondsLeft}s'
                        : 'RESEND CONFIRMATION EMAIL',
                    style: const TextStyle(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _signInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/login'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: const Text('I HAVE CONFIRMED — SIGN IN'),
      ),
    );
  }

  Widget _helpText() {
    return Text(
      'Wrong address? Create another account with the email you want to use.',
      textAlign: TextAlign.center,
      style: GoogleFonts.manrope(
        fontSize: 12,
        height: 1.5,
        color: AppColors.outline,
      ),
    );
  }
}
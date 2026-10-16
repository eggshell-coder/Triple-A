// lib/screens/customer/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/password_reset_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    // Same rule set the backend enforces — see auth.controller's validator.
    final passwordProblem = validateNewPassword(_passCtrl.text);
    if (passwordProblem != null) {
      setState(() => _error = passwordProblem);
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final data = await apiService.customerSignup(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        fullName: _nameCtrl.text.trim(),
      );

      final token = data['token'] as String?;
      final needsConfirm = data['email_confirmation_required'] as bool? ?? false;

      if (token != null && !needsConfirm) {
        // Supabase confirmed the address itself — sign straight in.
        await ref.read(userProvider.notifier).login(
              token,
              data['user'] as Map<String, dynamic>,
            );
        if (mounted) context.go('/');
        return;
      }

      // Verification is outstanding: hand off to a full page, not a dialog,
      // so the address stays visible and the link can be resent.
      if (mounted) {
        context.go(
          '/check-email'
          '?email=${Uri.encodeComponent(_emailCtrl.text.trim())}'
          '&required=$needsConfirm',
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppNavBar(showBack: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account',
                    style: GoogleFonts.newsreader(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text('Just your name and email — takes 30 seconds.',
                    style: GoogleFonts.manrope(
                        fontSize: 14, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 40),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: const Color(0xFFFFEBEE),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.secondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.manrope(
                                  fontSize: 13, color: AppColors.secondary))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration:
                      const InputDecoration(labelText: 'Full Name *'),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: const InputDecoration(labelText: 'Email *'),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    // Must match the backend rules exactly, otherwise the
                    // user passes this form and is rejected server-side
                    // with a message they cannot act on.
                    helperText: passwordRules.join(' · '),
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password *'),
                  onFieldSubmitted: (_) => _signup(),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFF0F7F1),
                  child: Row(children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.completed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Phone and address will be collected when you place your first order.',
                        style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            height: 1.5),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('CREATE ACCOUNT'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.onSurfaceVariant)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text('Sign in',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
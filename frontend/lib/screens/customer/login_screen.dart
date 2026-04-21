// lib/screens/customer/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await apiService.customerLogin(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await ref.read(userProvider.notifier).login(
        data['token'],
        data['user'] as Map<String, dynamic>,
      );

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
                Text('Welcome back',
                    style: GoogleFonts.newsreader(
                        fontSize: 36,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text('Sign in to view your orders and shop.',
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
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 24),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ",
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: AppColors.onSurfaceVariant)),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: Text('Create one',
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
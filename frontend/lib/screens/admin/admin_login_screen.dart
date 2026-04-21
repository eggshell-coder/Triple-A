// lib/screens/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await apiService.login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      ref
          .read(authProvider.notifier)
          .login(data['user'] as Map<String, dynamic>);

      if (mounted) {
        context.go('/admin/dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          // ── Left branding panel (wide screens only) ──────────────────
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TRIPLE A',
                      style: GoogleFonts.newsreader(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Admin Panel',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: Colors.white60,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 64),
                    const _InfoItem(
                      icon: Icons.inventory_2_outlined,
                      text: 'Manage Products & Inventory',
                    ),
                    const SizedBox(height: 20),
                    const _InfoItem(
                      icon: Icons.receipt_long_outlined,
                      text: 'View & Update Orders',
                    ),
                    const SizedBox(height: 20),
                    const _InfoItem(
                      icon: Icons.dashboard_outlined,
                      text: 'Business Dashboard & Stats',
                    ),
                  ],
                ),
              ),
            ),

          // ── Right login form ─────────────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.surfaceLowest,
              padding: const EdgeInsets.all(64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: GoogleFonts.newsreader(
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your admin account',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Error message ────────────────────────────
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: const Color(0xFFFFEBEE),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Email field ──────────────────────────────
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Password field ───────────────────────────
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: AppColors.outline,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ── Sign in button ───────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('SIGN IN'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Back to store ────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(
                              '← Back to Store',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }
}
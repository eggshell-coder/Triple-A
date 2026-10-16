// lib/widgets/visible_password_field.dart
//
// A password TextFormField with a show/hide toggle.
//
// Both the "forgot password" and "reset password" screens need this, and
// each field needs its OWN toggle state — so the visibility is internal
// rather than lifted into the parent.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class VisiblePasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const VisiblePasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.helperText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  State<VisiblePasswordField> createState() => _VisiblePasswordFieldState();
}

class _VisiblePasswordFieldState extends State<VisiblePasswordField> {
  bool _obscured = true;

  void _toggle() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      style: GoogleFonts.manrope(fontSize: 14, color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: AppColors.outline,
          ),
          tooltip: _obscured ? 'Show password' : 'Hide password',
          onPressed: _toggle,
        ),
      ),
    );
  }
}
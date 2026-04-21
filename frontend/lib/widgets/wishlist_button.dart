// lib/widgets/wishlist_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class WishlistButton extends ConsumerStatefulWidget {
  final String productId;   // UUID string
  final double size;
  final Color? activeColor;

  const WishlistButton({
    super.key,
    required this.productId,
    this.size = 20,
    this.activeColor,
  });

  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton> {
  bool _wishlisted = false;
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = ref.read(userProvider);
    if (!user.isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final result = await apiService.checkWishlist(widget.productId);
      if (mounted) setState(() { _wishlisted = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final user = ref.read(userProvider);
    if (!user.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save to wishlist.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await apiService.toggleWishlist(widget.productId);
      if (mounted) setState(() { _wishlisted = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width:  widget.size + 4,
        height: widget.size + 4,
        child: const CircularProgressIndicator(strokeWidth: 1.5),
      );
    }
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _wishlisted ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(_wishlisted),
          size: widget.size,
          color: _wishlisted
              ? (widget.activeColor ?? const Color(0xFFE57373))
              : Colors.grey,
        ),
      ),
    );
  }
}
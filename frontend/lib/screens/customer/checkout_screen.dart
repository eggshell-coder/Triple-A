// lib/screens/customer/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../data/bangladesh_geo.dart';
import '../../widgets/shared_widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _bkashTxnCtrl = TextEditingController();

  // Generated once when the screen opens; reused on every retry so the backend
  // can deduplicate a double-tap or network-retry into a single order.
  late final String _idempotencyKey = const Uuid().v4();

  String? _selectedDistrict;
  String? _selectedUpazila;
  bool    _submitting = false;

  // Payment method: 'cash_on_delivery' or 'bkash'
  String _paymentMethod = 'cash_on_delivery';
  static const String _bkashNumber = '017XXXXXXXX';

  List<String> get _upazilas {
    if (_selectedDistrict == null) return [];
    return BangladeshGeo.upazilasByDistrict[_selectedDistrict!] ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _bkashTxnCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null) {
      _showSnack('Please select a district');
      return;
    }
    if (_selectedUpazila == null) {
      _showSnack('Please select an upazila');
      return;
    }

    if (_paymentMethod == 'bkash') {
      if (_bkashTxnCtrl.text.trim().isEmpty) {
        _showSnack('bKash transaction ID required');
        return;
      }
    }

    setState(() => _submitting = true);

    final user = ref.read(userProvider);
    final cart = ref.read(cartProvider);

    try {
      final items = cart.map((i) => {
        'product_id': i.productId,
        'quantity':   i.quantity,
        'unit_price': i.price,
      }).toList();

      await apiService.placeOrder(
        customer: {
          'full_name':    _nameCtrl.text.trim(),
          'phone':        _phoneCtrl.text.trim(),
          'district':     _selectedDistrict!,
          'upazila':      _selectedUpazila!,
          'address_line': _addressCtrl.text.trim(),
        },
        items:          items,
        note:           _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        district:       _selectedDistrict,
        upazila:        _selectedUpazila,
        userId:         user.userId,
        idempotencyKey: _idempotencyKey,
        paymentMethod: _paymentMethod,
        bkashTransactionId: _paymentMethod == 'bkash' ? _bkashTxnCtrl.text.trim() : null,
        bkashPaidTo: _paymentMethod == 'bkash' ? _bkashNumber : null,
      );

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        _showSnack('Order placed successfully! 🎉', success: true);
        context.go('/my-orders');
      }
    } catch (e) {
      _showSnack('Failed to place order: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error
          ? Colors.red
          : success
              ? Colors.green
              : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart  = ref.watch(cartProvider);
    final total = cart.fold<double>(0, (s, i) => s + i.price * i.quantity);

    return Scaffold(
      appBar: const AppNavBar(showBack: true),
      backgroundColor: const Color(0xFFF8F5F0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('SHIPPING INFORMATION'),
              const SizedBox(height: 12),
              _buildTextField(_nameCtrl, 'Full Name', required: true),
              const SizedBox(height: 12),
              _buildTextField(_phoneCtrl, 'Phone Number', required: true),
              const SizedBox(height: 12),

              // ── District ──────────────────────────────────────────
              _buildDropdown(
                label: 'District',
                value: _selectedDistrict,
                items: BangladeshGeo.districts,
                onChanged: (val) => setState(() {
                  _selectedDistrict = val;
                  _selectedUpazila  = null;
                }),
              ),
              const SizedBox(height: 12),

              // ── Upazila (dependent on district) ───────────────────
              _buildDropdown(
                label:    'Upazila',
                value:    _selectedUpazila,
                items:    _upazilas,
                enabled:  _selectedDistrict != null,
                hint:     _selectedDistrict == null
                    ? 'Select district first'
                    : 'Select upazila',
                onChanged: (val) =>
                    setState(() => _selectedUpazila = val),
              ),
              const SizedBox(height: 12),

              _buildTextField(_addressCtrl, 'Address Line', required: true),
              const SizedBox(height: 12),
              _buildTextField(_notesCtrl, 'Order Notes (optional)',
                  required: false, maxLines: 3),
              const SizedBox(height: 24),

              // ── Payment Method ─────────────────────────────────────
              _sectionLabel('PAYMENT METHOD'),
              const SizedBox(height: 12),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),

              // ── Order Summary ─────────────────────────────────────
              _sectionLabel('ORDER SUMMARY'),
              const SizedBox(height: 12),
              ...cart.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${i.name} × ${i.quantity}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(fontSize: 13)),
                        ),
                        Text(
                          '৳${(i.price * i.quantity).toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('৳${total.toStringAsFixed(0)}',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('PLACE ORDER',
                          style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFF888888)),
      );

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _buildPaymentOption(
          value: 'cash_on_delivery',
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.money,
        ),
        const SizedBox(height: 10),
        _buildPaymentOption(
          value: 'bkash',
          title: 'bKash Send Money',
          subtitle: 'Pay via bKash Send Money to our number',
          icon: Icons.phone_android,
        ),
        if (_paymentMethod == 'bkash') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('bKash number e Send Money korun:',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.pink, size: 20),
                      const SizedBox(width: 8),
                      Text('017XXXXXXXX',
                          style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Pay korar por Transaction ID ekhane likhun:',
                    style: GoogleFonts.manrope(fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bkashTxnCtrl,
                  decoration: InputDecoration(
                    labelText: 'bKash Transaction ID',
                    hintText: 'TRX123456789',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.pink)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Transaction ID required' : null,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _paymentMethod == value ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _paymentMethod == value ? Colors.blue : Colors.grey.shade300,
            width: _paymentMethod == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _paymentMethod == value ? Colors.blue : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (_paymentMethod == value)
              const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(fontSize: 13),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
      ),
      hint: Text(hint ?? 'Select $label',
          style: GoogleFonts.manrope(fontSize: 13)),
      items: items
          .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: GoogleFonts.manrope(fontSize: 13))))
          .toList(),
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
    );
  }
}
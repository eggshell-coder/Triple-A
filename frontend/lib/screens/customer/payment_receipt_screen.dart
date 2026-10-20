import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final String orderId;
  const PaymentReceiptScreen({super.key, required this.orderId});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await apiService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data['data'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _shortId(String id) {
    return id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _paymentMethodLabel(String? method) {
    switch (method) {
      case 'bkash':
        return 'bKash Send Money';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      default:
        return method ?? '—';
    }
  }

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'verified':
        return 'Verified';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Payment Receipt', style: GoogleFonts.newsreader(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _order == null ? null : _shareReceipt,
            tooltip: 'Share',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _buildReceipt(),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildReceipt() {
    final order = _order!;
    final customer = order['customers'] as Map<String, dynamic>? ?? {};
    final items = (order['order_items'] as List?) ?? [];
    final total = (order['total_amount'] ?? 0).toDouble();
    final deliveryCharge = (order['delivery_charge'] ?? 0).toDouble();
    final subtotal = total - deliveryCharge;
    final paymentMethod = _paymentMethodLabel(order['payment_method'] as String?);
    final paymentStatus = _paymentStatusLabel(order['payment_status'] as String?);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text('TRIPLE A',
                    style: GoogleFonts.newsreader(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 4)),
                Text('Online Clothing Store',
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('Payment Receipt',
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),

          // Order Info
          _receiptRow('Order ID', _shortId(order['id'] ?? '')),
          _receiptRow('Date', _formatDate(order['created_at'] as String?)),
          _receiptRow('Status', (order['status'] ?? 'pending').toString().toUpperCase()),
          _receiptRow('Payment Method', paymentMethod),
          _receiptRow('Payment Status', paymentStatus),
          if (order['payment_method'] == 'bkash' && order['bkash_transaction_id'] != null)
            _receiptRow('bKash Txn ID', order['bkash_transaction_id'] as String),

          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),

          // Customer Info
          Text('CUSTOMER INFORMATION',
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          _receiptRow('Name', customer['full_name'] ?? '—'),
          _receiptRow('Phone', customer['phone'] ?? '—'),
          _receiptRow('Address', customer['address_line'] ?? '—'),
          _receiptRow('District', order['district'] ?? '—'),
          _receiptRow('Upazila', order['upazila'] ?? '—'),
          if (customer['email'] != null)
            _receiptRow('Email', customer['email'] as String),

          const SizedBox(height: 16),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),

          // Items
          Text('ORDER ITEMS',
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...items.map((item) {
            final product = item['products'] as Map<String, dynamic>?;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(product?['name'] ?? '—',
                        style: GoogleFonts.manrope(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('x${item['quantity']}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TK ${((item['unit_price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 8),

          // Totals
          _receiptRow('Subtotal', 'TK ${subtotal.toStringAsFixed(0)}'),
          _receiptRow('Delivery Charge', 'TK ${deliveryCharge.toStringAsFixed(0)}'),
          const Divider(height: 16),
          _receiptRow('TOTAL', 'TK ${total.toStringAsFixed(0)}',
              isBold: true, color: AppColors.primary),

          if (order['note'] != null) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            _receiptRow('Note', order['note'] as String),
          ],

          const SizedBox(height: 24),
          Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),

          // Footer
          Center(
            child: Column(
              children: [
                Text('Thank you for shopping with Triple A!',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text('Please keep this receipt for your records.',
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: isBold ? AppColors.onSurface : AppColors.onSurfaceVariant)),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? AppColors.onSurface)),
        ],
      ),
    );
  }

  void _shareReceipt() {
    // For now, just show a message. In production, you'd use share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt sharing coming soon')),
    );
  }
}

// lib/screens/admin/order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN ORDER MANAGEMENT SCREEN
// Shows all orders. Clicking a row opens full order detail.
// ─────────────────────────────────────────────────────────────────────────────
class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});
  @override
  ConsumerState<OrderManagementScreen> createState() =>
      _OrderManagementScreenState();
}

class _OrderManagementScreenState
    extends ConsumerState<OrderManagementScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _statusFilter = 'all';

  final _statusOptions = [
    'all', 'pending', 'processing', 'completed', 'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getOrders(
          status: _statusFilter == 'all' ? null : _statusFilter);
      if (mounted) {
        setState(() {
          _orders = data['data'] as List<dynamic>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewOrder(dynamic order) {
    showDialog(
        context: context,
        builder: (_) => _OrderDetailDialog(orderId: order['id']));
  }

  // Opens the Product Orders Summary page (separate full screen)
  void _openProductOrdersSummary() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ProductOrdersSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Orders',
      activePath: '/admin/orders',
      actions: [
        // Button to open product orders summary
        OutlinedButton.icon(
          onPressed: _openProductOrdersSummary,
          icon: const Icon(Icons.bar_chart_outlined, size: 18),
          label: const Text('PRODUCT ORDERS'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
      body: Column(children: [
        // ── Filter bar ──────────────────────────────────────────────────
        Container(
          color: AppColors.surfaceLowest,
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(children: [
            Text('Filter:',
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(width: 12),
            ..._statusOptions.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: s == 'all' ? 'ALL' : s.toUpperCase(),
                    selected: _statusFilter == s,
                    onTap: () {
                      setState(() => _statusFilter = s);
                      _load();
                    },
                  ),
                )),
            const Spacer(),
            // Order count
            Text('${_orders.length} orders',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
          ]),
        ),

        // ── Table ───────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppColors.outline),
                          const SizedBox(height: 16),
                          Text('No orders found',
                              style: GoogleFonts.newsreader(
                                  fontSize: 20,
                                  color: AppColors.onSurfaceVariant)),
                        ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Container(
                          color: AppColors.surfaceLowest,
                          child: Column(children: [
                            // Table header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              color: AppColors.surfaceLow,
                              child: Row(children: [
                                _H('ORDER ID', flex: 2),
                                _H('CUSTOMER', flex: 3),
                                _H('PHONE', flex: 2),
                                _H('TOTAL', flex: 2),
                                _H('STATUS', flex: 2),
                                _H('DATE', flex: 2),
                                _H('', flex: 2),
                              ]),
                            ),
                            ..._orders.map((o) => _OrderRow(
                                  order: o,
                                  onView: () => _viewOrder(o),
                                  onStatusChange: (status) async {
                                    try {
                                      await apiService
                                          .updateOrderStatus(
                                              o['id'], status);
                                      _load();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text('Error: $e')));
                                      }
                                    }
                                  },
                                )),
                          ]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT ORDERS SUMMARY SCREEN
// Shows every product and which customers have ordered it.
// ─────────────────────────────────────────────────────────────────────────────
class ProductOrdersSummaryScreen extends StatefulWidget {
  const ProductOrdersSummaryScreen({super.key});

  @override
  State<ProductOrdersSummaryScreen> createState() =>
      _ProductOrdersSummaryScreenState();
}

class _ProductOrdersSummaryScreenState
    extends State<ProductOrdersSummaryScreen> {
  // Map: productId → { product info, list of orders }
  Map<String, Map<String, dynamic>> _productOrderMap = {};
  bool _loading = true;
  String? _expandedProductId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // Single endpoint — returns everything grouped by product
      final data = await apiService.getProductOrdersSummary();
      final List<dynamic> items = data['data'] as List<dynamic>;

      // Convert to the map format the UI expects
      final Map<String, Map<String, dynamic>> productMap = {};
      for (final item in items) {
        final product = item['product'] as Map<String, dynamic>;
        final pid = product['id'] as String;
        productMap[pid] = {
          'product': product,
          'total_qty': item['total_qty'] ?? 0,
          'total_revenue': (item['total_revenue'] ?? 0).toDouble(),
          'orders': (item['orders'] as List<dynamic>)
              .map((o) => Map<String, dynamic>.from(o))
              .toList(),
        };
      }

      if (mounted) {
        setState(() {
          _productOrderMap = productMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Product Orders Summary',
            style: GoogleFonts.newsreader(
                color: Colors.white, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                  '${_productOrderMap.length} products',
                  style: GoogleFonts.manrope(
                      color: Colors.white60, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Loading order data...',
                    style: TextStyle(color: AppColors.onSurfaceVariant)),
              ]))
          : _productOrderMap.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 48, color: AppColors.outline),
                      const SizedBox(height: 16),
                      Text('No orders yet',
                          style: GoogleFonts.newsreader(
                              fontSize: 20,
                              color: AppColors.onSurfaceVariant)),
                    ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Page title + description
                    Text('Product Orders Summary',
                        style: GoogleFonts.newsreader(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                        'See which customers have ordered each product. Tap a product to expand.',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 24),

                    // Summary stats row
                    _SummaryStatsRow(productMap: _productOrderMap),
                    const SizedBox(height: 24),

                    // Product cards
                    ..._productOrderMap.entries.map((entry) {
                      final pid = entry.key;
                      final data = entry.value;
                      final isExpanded = _expandedProductId == pid;
                      return _ProductOrderCard(
                        productData: data,
                        isExpanded: isExpanded,
                        onToggle: () {
                          setState(() {
                            _expandedProductId =
                                isExpanded ? null : pid;
                          });
                        },
                      );
                    }),
                  ]),
                ),
    );
  }
}

// ─── Summary Stats Row ────────────────────────────────────────────────────────
class _SummaryStatsRow extends StatelessWidget {
  final Map<String, Map<String, dynamic>> productMap;
  const _SummaryStatsRow({required this.productMap});

  @override
  Widget build(BuildContext context) {
    final totalProducts = productMap.length;
    final totalQty = productMap.values
        .fold<int>(0, (s, v) => s + (v['total_qty'] as int));
    final totalRevenue = productMap.values.fold<double>(
        0, (s, v) => s + (v['total_revenue'] as double));

    return Row(children: [
      _StatCard(
          label: 'Products Ordered',
          value: '$totalProducts',
          icon: Icons.inventory_2_outlined),
      const SizedBox(width: 12),
      _StatCard(
          label: 'Total Items Sold',
          value: '$totalQty',
          icon: Icons.shopping_bag_outlined),
      const SizedBox(width: 12),
      _StatCard(
          label: 'Total Revenue',
          value:
              '৳ ${NumberFormat('#,##0').format(totalRevenue)}',
          icon: Icons.payments_outlined),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surfaceLowest,
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: GoogleFonts.newsreader(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface)),
              Text(label,
                  style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      );
}

// ─── Product Order Card ───────────────────────────────────────────────────────
class _ProductOrderCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ProductOrderCard({
    required this.productData,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final product = productData['product'] as Map<String, dynamic>;
    final orders =
        productData['orders'] as List<Map<String, dynamic>>;
    final totalQty = productData['total_qty'] as int;
    final totalRevenue = productData['total_revenue'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceLowest,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Product header row (always visible) ────────────────────────
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              // Product thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  width: 56,
                  height: 64,
                  child: product['image_url'] != null
                      ? Image.network(product['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surfaceLow))
                      : Container(
                          color: AppColors.surfaceLow,
                          child: const Icon(Icons.image_outlined,
                              size: 24, color: AppColors.outline)),
                ),
              ),
              const SizedBox(width: 16),

              // Product name + stats
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(product['name'] ?? '—',
                    style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Row(children: [
                  _InfoBadge(
                      label: '$totalQty sold',
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  _InfoBadge(
                      label:
                          '${orders.length} order${orders.length != 1 ? 's' : ''}',
                      color: AppColors.tertiary),
                  const SizedBox(width: 8),
                  _InfoBadge(
                      label:
                          '৳ ${NumberFormat('#,##0').format(totalRevenue)}',
                      color: AppColors.completed),
                ]),
              ])),

              // Expand icon
              Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.outline),
            ]),
          ),
        ),

        // ── Expanded customer list ─────────────────────────────────────
        if (isExpanded) ...[
          Container(
            height: 1,
            color: AppColors.outlineVariant.withOpacity(0.2),
          ),
          // Customer table header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            color: AppColors.surfaceLow,
            child: Row(children: [
              _TH('CUSTOMER', flex: 3),
              _TH('PHONE', flex: 2),
              _TH('ADDRESS', flex: 4),
              _TH('QTY', flex: 1),
              _TH('SUBTOTAL', flex: 2),
              _TH('STATUS', flex: 2),
              _TH('DATE', flex: 2),
            ]),
          ),
          // Customer rows
          ...orders.map((o) => _CustomerOrderRow(orderData: o)),
          // Total row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            color: AppColors.surfaceLow,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
              Text('Total revenue from this product:  ',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant)),
              Text(
                  '৳ ${NumberFormat('#,##0').format(totalRevenue)}',
                  style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Customer Order Row (inside expanded product card) ────────────────────────
class _CustomerOrderRow extends StatelessWidget {
  final Map<String, dynamic> orderData;
  const _CustomerOrderRow({required this.orderData});

  @override
  Widget build(BuildContext context) {
    final date = orderData['order_date'] != null
        ? DateFormat('dd MMM yyyy')
            .format(DateTime.parse(orderData['order_date']))
        : '—';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.15)))),
      child: Row(children: [
        // Customer name
        Expanded(
            flex: 3,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(orderData['customer_name'] ?? '—',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                  '#${orderData['order_id']?.toString().substring(0, 8).toUpperCase() ?? '—'}',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ])),

        // Phone
        Expanded(
            flex: 2,
            child: Text(orderData['customer_phone'] ?? '—',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),

        // Address
        Expanded(
            flex: 4,
            child: Text(orderData['customer_address'] ?? '—',
                style: GoogleFonts.manrope(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)),

        // Qty
        Expanded(
            flex: 1,
            child: Text('${orderData['quantity']}',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600))),

        // Subtotal
        Expanded(
            flex: 2,
            child: Text(
                '৳ ${(orderData['subtotal'] ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600))),

        // Status chip
        Expanded(
            flex: 2,
            child: StatusChip(orderData['order_status'] ?? 'pending')),

        // Date
        Expanded(
            flex: 2,
            child: Text(date,
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant))),
      ]),
    );
  }
}

// ─── Small info badge ─────────────────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2)),
        child: Text(label,
            style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

// ─── Table helpers ────────────────────────────────────────────────────────────
class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant)),
      );
}

class _H extends StatelessWidget {
  final String text;
  final int flex;
  const _H(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant)),
      );
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: selected
                      ? Colors.white
                      : AppColors.onSurfaceVariant)),
        ),
      );
}

// ─── Order Row ────────────────────────────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  final dynamic order;
  final VoidCallback onView;
  final Function(String) onStatusChange;
  const _OrderRow(
      {required this.order,
      required this.onView,
      required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final customer = order['customers'];
    final date = order['created_at'] != null
        ? DateFormat('dd MMM yy')
            .format(DateTime.parse(order['created_at']))
        : '—';
    final statusOptions = [
      'pending', 'processing', 'completed', 'cancelled'
    ];

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.2)))),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: Text(
                order['id']
                        ?.toString()
                        .substring(0, 8)
                        .toUpperCase() ??
                    '—',
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary))),
        Expanded(
            flex: 3,
            child: Text(customer?['full_name'] ?? '—',
                style: GoogleFonts.manrope(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
        Expanded(
            flex: 2,
            child: Text(customer?['phone'] ?? '—',
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant))),
        Expanded(
            flex: 2,
            child: Text(
                '৳ ${(order['total_amount'] ?? 0).toStringAsFixed(0)}',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600))),
        Expanded(
            flex: 2,
            child: PopupMenuButton<String>(
              initialValue: order['status'],
              tooltip: 'Change status',
              onSelected: onStatusChange,
              itemBuilder: (_) => statusOptions
                  .map((s) => PopupMenuItem(
                      value: s,
                      child: Text(s.toUpperCase(),
                          style: GoogleFonts.manrope(fontSize: 12))))
                  .toList(),
              child: StatusChip(order['status'] ?? 'pending'),
            )),
        Expanded(
            flex: 2,
            child: Text(date,
                style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant))),
        Expanded(
            flex: 2,
            child: TextButton(
              onPressed: onView,
              child: Text('VIEW',
                  style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            )),
      ]),
    );
  }
}

// ─── Order Detail Dialog ──────────────────────────────────────────────────────
class _OrderDetailDialog extends StatefulWidget {
  final String orderId;
  const _OrderDetailDialog({required this.orderId});

  @override
  State<_OrderDetailDialog> createState() =>
      _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  Map<String, dynamic>? _order;
  bool _loading = true;

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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 600, maxHeight: 640),
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
            : _order == null
                ? const Center(child: Text('Order not found'))
                : Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text('Order Details',
                            style: GoogleFonts.newsreader(
                                fontSize: 24,
                                fontWeight: FontWeight.w400)),
                        const Spacer(),
                        StatusChip(_order!['status'] ?? 'pending'),
                        const SizedBox(width: 12),
                        IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                Navigator.pop(context)),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                          'ID: ${_order!['id']?.toString().substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 20),
                      // Customer info
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppColors.surfaceLow,
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text('CUSTOMER',
                              style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          _InfoRow('Name',
                              _order!['customers']?['full_name'] ??
                                  '—'),
                          _InfoRow('Phone',
                              _order!['customers']?['phone'] ?? '—'),
                          _InfoRow('Address',
                              _order!['customers']?['address'] ??
                                  '—'),
                          if (_order!['customers']?['email'] != null)
                            _InfoRow('Email',
                                _order!['customers']!['email']),
                          if (_order!['note'] != null)
                            _InfoRow('Note', _order!['note']),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Text('ITEMS',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(children: [
                          ...(_order!['order_items']
                                      as List<dynamic>? ??
                                  [])
                              .map((item) {
                            final product = item['products'];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(2),
                                  child: SizedBox(
                                    width: 48,
                                    height: 56,
                                    child: product?['image_url'] !=
                                            null
                                        ? Image.network(
                                            product!['image_url'],
                                            fit: BoxFit.cover)
                                        : Container(
                                            color:
                                                AppColors.surfaceLow),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                  Text(product?['name'] ?? '—',
                                      style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Qty: ${item['quantity']}  ×  ৳ ${(item['unit_price'] ?? 0).toStringAsFixed(0)}',
                                      style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppColors
                                              .onSurfaceVariant)),
                                ])),
                                Text(
                                    '৳ ${((item['unit_price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                                    style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            );
                          }),
                          Container(
                              height: 1,
                              color: AppColors.outlineVariant
                                  .withOpacity(0.3)),
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                            Text('Total',
                                style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '৳ ${(_order!['total_amount'] ?? 0).toStringAsFixed(0)}',
                                style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 68,
              child: Text(label,
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface))),
        ]),
      );
}
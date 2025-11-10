import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as app_order;
import '../../utils/app_theme.dart';

class SHGMyPurchasesScreen extends StatefulWidget {
  const SHGMyPurchasesScreen({super.key});

  @override
  State<SHGMyPurchasesScreen> createState() => _SHGMyPurchasesScreenState();
}

class _SHGMyPurchasesScreenState extends State<SHGMyPurchasesScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final shgId = authProvider.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Purchases'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(shgId, [app_order.OrderStatus.pending]),
          _buildOrdersList(shgId, [
            app_order.OrderStatus.confirmed,
            app_order.OrderStatus.preparing,
            app_order.OrderStatus.ready,
            app_order.OrderStatus.inTransit,
            app_order.OrderStatus.delivered,
          ]),
          _buildOrdersList(shgId, [
            app_order.OrderStatus.completed,
            app_order.OrderStatus.rejected,
            app_order.OrderStatus.cancelled,
          ]),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String shgId, List<app_order.OrderStatus> statusFilter) {
    return StreamBuilder<List<app_order.Order>>(
      stream: _orderService.streamBuyerOrders(shgId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var orders = snapshot.data ?? [];

        // Apply status filter
        orders = orders.where((order) => statusFilter.contains(order.status)).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your input purchases will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(app_order.Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetailsDialog(order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatus(order.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // PSA Seller Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.store, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PSA Supplier',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          order.farmerName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (order.farmerPhone?.isNotEmpty ?? false)
                          Text(
                            order.farmerPhone ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order Items Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_basket, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${order.items.length} item(s)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Text(
                      'UGX ${NumberFormat('#,###').format(order.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Confirm Receipt Button (for delivered orders)
              if (order.status == app_order.OrderStatus.delivered && !(order.isReceivedByBuyer ?? false)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _confirmReceipt(order),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Confirm Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReceipt(app_order.Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Confirm Receipt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Have you received this order in good condition?'),
            const SizedBox(height: 16),
            const Text('By confirming:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('✅ Order will be marked as completed'),
            const Text('✅ Product stock will be updated'),
            const Text('✅ Receipt will be generated'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await _orderService.confirmReceipt(order.id);
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Order confirmed! Stock has been updated.'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _showReceipt(order);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error confirming receipt: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showReceipt(app_order.Order order) {
    final receipt = _generateReceipt(order);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Order Receipt'),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              receipt,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receipt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _generateReceipt(app_order.Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('   SAYEKATALE MARKETPLACE');
    buffer.writeln('          RECEIPT');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('Order ID: ${order.id}');
    buffer.writeln('Date: ${dateFormat.format(order.createdAt)}');
    buffer.writeln('Status: ${_formatStatus(order.status)}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('PSA SUPPLIER DETAILS');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Name: ${order.farmerName}');
    if (order.farmerPhone?.isNotEmpty ?? false) {
      buffer.writeln('Phone: ${order.farmerPhone}');
    }
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('BUYER DETAILS (SHG)');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Name: ${order.buyerName}');
    buffer.writeln('Phone: ${order.buyerPhone}');
    if (order.deliveryAddress != null) {
      buffer.writeln('Address: ${order.deliveryAddress}');
    }
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('ORDER ITEMS');
    buffer.writeln('───────────────────────────────────');

    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      buffer.writeln('${i + 1}. ${item.productName}');
      buffer.writeln('   ${item.quantity} ${item.unit} × UGX ${NumberFormat('#,###').format(item.price)}');
      buffer.writeln('   Subtotal: UGX ${NumberFormat('#,###').format(item.subtotal)}');
      buffer.writeln('');
    }

    buffer.writeln('───────────────────────────────────');
    buffer.writeln('TOTAL: UGX ${NumberFormat('#,###').format(order.totalAmount)}');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('');
    buffer.writeln('Payment: ${_formatPaymentMethod(order.paymentMethod)}');
    buffer.writeln('');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('ORDER TIMELINE');
    buffer.writeln('───────────────────────────────────');
    buffer.writeln('Placed: ${dateFormat.format(order.createdAt)}');
    if (order.confirmedAt != null) {
      buffer.writeln('Confirmed: ${dateFormat.format(order.confirmedAt!)}');
    }
    if (order.deliveredAt != null) {
      buffer.writeln('Delivered: ${dateFormat.format(order.deliveredAt!)}');
    }
    if (order.receivedAt != null) {
      buffer.writeln('Received: ${dateFormat.format(order.receivedAt!)}');
    }
    buffer.writeln('');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('Thank you for your business!');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  void _showOrderDetailsDialog(app_order.Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Order ID
                _buildDetailRow('Order ID', '#${order.id.substring(0, 12).toUpperCase()}'),
                _buildDetailRow('Date', DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)),
                _buildDetailRow('Status', _formatStatus(order.status)),

                const SizedBox(height: 16),
                const Text(
                  'PSA Supplier Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Name', order.farmerName ?? 'Unknown'),
                if (order.farmerPhone?.isNotEmpty ?? false)
                  _buildDetailRow('Phone', order.farmerPhone ?? ''),

                if (order.deliveryAddress != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Address', order.deliveryAddress!),
                  if (order.deliveryNotes != null)
                    _buildDetailRow('Notes', order.deliveryNotes!),
                ],

                const SizedBox(height: 16),
                const Text(
                  'Order Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                ...order.items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.productImage ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${item.quantity} ${item.unit} × UGX ${NumberFormat('#,###').format(item.price)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'UGX ${NumberFormat('#,###').format(item.subtotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )),

                const Divider(),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'UGX ${NumberFormat('#,###').format(order.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                _buildDetailRow('Payment Method', _formatPaymentMethod(order.paymentMethod)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Colors.orange;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.preparing:
      case app_order.OrderStatus.paymentHeld:
        return Colors.blue;
      case app_order.OrderStatus.ready:
      case app_order.OrderStatus.inTransit:
      case app_order.OrderStatus.deliveryPending:
        return Colors.purple;
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.deliveredPendingConfirmation:
      case app_order.OrderStatus.codPendingBothConfirmation:
        return Colors.deepPurple;
      case app_order.OrderStatus.completed:
        return Colors.green;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.rejected:
      case app_order.OrderStatus.codOverdue:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Icons.pending;
      case app_order.OrderStatus.confirmed:
        return Icons.check_circle;
      case app_order.OrderStatus.preparing:
        return Icons.inventory;
      case app_order.OrderStatus.paymentHeld:
        return Icons.lock;
      case app_order.OrderStatus.ready:
        return Icons.done_all;
      case app_order.OrderStatus.inTransit:
      case app_order.OrderStatus.deliveryPending:
        return Icons.local_shipping;
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.deliveredPendingConfirmation:
      case app_order.OrderStatus.codPendingBothConfirmation:
        return Icons.check_circle_outline;
      case app_order.OrderStatus.completed:
        return Icons.verified;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.rejected:
      case app_order.OrderStatus.codOverdue:
        return Icons.cancel;
    }
  }

  String _formatStatus(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Pending';
      case app_order.OrderStatus.paymentPending:
        return 'Payment Pending';
      case app_order.OrderStatus.paymentHeld:
        return 'Payment Secured';
      case app_order.OrderStatus.confirmed:
        return 'Confirmed';
      case app_order.OrderStatus.rejected:
        return 'Rejected';
      case app_order.OrderStatus.preparing:
        return 'Preparing';
      case app_order.OrderStatus.ready:
        return 'Ready';
      case app_order.OrderStatus.inTransit:
        return 'In Transit';
      case app_order.OrderStatus.deliveryPending:
        return 'Delivery Pending';
      case app_order.OrderStatus.delivered:
        return 'Delivered';
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return 'Awaiting Confirmation';
      case app_order.OrderStatus.codPendingBothConfirmation:
        return 'COD - Both Confirm';
      case app_order.OrderStatus.codOverdue:
        return 'COD Overdue';
      case app_order.OrderStatus.completed:
        return 'Completed';
      case app_order.OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatPaymentMethod(app_order.PaymentMethod method) {
    switch (method) {
      case app_order.PaymentMethod.cash:
      case app_order.PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case app_order.PaymentMethod.mobileMoney:
      case app_order.PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
      case app_order.PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case app_order.PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

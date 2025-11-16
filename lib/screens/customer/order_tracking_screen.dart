import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/app_theme.dart';

/// Screen for tracking order status in real-time
class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';

    if (userId.isEmpty) {
      return const Center(child: Text('Please log in to view your orders'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.streamBuyerOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading orders: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order),
              ],
            ),
            const SizedBox(height: 12),

            // Farmer info
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Farmer: ${order.farmerName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order.farmerPhone ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'Total: UGX ${order.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered: ${_formatDate(order.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),

            if (order.deliveredAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Delivered: ${_formatDate(order.deliveredAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (order.receivedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '✅ Received: ${_formatDate(order.receivedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            _buildOrderItems(order.items),

            // Confirm Receipt Button
            if (order.status == OrderStatus.delivered &&
                !(order.isReceivedByBuyer ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _confirmReceipt(order),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

            // View Receipt Button
            if (order.isReceivedByBuyer ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceipt(order),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
    Color color;
    String label;
    IconData? icon;

    if (order.isReceivedByBuyer ?? false) {
      color = Colors.green;
      label = '✅ Received';
      icon = Icons.check_circle;
    } else {
      switch (order.status) {
        case OrderStatus.pending:
        case OrderStatus.paymentPending:
          color = Colors.orange;
          label = 'Pending';
          icon = Icons.access_time;
          break;
        case OrderStatus.confirmed:
          color = Colors.blue;
          label = 'Confirmed';
          icon = Icons.thumb_up;
          break;
        case OrderStatus.preparing:
          color = Colors.purple;
          label = 'Preparing';
          icon = Icons.kitchen;
          break;
        case OrderStatus.paymentHeld:
          color = Colors.blue;
          label = 'Payment Secured';
          icon = Icons.lock;
          break;
        case OrderStatus.ready:
          color = Colors.teal;
          label = 'Ready';
          icon = Icons.done_all;
          break;
        case OrderStatus.inTransit:
        case OrderStatus.deliveryPending:
          color = Colors.indigo;
          label = 'In Transit';
          icon = Icons.local_shipping;
          break;
        case OrderStatus.delivered:
        case OrderStatus.deliveredPendingConfirmation:
        case OrderStatus.codPendingBothConfirmation:
          color = Colors.green;
          label = 'Delivered';
          icon = Icons.inventory_2;
          break;
        case OrderStatus.completed:
          color = Colors.green;
          label = 'Completed';
          icon = Icons.check_circle;
          break;
        case OrderStatus.rejected:
        case OrderStatus.codOverdue:
          color = Colors.red;
          label = 'Rejected';
          icon = Icons.cancel;
          break;
        case OrderStatus.cancelled:
          color = Colors.grey;
          label = 'Cancelled';
          icon = Icons.block;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.productName} × ${item.quantity} ${item.unit}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  'UGX ${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReceipt(Order order) async {
    // Show confirmation dialog
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
            const Text(
              'By confirming:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      try {
        // Confirm receipt (reduces stock automatically)
        await _orderService.confirmReceipt(order.id);

        if (mounted) {
          setState(() => _isProcessing = false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('✅ Order confirmed! Stock has been updated.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Show receipt immediately
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showReceipt(order);
          }
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

  void _showReceipt(Order order) {
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
          child: SelectableText(
            receipt,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
                  content: Text('📋 Receipt copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _generateReceipt(Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return '''
═══════════════════════════════════
   SAYEKATALE MARKETPLACE
          RECEIPT
═══════════════════════════════════

Order ID: ${order.id}
Date: ${dateFormat.format(order.createdAt)}

───────────────────────────────────
FARMER DETAILS:
───────────────────────────────────
Name: ${order.farmerName}
Phone: ${order.farmerPhone}

───────────────────────────────────
BUYER DETAILS:
───────────────────────────────────
Name: ${order.buyerName}
Phone: ${order.buyerPhone}
${'\nAddress:\n${order.deliveryAddress}'}

═══════════════════════════════════
ITEMS ORDERED:
═══════════════════════════════════
${order.items.map((item) {
      final subtotal = item.price * item.quantity;
      return '''
${item.productName}
  ${item.quantity} ${item.unit} × UGX ${item.price.toStringAsFixed(0)}
  Subtotal: UGX ${subtotal.toStringAsFixed(0)}
''';
    }).join('\n')}
───────────────────────────────────
TOTAL AMOUNT: UGX ${order.totalAmount.toStringAsFixed(0)}
═══════════════════════════════════

Payment Method: ${_getPaymentMethodName(order.paymentMethod)}

───────────────────────────────────
ORDER TIMELINE:
───────────────────────────────────
Placed:    ${dateFormat.format(order.createdAt)}
${order.confirmedAt != null ? 'Confirmed: ${dateFormat.format(order.confirmedAt!)}' : ''}
${order.deliveredAt != null ? 'Delivered: ${dateFormat.format(order.deliveredAt!)}' : ''}
${order.receivedAt != null ? 'Received:  ${dateFormat.format(order.receivedAt!)}' : ''}

${(order.isReceivedByBuyer ?? false) ? '''
═══════════════════════════════════
✅ ORDER COMPLETED
═══════════════════════════════════
Received by: ${order.buyerName}
Received on: ${dateFormat.format(order.receivedAt!)}
''' : ''}

═══════════════════════════════════
  Thank you for using Sayekatale!
═══════════════════════════════════
''';
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.mobileMoney:
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

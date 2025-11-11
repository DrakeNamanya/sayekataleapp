import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/message_service.dart';
import '../../services/delivery_tracking_service.dart';
import '../../models/order.dart' as app_order;
import '../common/chat_screen.dart';
import '../delivery/live_tracking_screen.dart';
import 'order_review_screen.dart';

class SMEOrdersScreen extends StatefulWidget {
  const SMEOrdersScreen({super.key});

  @override
  State<SMEOrdersScreen> createState() => _SMEOrdersScreenState();
}

class _SMEOrdersScreenState extends State<SMEOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final MessageService _messageService = MessageService();
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  late TabController _tabController;

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
    final buyerId = authProvider.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Pending'),
            Tab(icon: Icon(Icons.local_shipping), text: 'In Progress'),
            Tab(icon: Icon(Icons.history), text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(buyerId, [
            app_order.OrderStatus.pending,
          ]),
          _buildOrdersList(buyerId, [
            app_order.OrderStatus.confirmed,
            app_order.OrderStatus.preparing,
            app_order.OrderStatus.ready,
            app_order.OrderStatus.inTransit,
          ]),
          _buildOrdersList(buyerId, [
            app_order.OrderStatus.completed,
            app_order.OrderStatus.rejected,
            app_order.OrderStatus.cancelled,
          ]),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String buyerId, List<app_order.OrderStatus> statusFilter) {
    return StreamBuilder<List<app_order.Order>>(
      stream: _orderService.streamBuyerOrders(buyerId),
      builder: (context, snapshot) {
        // Debug logging
        if (kDebugMode) {
          debugPrint('📊 SME Orders - Connection: ${snapshot.connectionState}');
          debugPrint('📊 SME Orders - Has Error: ${snapshot.hasError}');
          debugPrint('📊 SME Orders - Data: ${snapshot.data?.length ?? 0} orders');
          debugPrint('📊 SME Orders - Status Filter: ${statusFilter.map((s) => s.toString()).join(", ")}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading orders...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            debugPrint('❌ SME Orders Error: ${snapshot.error}');
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(fontSize: 18, color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          );
        }

        var orders = snapshot.data ?? [];
        if (kDebugMode) {
          debugPrint('📦 Total orders fetched: ${orders.length}');
        }

        orders = orders.where((order) => statusFilter.contains(order.status)).toList();
        if (kDebugMode) {
          debugPrint('📦 After status filter: ${orders.length}');
        }

        if (orders.isEmpty) {
          return Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to place orders',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filtered by: ${statusFilter.map((s) => _formatStatus(s)).join(", ")}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
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
              
              // Farmer Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.agriculture, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.farmerName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
              
              // Status Message
              if (order.status == app_order.OrderStatus.pending) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waiting for farmer confirmation',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (order.status == app_order.OrderStatus.rejected && order.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejected: ${order.rejectionReason}',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Track Delivery Button (for orders in transit)
              if (order.status == app_order.OrderStatus.confirmed || 
                  order.status == app_order.OrderStatus.preparing ||
                  order.status == app_order.OrderStatus.ready ||
                  order.status == app_order.OrderStatus.inTransit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _trackDelivery(order),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Track Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Rate Order Button (for delivered orders without review)
              if (order.status == app_order.OrderStatus.delivered && 
                  (order.isReceivedByBuyer ?? false) && 
                  order.rating == null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToReviewScreen(order),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Rate This Order'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Already Reviewed Badge
              if (order.rating != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You rated this order ${order.rating} star${order.rating! > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Track delivery for order
  Future<void> _trackDelivery(app_order.Order order) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get delivery tracking
      final tracking = await _trackingService.getDeliveryTrackingByOrderId(order.id);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (tracking == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Delivery tracking not available yet.\n\n'
                'This could be because:\n'
                '• The farmer hasn\'t confirmed your order yet\n'
                '• GPS coordinates are missing from your profile or the farmer\'s profile\n\n'
                '📍 To enable tracking: Go to Profile → Edit Profile → Add your GPS location\n\n'
                'Please check back after the order is confirmed.',
              ),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Got it',
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      // Navigate to live tracking
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTrackingScreen(trackingId: tracking.id),
          ),
        );
      }
    } catch (e) {
      // Close loading if open
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to review screen and refresh on return
  Future<void> _navigateToReviewScreen(app_order.Order order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(order: order),
      ),
    );
    
    // Refresh orders list if review was submitted
    if (result == true && mounted) {
      setState(() {}); // Trigger rebuild to fetch updated orders
    }
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
                
                _buildDetailRow('Order ID', '#${order.id.substring(0, 12).toUpperCase()}'),
                _buildDetailRow('Date', DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt)),
                _buildDetailRow('Status', _formatStatus(order.status)),
                
                const SizedBox(height: 16),
                const Text(
                  'Farmer Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Name', order.farmerName ?? 'Unknown'),
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
                
                if (order.status == app_order.OrderStatus.rejected && order.rejectionReason != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(order.rejectionReason!),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                // Contact Seller Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleContactSeller(order),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Contact Seller'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContactSeller(app_order.Order order) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to contact seller'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Close order details dialog
      Navigator.pop(context);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get conversation
      final conversation = await _messageService.getOrCreateConversation(
        user1Id: currentUser.id,
        user1Name: currentUser.name,
        user2Id: order.farmerId ?? order.sellerId,
        user2Name: order.farmerName ?? 'Seller',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: order.farmerId ?? order.sellerId,
              otherUserName: order.farmerName ?? 'Seller',
              currentUserId: currentUser.id,
              currentUserName: currentUser.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        return Icons.restaurant;
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

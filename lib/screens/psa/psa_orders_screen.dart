import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as app_order;

class PSAOrdersScreen extends StatefulWidget {
  const PSAOrdersScreen({super.key});

  @override
  State<PSAOrdersScreen> createState() => _PSAOrdersScreenState();
}

class _PSAOrdersScreenState extends State<PSAOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  final List<String> _statusFilters = ['All', 'Pending', 'Confirmed', 'Preparing', 'Ready', 'Delivered', 'Completed'];
  String _selectedFilter = 'All';

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
    final psaId = authProvider.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildRevenueCard(psaId),
          _buildFilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(psaId, [
                  app_order.OrderStatus.pending,
                ]),
                _buildOrdersList(psaId, [
                  app_order.OrderStatus.confirmed,
                  app_order.OrderStatus.preparing,
                  app_order.OrderStatus.ready,
                  app_order.OrderStatus.inTransit,
                ]),
                _buildOrdersList(psaId, [
                  app_order.OrderStatus.delivered,
                  app_order.OrderStatus.completed,
                  app_order.OrderStatus.cancelled,
                  app_order.OrderStatus.rejected,
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String psaId) {
    return FutureBuilder<double>(
      future: _orderService.getFarmerRevenue(psaId),
      builder: (context, snapshot) {
        final revenue = snapshot.data ?? 0.0;
        return Container(
          height: 100,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${NumberFormat('#,###').format(revenue)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(String psaId, List<app_order.OrderStatus> statusFilter) {
    return StreamBuilder<List<app_order.Order>>(
      stream: _orderService.streamFarmerOrders(psaId),
      builder: (context, snapshot) {
        // Debug logging
        if (kDebugMode) {
          debugPrint('📊 PSA Orders - Connection: ${snapshot.connectionState}');
          debugPrint('📊 PSA Orders - Has Error: ${snapshot.hasError}');
          debugPrint('📊 PSA Orders - Data: ${snapshot.data?.length ?? 0} orders');
          debugPrint('📊 PSA Orders - Status Filter: ${statusFilter.map((s) => s.toString()).join(", ")}');
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
            debugPrint('❌ PSA Orders Error: ${snapshot.error}');
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

        // Apply status filter
        orders = orders.where((order) => statusFilter.contains(order.status)).toList();
        if (kDebugMode) {
          debugPrint('📦 After status filter: ${orders.length}');
        }

        // Apply chip filter
        if (_selectedFilter != 'All') {
          final filterStatus = app_order.OrderStatus.values.firstWhere(
            (s) => s.toString().split('.').last.toLowerCase() == _selectedFilter.toLowerCase(),
            orElse: () => app_order.OrderStatus.pending,
          );
          orders = orders.where((order) => order.status == filterStatus).toList();
          if (kDebugMode) {
            debugPrint('📦 After chip filter ($_selectedFilter): ${orders.length}');
          }
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
                    'Orders from SHG buyers will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All' 
                        ? 'Filtered by: ${statusFilter.map((s) => _formatStatus(s)).join(", ")}'
                        : 'Filter: $_selectedFilter',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
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

              // SHG Buyer Info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.groups, color: Colors.green[800]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SHG Buyer',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          order.buyerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          order.buyerPhone,
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
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (order.status == app_order.OrderStatus.pending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectOrder(order),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmOrder(order),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Accept Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (order.status == app_order.OrderStatus.confirmed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, app_order.OrderStatus.preparing),
                    icon: const Icon(Icons.inventory, size: 18),
                    label: const Text('Mark as Preparing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (order.status == app_order.OrderStatus.preparing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, app_order.OrderStatus.ready),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark as Ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (order.status == app_order.OrderStatus.ready) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, app_order.OrderStatus.inTransit),
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Mark as In Transit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (order.status == app_order.OrderStatus.inTransit) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(order, app_order.OrderStatus.delivered),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Mark as Delivered'),
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
                  'SHG Buyer Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Name', order.buyerName),
                _buildDetailRow('Phone', order.buyerPhone),

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
                          color: Colors.blue,
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
                        color: Colors.blue,
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

  Future<void> _confirmOrder(app_order.Order order) async {
    try {
      await _orderService.confirmOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(app_order.Order order) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Out of stock, Cannot deliver to location',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _orderService.rejectOrder(
          order.id,
          reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : 'No reason provided',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(app_order.Order order, app_order.OrderStatus newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Order status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Colors.orange;
      case app_order.OrderStatus.paymentHeld:
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.preparing:
        return Colors.blue;
      case app_order.OrderStatus.deliveryPending:
      case app_order.OrderStatus.ready:
      case app_order.OrderStatus.inTransit:
        return Colors.purple;
      case app_order.OrderStatus.deliveredPendingConfirmation:
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.completed:
        return Colors.green;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.rejected:
        return Colors.red;
      case app_order.OrderStatus.codPendingBothConfirmation:
      case app_order.OrderStatus.codOverdue:
        return Colors.deepOrange;
    }
  }

  IconData _getStatusIcon(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.paymentPending:
        return Icons.pending;
      case app_order.OrderStatus.paymentHeld:
        return Icons.lock;
      case app_order.OrderStatus.confirmed:
        return Icons.check_circle;
      case app_order.OrderStatus.preparing:
        return Icons.inventory;
      case app_order.OrderStatus.deliveryPending:
      case app_order.OrderStatus.ready:
        return Icons.done_all;
      case app_order.OrderStatus.inTransit:
        return Icons.local_shipping;
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return Icons.assignment_turned_in;
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.completed:
        return Icons.check_circle_outline;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.rejected:
        return Icons.cancel;
      case app_order.OrderStatus.codPendingBothConfirmation:
      case app_order.OrderStatus.codOverdue:
        return Icons.warning;
    }
  }

  String _formatStatus(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Pending';
      case app_order.OrderStatus.paymentPending:
        return 'Payment Pending';
      case app_order.OrderStatus.paymentHeld:
        return 'Payment Held';
      case app_order.OrderStatus.deliveryPending:
        return 'Delivery Pending';
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return 'Delivered - Pending Confirmation';
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
      case app_order.OrderStatus.delivered:
        return 'Delivered';
      case app_order.OrderStatus.completed:
        return 'Completed';
      case app_order.OrderStatus.cancelled:
        return 'Cancelled';
      case app_order.OrderStatus.codPendingBothConfirmation:
        return 'COD - Pending Confirmation';
      case app_order.OrderStatus.codOverdue:
        return 'COD - Overdue';
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

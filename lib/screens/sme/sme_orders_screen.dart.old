import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';
import 'sme_order_detail_screen.dart';

class SMEOrdersScreen extends StatefulWidget {
  const SMEOrdersScreen({super.key});

  @override
  State<SMEOrdersScreen> createState() => _SMEOrdersScreenState();
}

class _SMEOrdersScreenState extends State<SMEOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Mock orders - In production, fetch from Firebase
  final List<Order> _mockOrders = [
    Order(
      id: 'ORD-00001',
      customerId: 'SME-00001',
      farmId: 'SHG-00001',
      items: [
        OrderItem(
          productId: 'prod1',
          productName: 'Fresh Onions',
          quantity: 50,
          unitPrice: 3000.0,
          total: 150000.0,
        ),
        OrderItem(
          productId: 'prod2',
          productName: 'Ripe Tomatoes',
          quantity: 30,
          unitPrice: 2500.0,
          total: 75000.0,
        ),
      ],
      subtotal: 225000.0,
      deliveryFee: 15000.0,
      serviceFee: 5000.0,
      total: 245000.0,
      paymentMethod: PaymentMethod.mtnMomo,
      paymentStatus: PaymentStatus.completed,
      statusTimeline: [
        OrderStatusTimeline(
          status: OrderStatus.placed,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.accepted,
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.preparing,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
      ],
      estimatedDelivery: 'Today, 5:00 PM',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    ),
    Order(
      id: 'ORD-00002',
      customerId: 'SME-00001',
      farmId: 'SHG-00002',
      items: [
        OrderItem(
          productId: 'prod3',
          productName: 'Broiler Chicken',
          quantity: 20,
          unitPrice: 18000.0,
          total: 360000.0,
        ),
      ],
      subtotal: 360000.0,
      deliveryFee: 20000.0,
      serviceFee: 8000.0,
      total: 388000.0,
      paymentMethod: PaymentMethod.airtelMoney,
      paymentStatus: PaymentStatus.completed,
      statusTimeline: [
        OrderStatusTimeline(
          status: OrderStatus.placed,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.accepted,
          timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.preparing,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.ready,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.outForDelivery,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
      estimatedDelivery: 'Today, 3:30 PM',
      riderId: 'RDR-001',
      riderName: 'John Mugisha',
      riderPhone: '+256700111222',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Order(
      id: 'ORD-00003',
      customerId: 'SME-00001',
      farmId: 'SHG-00003',
      items: [
        OrderItem(
          productId: 'prod6',
          productName: 'Male Goats',
          quantity: 3,
          unitPrice: 250000.0,
          total: 750000.0,
        ),
      ],
      subtotal: 750000.0,
      deliveryFee: 50000.0,
      serviceFee: 15000.0,
      total: 815000.0,
      paymentMethod: PaymentMethod.cash,
      paymentStatus: PaymentStatus.pending,
      statusTimeline: [
        OrderStatusTimeline(
          status: OrderStatus.placed,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.accepted,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: -2)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.preparing,
          timestamp: DateTime.now().subtract(const Duration(hours: 18)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.ready,
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.outForDelivery,
          timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        OrderStatusTimeline(
          status: OrderStatus.delivered,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      estimatedDelivery: null,
      riderId: 'RDR-002',
      riderName: 'Peter Ssemwanga',
      riderPhone: '+256700333444',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
  
  List<Order> get _activeOrders {
    return _mockOrders.where((order) {
      return order.currentStatus != OrderStatus.delivered &&
             order.currentStatus != OrderStatus.cancelled;
    }).toList();
  }
  
  List<Order> get _completedOrders {
    return _mockOrders.where((order) {
      return order.currentStatus == OrderStatus.delivered;
    }).toList();
  }
  
  List<Order> get _cancelledOrders {
    return _mockOrders.where((order) {
      return order.currentStatus == OrderStatus.cancelled;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'All (${_mockOrders.length})'),
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'Completed (${_completedOrders.length})'),
            Tab(text: 'Cancelled (${_cancelledOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(orders: _mockOrders),
          _OrdersList(orders: _activeOrders),
          _OrdersList(orders: _completedOrders),
          _OrdersList(orders: _cancelledOrders),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Order> orders;
  
  const _OrdersList({required this.orders});
  
  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
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
        return _OrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  
  const _OrderCard({required this.order});
  
  Color get _statusColor {
    switch (order.currentStatus) {
      case OrderStatus.placed:
      case OrderStatus.accepted:
        return AppTheme.warningColor;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return AppTheme.primaryColor;
      case OrderStatus.outForDelivery:
        return Colors.blue;
      case OrderStatus.delivered:
        return AppTheme.successColor;
      case OrderStatus.cancelled:
        return AppTheme.errorColor;
    }
  }
  
  IconData get _statusIcon {
    switch (order.currentStatus) {
      case OrderStatus.placed:
        return Icons.receipt;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.inventory;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SMEOrderDetailScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_statusIcon, color: _statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.currentStatus.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              // Order Items
              Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'UGX ${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 8),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'UGX ${order.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              // Delivery Info
              if (order.currentStatus == OrderStatus.outForDelivery ||
                  order.currentStatus == OrderStatus.delivered)
                ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.riderName ?? 'Delivery in progress',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (order.riderPhone != null)
                                Text(
                                  order.riderPhone!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (order.riderPhone != null)
                          IconButton(
                            icon: const Icon(Icons.phone, size: 20),
                            onPressed: () {
                              // Call rider
                            },
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                ],
              
              // View Details Button
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SMEOrderDetailScreen(order: order),
                      ),
                    );
                  },
                  child: const Text('View Order Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} minutes ago';
      }
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

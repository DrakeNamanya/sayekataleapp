import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/message_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../utils/app_theme.dart';
import '../../models/order.dart' as app_order;
import '../../models/product.dart';
import 'psa_products_screen.dart';
import 'psa_orders_screen.dart';
import 'psa_customers_screen.dart';
import 'psa_inventory_screen.dart';
import 'psa_delivery_screen.dart';
import 'psa_financial_screen.dart';
import 'psa_messages_screen.dart';
import 'psa_profile_screen.dart';
import 'psa_notifications_screen.dart';
import '../delivery/delivery_control_screen.dart';

class PSADashboardScreen extends StatefulWidget {
  const PSADashboardScreen({super.key});

  @override
  State<PSADashboardScreen> createState() => _PSADashboardScreenState();
}

class _PSADashboardScreenState extends State<PSADashboardScreen> {
  int _selectedIndex = 0;
  int _unreadNotifications = 7;
  int _unreadMessages = 4;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _DashboardHome(),
      const PSAProductsScreen(),
      const PSAOrdersScreen(),
      const PSAInventoryScreen(),
      const PSAProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final supplierId = authProvider.currentUser?.id ?? '';
    final orderService = OrderService();

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: FutureBuilder<int>(
        future: orderService.getFarmerPendingOrdersCount(supplierId),
        builder: (context, snapshot) {
          final pendingOrders = snapshot.data ?? 0;
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: pendingOrders > 0
                    ? Badge(
                        label: Text('$pendingOrders'),
                        child: const Icon(Icons.shopping_bag_outlined),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                activeIcon: pendingOrders > 0
                    ? Badge(
                        label: Text('$pendingOrders'),
                        child: const Icon(Icons.shopping_bag),
                      )
                    : const Icon(Icons.shopping_bag),
                label: 'Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.inventory_outlined),
                activeIcon: Icon(Icons.inventory),
                label: 'Inventory',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  // Real data from Firebase
  double _todayRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  int _activeOrders = 0;
  int _totalProducts = 0;
  int _lowStockItems = 0;
  int _deliveryPending = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRealStats();
    });
  }

  Future<void> _loadRealStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supplierId = authProvider.currentUser?.id;

    if (supplierId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final orderService = OrderService();
      final productService = ProductService();

      // Load all stats in parallel
      final results = await Future.wait([
        orderService.getFarmerTodayEarnings(supplierId),
        orderService.getFarmerRevenue(supplierId), // Monthly is actually total
        orderService.getFarmerActiveOrdersCount(supplierId),
        productService.getFarmerProductsCount(supplierId),
        productService.getFarmerLowStockCount(supplierId),
        orderService.getFarmerActiveOrdersCount(supplierId), // Using active as pending delivery
      ]);

      if (mounted) {
        setState(() {
          _todayRevenue = results[0] as double;
          _monthlyRevenue = results[1] as double;
          _activeOrders = results[2] as int;
          _totalProducts = results[3] as int;
          _lowStockItems = results[4] as int;
          _deliveryPending = results[5] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final notificationService = NotificationService();
    final messageService = MessageService();
    final orderService = OrderService();
    final userId = user?.id ?? '';

    // Use real data
    final todayRevenue = _todayRevenue;
    final monthlyRevenue = _monthlyRevenue;
    final activeOrders = _activeOrders;
    final totalProducts = _totalProducts;
    final lowStockItems = _lowStockItems;
    final deliveryPending = _deliveryPending;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supplier Dashboard',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? 'Supplier',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                StreamBuilder<int>(
                                  stream: notificationService.streamUnreadCount(userId),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data ?? 0;
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const PSANotificationsScreen()),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                StreamBuilder<int>(
                                  stream: messageService.streamTotalUnreadCount(userId),
                                  builder: (context, snapshot) {
                                    final unreadCount = snapshot.data ?? 0;
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.message_outlined, color: Colors.white),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const PSAMessagesScreen()),
                                            );
                                          },
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Today\'s Revenue',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UGX ${todayRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                label: 'Monthly',
                                value: 'UGX ${(monthlyRevenue / 1000000).toStringAsFixed(1)}M',
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStatCard(
                                label: 'Active Orders',
                                value: activeOrders.toString(),
                                icon: Icons.shopping_bag,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Products',
                          value: totalProducts.toString(),
                          icon: Icons.inventory_2,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Low Stock',
                          value: lowStockItems.toString(),
                          icon: Icons.warning_amber,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Pending Delivery',
                          value: deliveryPending.toString(),
                          icon: Icons.local_shipping,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Active Orders',
                          value: activeOrders.toString(),
                          icon: Icons.shopping_bag,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_business,
                          label: 'Add Product',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PSAProductsScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.inventory,
                          label: 'Inventory',
                          color: AppTheme.secondaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PSAInventoryScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.people,
                          label: 'Customers',
                          color: Colors.purple.shade600,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PSACustomersScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.local_shipping,
                          label: 'My Deliveries',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeliveryControlScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Alerts Section
                  if (lowStockItems > 0 || deliveryPending > 0) ...[
                    const Text(
                      'Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (lowStockItems > 0)
                      _AlertCard(
                        icon: Icons.warning_amber,
                        title: 'Low Stock Items',
                        subtitle: '$lowStockItems products need restocking',
                        color: AppTheme.warningColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PSAInventoryScreen()),
                          );
                        },
                      ),
                    if (deliveryPending > 0)
                      _AlertCard(
                        icon: Icons.local_shipping,
                        title: 'Pending Deliveries',
                        subtitle: '$deliveryPending orders awaiting dispatch',
                        color: Colors.blue.shade600,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PSADeliveryScreen()),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Recent Orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PSAOrdersScreen()),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<app_order.Order>>(
                    future: orderService.getFarmerRecentOrders(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error loading recent orders: ${snapshot.error}'),
                        );
                      }

                      final recentOrders = snapshot.data ?? [];

                      if (recentOrders.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No recent orders in the last 24 hours',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: recentOrders.take(3).map((order) {
                          return _OrderCard(
                            orderId: '#${order.id.substring(0, 8)}',
                            customerName: order.buyerName,
                            products: order.items.map((item) => item.productName).take(2).join(', '),
                            amount: order.totalAmount,
                            status: order.status.toString().split('.').last,
                            statusColor: _getStatusColor(order.status),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
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
        return AppTheme.warningColor;
      case app_order.OrderStatus.confirmed:
      case app_order.OrderStatus.preparing:
        return AppTheme.primaryColor;
      case app_order.OrderStatus.ready:
      case app_order.OrderStatus.inTransit:
        return Colors.blue;
      case app_order.OrderStatus.delivered:
      case app_order.OrderStatus.completed:
        return AppTheme.successColor;
      case app_order.OrderStatus.cancelled:
      case app_order.OrderStatus.rejected:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}

// Mini stat card for header
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick action card
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Alert card
class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// Order card
class _OrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String products;
  final double amount;
  final String status;
  final Color statusColor;

  const _OrderCard({
    required this.orderId,
    required this.customerName,
    required this.products,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  customerName,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    products,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Amount',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'UGX ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

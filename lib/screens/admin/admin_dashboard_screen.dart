import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/admin_auth_service.dart';
import '../../models/admin_user.dart';
import 'psa_verification_screen.dart';
import 'user_management_screen.dart';
import 'product_moderation_screen.dart';
import 'order_management_screen.dart';
import 'admin_analytics_dashboard.dart';
import 'complaints_screen.dart';
import 'team_management_screen.dart';
import 'send_notification_screen.dart';
import 'call_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminUser adminUser;

  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AdminAuthService _authService = AdminAuthService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadRecentActivities();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.logoutAdmin();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        }
      }
    }
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load stats: $e')));
      }
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final activities = await _adminService.getRecentActivities(limit: 10);
      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      // Silently fail for activities - not critical
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(),
                    const SizedBox(height: 16),

                    // Key Metrics
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Recent Activities
                    Text(
                      'Recent Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentActivities(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${widget.adminUser.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.adminUser.role.displayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_stats?['pending_psa'] != null && _stats!['pending_psa'] > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notification_important,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_stats!['pending_psa']} PSA verification(s) pending review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Primary Metrics (2x2 grid)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Users',
              _stats!['total_users']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
              subtitle: '${_stats!['verified_users'] ?? 0} verified',
            ),
            _buildMetricCard(
              'Total Products',
              _stats!['total_products']?.toString() ?? '0',
              Icons.inventory_2,
              Colors.green,
              subtitle: '${_stats!['active_products'] ?? 0} active',
            ),
            _buildMetricCard(
              'Total Orders',
              _stats!['total_orders']?.toString() ?? '0',
              Icons.shopping_cart,
              Colors.orange,
              subtitle: '${_stats!['pending_orders'] ?? 0} pending',
            ),
            _buildMetricCard(
              'Revenue',
              'UGX ${(_stats!['total_revenue'] ?? 0.0).toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.purple,
              isCompact: true,
              subtitle: 'Completed orders',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Secondary Metrics (3 columns)
        Row(
          children: [
            Expanded(
              child: _buildCompactMetric(
                'Flagged Products',
                _stats!['flagged_products']?.toString() ?? '0',
                Icons.flag,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactMetric(
                'Low Stock',
                _stats!['low_stock_products']?.toString() ?? '0',
                Icons.warning_amber,
                Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactMetric(
                'Processing',
                _stats!['processing_orders']?.toString() ?? '0',
                Icons.sync,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isCompact = false,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 16 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <Map<String, dynamic>>[];

    // Add actions based on permissions
    if (widget.adminUser.hasPermission(AdminPermissions.verifyPsa)) {
      actions.add({
        'title': 'PSA Verification',
        'icon': Icons.verified_user,
        'color': Colors.orange,
        'badge': _stats?['pending_psa'],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PsaVerificationScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    if (widget.adminUser.hasPermission(AdminPermissions.manageUsers)) {
      actions.add({
        'title': 'User Management',
        'icon': Icons.people_alt,
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UserManagementScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    if (widget.adminUser.hasPermission(AdminPermissions.moderateProducts)) {
      actions.add({
        'title': 'Product Moderation',
        'icon': Icons.fact_check,
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductModerationScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    if (widget.adminUser.hasPermission(AdminPermissions.manageOrders)) {
      actions.add({
        'title': 'Order Management',
        'icon': Icons.shopping_bag,
        'color': Colors.purple,
        'badge': _stats?['pending_orders'],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderManagementScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    if (widget.adminUser.hasPermission(AdminPermissions.handleComplaints)) {
      actions.add({
        'title': 'Complaints',
        'icon': Icons.support_agent,
        'color': Colors.red,
        'badge': _stats?['pending_complaints'],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ComplaintsScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    if (widget.adminUser.hasPermission(AdminPermissions.viewAnalytics)) {
      actions.add({
        'title': 'Analytics Dashboard',
        'icon': Icons.analytics,
        'color': Colors.teal,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAnalyticsDashboard(),
            ),
          );
        },
      });
      
      // Call Analytics (track SME interactions)
      actions.add({
        'title': 'Call Analytics',
        'icon': Icons.phone_in_talk,
        'color': Colors.deepOrange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CallAnalyticsScreen(),
            ),
          );
        },
      });
    }

    // Send Notifications (all admins can send notifications)
    actions.add({
      'title': 'Send Notification',
      'icon': Icons.notifications_active,
      'color': Colors.amber,
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SendNotificationScreen(),
          ),
        );
      },
    });

    if (widget.adminUser.hasPermission(AdminPermissions.manageAdmins)) {
      actions.add({
        'title': 'Team Management',
        'icon': Icons.groups,
        'color': Colors.indigo,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TeamManagementScreen(adminUser: widget.adminUser),
            ),
          );
        },
      });
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          action['title'],
          action['icon'],
          action['color'],
          action['onTap'],
          badge: action['badge'],
        );
      },
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badge,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentActivities.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No recent activities yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length > 5
                  ? 5
                  : _recentActivities.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade200, height: 1),
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return _buildActivityItem(activity);
              },
            ),
            if (_recentActivities.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Show all activities dialog
                    _showAllActivities();
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('View All Activities'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'unknown';
    final action = activity['action'] ?? 'Unknown action';
    final timestamp = activity['timestamp']?.toString() ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'order':
        icon = Icons.shopping_cart;
        iconColor = Colors.orange;
        break;
      case 'product':
        icon = Icons.inventory_2;
        iconColor = Colors.green;
        break;
      case 'user':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case 'verification':
        icon = Icons.verified_user;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.circle;
        iconColor = Colors.grey;
    }

    String timeAgo = _formatTimeAgo(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (activity['productName'] != null) ...[
                  Text(
                    activity['productName'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showAllActivities() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Recent Activities'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return _buildActivityItem(_recentActivities[index]);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

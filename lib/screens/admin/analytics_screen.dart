import 'package:flutter/material.dart';
import '../../models/admin_user.dart';
import '../../services/admin_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final AdminUser adminUser;

  const AnalyticsScreen({super.key, required this.adminUser});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard(
                      'Total Users',
                      _stats!['total_users'],
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Products',
                      _stats!['total_products'],
                      Icons.inventory,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Total Orders',
                      _stats!['total_orders'],
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Total Revenue',
                      'UGX ${_stats!['total_revenue']?.toStringAsFixed(0) ?? '0'}',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'User Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'SHG Members',
                      _stats!['shg_count'],
                      Icons.groups,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'PSA Partners',
                      _stats!['psa_count'],
                      Icons.store,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      'Customers',
                      _stats!['customer_count'],
                      Icons.person,
                      Colors.cyan,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/analytics_service.dart';
import '../../services/csv_export_service.dart';
import '../../models/user.dart';
import '../../utils/app_theme.dart';

class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CsvExportService _exportService = CsvExportService();

  AnalyticsData? _data;
  bool _isLoading = true;
  bool _isExporting = false;

  // Filters
  String? _selectedDistrict;
  UserRole? _selectedRole;
  String? _selectedProductCategory;
  DateTimeRange? _dateRange;
  List<String> _districts = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final districts = await _analyticsService.getDistricts();
    setState(() {
      _districts = districts;
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _analyticsService.getAnalytics(
        district: _selectedDistrict,
        role: _selectedRole,
        productCategory: _selectedProductCategory,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    if (_data == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Prepare export data
      final List<Map<String, dynamic>> exportData = [
        // Summary section
        {'Category': 'SUMMARY', 'Metric': '', 'Value': ''},
        {'Category': 'Users', 'Metric': 'Total Users', 'Value': _data!.totalUsers},
        {'Category': 'Users', 'Metric': 'Active Users', 'Value': _data!.activeUsers},
        {'Category': 'Users', 'Metric': 'SHG Members', 'Value': _data!.shgCount},
        {'Category': 'Users', 'Metric': 'SME Customers', 'Value': _data!.smeCount},
        {'Category': 'Users', 'Metric': 'PSA Partners', 'Value': _data!.psaCount},
        {'Category': '', 'Metric': '', 'Value': ''},
        {'Category': 'Orders', 'Metric': 'Total Orders', 'Value': _data!.totalOrders},
        {
          'Category': 'Orders',
          'Metric': 'Pending Confirmation',
          'Value': _data!.pendingOrders
        },
        {'Category': 'Orders', 'Metric': 'Confirmed', 'Value': _data!.confirmedOrders},
        {'Category': 'Orders', 'Metric': 'Delivered', 'Value': _data!.deliveredOrders},
        {'Category': 'Orders', 'Metric': 'Completed', 'Value': _data!.completedOrders},
        {'Category': 'Orders', 'Metric': 'Cancelled', 'Value': _data!.cancelledOrders},
        {'Category': '', 'Metric': '', 'Value': ''},
        {
          'Category': 'Revenue',
          'Metric': 'Total Revenue',
          'Value': 'UGX ${_data!.totalRevenue.toStringAsFixed(0)}'
        },
        {
          'Category': 'Revenue',
          'Metric': 'Order Revenue',
          'Value': 'UGX ${_data!.totalOrderRevenue.toStringAsFixed(0)}'
        },
        {
          'Category': 'Revenue',
          'Metric': 'Subscription Revenue',
          'Value': 'UGX ${_data!.subscriptionRevenue.toStringAsFixed(0)}'
        },
        {'Category': '', 'Metric': '', 'Value': ''},
        {
          'Category': 'Subscriptions',
          'Metric': 'Total Subscriptions',
          'Value': _data!.totalSubscriptions
        },
        {
          'Category': 'Subscriptions',
          'Metric': 'Active Subscriptions',
          'Value': _data!.activeSubscriptions
        },
        {'Category': '', 'Metric': '', 'Value': ''},
        
        // Users by district
        {'Category': 'USERS BY DISTRICT', 'Metric': '', 'Value': ''},
        ..._data!.usersByDistrict.entries.map((e) => {
              'Category': 'District',
              'Metric': e.key,
              'Value': e.value,
            }),
        {'Category': '', 'Metric': '', 'Value': ''},
        
        // Orders by district
        {'Category': 'ORDERS BY DISTRICT', 'Metric': '', 'Value': ''},
        ..._data!.ordersByDistrict.entries.map((e) => {
              'Category': 'District',
              'Metric': e.key,
              'Value': e.value,
            }),
        {'Category': '', 'Metric': '', 'Value': ''},
        
        // Orders by product
        {'Category': 'ORDERS BY PRODUCT', 'Metric': '', 'Value': ''},
        ..._data!.ordersByProduct.entries.map((e) => {
              'Category': 'Product',
              'Metric': e.key,
              'Value': e.value,
            }),
      ];

      final filename =
          'sayekatale_analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

      await _exportService.exportToCSV(
        data: exportData,
        filename: filename,
      );

      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analytics exported successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDistrict = null;
      _selectedRole = null;
      _selectedProductCategory = null;
      _dateRange = null;
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
            tooltip: 'Filters',
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportData,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
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
                    // Active filters display
                    if (_hasActiveFilters()) _buildActiveFilters(),

                    // Summary cards
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOverviewGrid(),

                    const SizedBox(height: 24),

                    // User statistics
                    _buildSection(
                      'Users',
                      [
                        _buildStatCard(
                          'Total Users',
                          _data!.totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Active Users',
                          _data!.activeUsers.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'SHG Members',
                          _data!.shgCount.toString(),
                          Icons.groups,
                          Colors.teal,
                        ),
                        _buildStatCard(
                          'SME Customers',
                          _data!.smeCount.toString(),
                          Icons.business,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'PSA Partners',
                          _data!.psaCount.toString(),
                          Icons.store,
                          Colors.indigo,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Order statistics
                    _buildSection(
                      'Orders',
                      [
                        _buildStatCard(
                          'Total Orders',
                          _data!.totalOrders.toString(),
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Pending',
                          _data!.pendingOrders.toString(),
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Confirmed',
                          _data!.confirmedOrders.toString(),
                          Icons.check,
                          Colors.cyan,
                        ),
                        _buildStatCard(
                          'Delivered',
                          _data!.deliveredOrders.toString(),
                          Icons.local_shipping,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Completed',
                          _data!.completedOrders.toString(),
                          Icons.done_all,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Cancelled',
                          _data!.cancelledOrders.toString(),
                          Icons.cancel,
                          Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Revenue statistics
                    _buildSection(
                      'Revenue',
                      [
                        _buildStatCard(
                          'Total Revenue',
                          'UGX ${_formatNumber(_data!.totalRevenue)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Order Revenue',
                          'UGX ${_formatNumber(_data!.totalOrderRevenue)}',
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Subscription Revenue',
                          'UGX ${_formatNumber(_data!.subscriptionRevenue)}',
                          Icons.card_membership,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Breakdown sections
                    if (_data!.usersByDistrict.isNotEmpty)
                      _buildBreakdownSection(
                        'Users by District',
                        _data!.usersByDistrict,
                        Icons.location_on,
                      ),

                    if (_data!.ordersByDistrict.isNotEmpty)
                      _buildBreakdownSection(
                        'Orders by District',
                        _data!.ordersByDistrict,
                        Icons.location_city,
                      ),

                    if (_data!.ordersByProduct.isNotEmpty)
                      _buildBreakdownSection(
                        'Orders by Product',
                        _data!.ordersByProduct,
                        Icons.category,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedDistrict != null ||
        _selectedRole != null ||
        _selectedProductCategory != null ||
        _dateRange != null;
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Filters:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedDistrict != null)
                Chip(
                  label: Text('District: $_selectedDistrict'),
                  onDeleted: () {
                    setState(() {
                      _selectedDistrict = null;
                    });
                    _loadAnalytics();
                  },
                ),
              if (_selectedRole != null)
                Chip(
                  label: Text('Role: ${_selectedRole!.toString().split('.').last.toUpperCase()}'),
                  onDeleted: () {
                    setState(() {
                      _selectedRole = null;
                    });
                    _loadAnalytics();
                  },
                ),
              if (_selectedProductCategory != null)
                Chip(
                  label: Text('Product: $_selectedProductCategory'),
                  onDeleted: () {
                    setState(() {
                      _selectedProductCategory = null;
                    });
                    _loadAnalytics();
                  },
                ),
              if (_dateRange != null)
                Chip(
                  label: Text(
                    'Date: ${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  ),
                  onDeleted: () {
                    setState(() {
                      _dateRange = null;
                    });
                    _loadAnalytics();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildOverviewCard(
          'Total Users',
          _data!.totalUsers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildOverviewCard(
          'Total Orders',
          _data!.totalOrders.toString(),
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildOverviewCard(
          'Pending Orders',
          _data!.pendingOrders.toString(),
          Icons.hourglass_empty,
          Colors.amber,
        ),
        _buildOverviewCard(
          'Total Revenue',
          'UGX ${_formatNumber(_data!.totalRevenue)}',
          Icons.attach_money,
          Colors.green,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 16 : 24,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownSection(
    String title,
    Map<String, int> data,
    IconData icon,
  ) {
    // Sort by value descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sortedEntries.take(10).map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(entry.key),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            )),
        if (sortedEntries.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... and ${sortedEntries.length - 10} more',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Analytics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // District filter
              const Text('District:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('All Districts'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Districts')),
                  ..._districts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Role filter
              const Text('User Role:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('All Roles'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ...UserRole.values.map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.toString().split('.').last.toUpperCase()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date range filter
              const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (picked != null) {
                    setState(() {
                      _dateRange = picked;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dateRange == null
                      ? 'Select Date Range'
                      : '${DateFormat('MMM d, y').format(_dateRange!.start)} - ${DateFormat('MMM d, y').format(_dateRange!.end)}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAnalytics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}

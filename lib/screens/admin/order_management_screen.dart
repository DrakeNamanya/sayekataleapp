import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/admin_user.dart';
import '../../services/csv_export_service.dart';

class OrderManagementScreen extends StatefulWidget {
  final AdminUser adminUser;

  const OrderManagementScreen({
    super.key,
    required this.adminUser,
  });

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final CsvExportService _csvExportService = CsvExportService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isExporting = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  // Statistics
  int _totalOrders = 0;
  int _deliveredOrders = 0;
  int _pendingOrders = 0;
  int _inTransitOrders = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await _firestore.collection('orders').get();
      
      final orders = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        orders.add(data);
      }

      // Sort by created_at descending (newest first)
      orders.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });

      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
        _calculateStats();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
    }
  }

  void _calculateStats() {
    _totalOrders = _orders.length;
    _deliveredOrders = 0;
    _pendingOrders = 0;
    _inTransitOrders = 0;
    _totalRevenue = 0;

    for (var order in _orders) {
      final status = (order['status'] ?? '').toString().toLowerCase();
      
      // Firebase statuses: delivered, completed, ready, confirmed, shipped, placed, pending
      if (status == 'delivered' || status == 'completed') {
        _deliveredOrders++;
      } else if (status == 'placed' || status == 'created' || status.isEmpty) {
        _pendingOrders++;
      } else if (status == 'confirmed' || status == 'shipped' || status == 'ready') {
        _inTransitOrders++;
      }

      final amount = order['total_amount'];
      if (amount != null) {
        _totalRevenue += (amount is num ? amount.toDouble() : 0);
      }
    }
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Filter by status
        if (_selectedStatus != 'all') {
          final status = (order['status'] ?? '').toString().toLowerCase();
          if (_selectedStatus == 'delivered' && 
              !(status == 'delivered' || status == 'completed')) {
            return false;
          }
          if (_selectedStatus == 'pending' && 
              !(status == 'placed' || status == 'created' || status.isEmpty)) {
            return false;
          }
          if (_selectedStatus == 'in_transit' && 
              !(status == 'confirmed' || status == 'shipped' || status == 'ready')) {
            return false;
          }
        }

        // Filter by search query
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final buyerName = (order['buyer_name'] ?? '').toString().toLowerCase();
          final buyerId = (order['buyer_system_id'] ?? order['buyer_id'] ?? '').toString().toLowerCase();
          final orderId = (order['id'] ?? '').toString().toLowerCase();
          
          // Search in items array for product names
          String productNames = '';
          if (order['items'] is List) {
            final items = order['items'] as List;
            productNames = items.map((item) => (item['product_name'] ?? '').toString()).join(' ').toLowerCase();
          }
          
          return buyerName.contains(query) || 
                 buyerId.contains(query) || 
                 productNames.contains(query) ||
                 orderId.contains(query);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _exportToCSV() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV export is only available on web platform'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await _csvExportService.exportOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orders exported to CSV successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'N/A';
      
      DateTime dt;
      if (dateValue is Timestamp) {
        dt = dateValue.toDate();
      } else if (dateValue is String) {
        dt = DateTime.parse(dateValue);
      } else {
        return 'Invalid date';
      }
      
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getStatusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return 'Delivered';
    if (s == 'placed' || s == 'created' || s.isEmpty) return 'Pending';
    if (s == 'confirmed' || s == 'shipped' || s == 'ready') return 'In Transit';
    return status.isEmpty ? 'Pending' : status;
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'delivered' || s == 'completed') return Colors.green;
    if (s == 'placed' || s == 'created' || s.isEmpty) return Colors.orange;
    if (s == 'confirmed' || s == 'shipped' || s == 'ready') return Colors.blue;
    return Colors.grey;
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    // Extract items
    final items = order['items'] as List? ?? [];
    int totalQuantity = 0;
    for (var item in items) {
      totalQuantity += (item['quantity'] ?? 0) as int;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - ${order['order_number'] ?? order['id'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order['id'] ?? 'N/A'),
              if (order['order_number'] != null)
                _buildDetailRow('Order Number', order['order_number']),
              const Divider(),
              const Text(
                'Buyer Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('User ID', order['buyer_system_id'] ?? order['buyer_id'] ?? 'N/A'),
              _buildDetailRow('Name', order['buyer_name'] ?? 'N/A'),
              _buildDetailRow('Phone', order['buyer_phone'] ?? 'N/A'),
              const Divider(),
              const Text(
                'Farmer/Seller Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('User ID', order['farmer_system_id'] ?? order['farmer_id'] ?? 'N/A'),
              _buildDetailRow('Name', order['farmer_name'] ?? 'N/A'),
              _buildDetailRow('Phone', order['farmer_phone'] ?? 'N/A'),
              const Divider(),
              const Text(
                'Products Ordered:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (items.isNotEmpty)
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Quantity: ${item['quantity']} ${item['unit'] ?? ''}'),
                        Text('Price: UGX ${NumberFormat('#,###').format(item['price'] ?? 0)} each'),
                        Text(
                          'Subtotal: UGX ${NumberFormat('#,###').format(item['subtotal'] ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )).toList()
              else
                const Text('No items found'),
              const SizedBox(height: 8),
              _buildDetailRow('Total Items', totalQuantity.toString()),
              _buildDetailRow('Total Amount', 'UGX ${NumberFormat('#,###').format(order['total_amount'] ?? 0)}'),
              const Divider(),
              const Text(
                'Delivery Information:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Status', _getStatusLabel(order['status'] ?? 'Unknown')),
              _buildDetailRow('Payment Method', order['payment_method'] ?? 'N/A'),
              if (order['delivery_address'] != null && order['delivery_address'].toString().isNotEmpty)
                _buildDetailRow('Delivery Address', order['delivery_address'].toString()),
              if (order['delivery_notes'] != null && order['delivery_notes'].toString().isNotEmpty)
                _buildDetailRow('Delivery Notes', order['delivery_notes']),
              const Divider(),
              _buildDetailRow('Order Date', _formatDate(order['created_at'])),
              if (order['confirmed_at'] != null)
                _buildDetailRow('Confirmed', _formatDate(order['confirmed_at'])),
              if (order['shipped_at'] != null)
                _buildDetailRow('Shipped', _formatDate(order['shipped_at'])),
              if (order['delivered_at'] != null)
                _buildDetailRow('Delivered', _formatDate(order['delivered_at'])),
              if (order['received_at'] != null)
                _buildDetailRow('Received by Buyer', _formatDate(order['received_at'])),
              if (order['rating'] != null) ...[
                const Divider(),
                const Text(
                  'Review:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Rating', '${order['rating']}/5 ⭐'),
                if (order['review'] != null)
                  _buildDetailRow('Comment', order['review']),
                if (order['reviewed_at'] != null)
                  _buildDetailRow('Reviewed', _formatDate(order['reviewed_at'])),
              ],
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (kIsWeb)
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
              onPressed: _isExporting ? null : _exportToCSV,
              tooltip: 'Export to CSV',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Orders',
                        _totalOrders.toString(),
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Delivered',
                        _deliveredOrders.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        _pendingOrders.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'In Transit',
                        _inTransitOrders.toString(),
                        Icons.local_shipping,
                        Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Total Revenue: UGX ${NumberFormat('#,###').format(_totalRevenue)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by buyer name, ID, product, or order ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Orders')),
                    DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'in_transit', child: Text('In Transit')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _filterOrders();
                  },
                ),
              ],
            ),
          ),

          // Orders Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                ),
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                columns: const [
                                  DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('User ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Cost (UGX)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredOrders.map((order) {
                                  final status = order['status'] ?? 'Unknown';
                                  final statusLabel = _getStatusLabel(status);
                                  final statusColor = _getStatusColor(status);
                                  
                                  // Extract products from items array
                                  String productNames = 'N/A';
                                  int totalQuantity = 0;
                                  if (order['items'] is List) {
                                    final items = order['items'] as List;
                                    if (items.isNotEmpty) {
                                      productNames = items.map((item) => item['product_name'] ?? 'Unknown').join(', ');
                                      for (var item in items) {
                                        totalQuantity += (item['quantity'] ?? 0) as int;
                                      }
                                    }
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          (order['order_number'] ?? order['id'] ?? 'N/A').toString().length > 15
                                              ? (order['order_number'] ?? order['id']).toString().substring(0, 12) + '...'
                                              : (order['order_number'] ?? order['id'] ?? 'N/A').toString(),
                                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                        ),
                                      ),
                                      DataCell(Text(order['buyer_system_id'] ?? order['buyer_id'] ?? 'N/A')),
                                      DataCell(
                                        Text(
                                          order['buyer_name'] ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            productNames,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          totalQuantity.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          NumberFormat('#,###').format(order['total_amount'] ?? 0),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(_formatDate(order['created_at']))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 20),
                                          onPressed: () => _showOrderDetails(order),
                                          tooltip: 'View Details',
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

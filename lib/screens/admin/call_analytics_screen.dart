import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';

class CallAnalyticsScreen extends StatefulWidget {
  const CallAnalyticsScreen({super.key});

  @override
  State<CallAnalyticsScreen> createState() => _CallAnalyticsScreenState();
}

class _CallAnalyticsScreenState extends State<CallAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterBy = 'all'; // 'all', 'today', 'week', 'month'
  String _sortBy = 'recent'; // 'recent', 'product', 'seller'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Button Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Time')),
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'recent', child: Text('Most Recent')),
              const PopupMenuItem(
                value: 'product',
                child: Text('By Product'),
              ),
              const PopupMenuItem(value: 'seller', child: Text('By Seller')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          Expanded(
            child: _buildAnalyticsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final totalCalls = snapshot.data!.docs.length;

        // Count by buyer type
        final buyerTypeCounts = <String, int>{};
        final sellerProductCounts = <String, int>{};
        final productCounts = <String, int>{};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final buyerType = data['buyer_type'] as String? ?? 'Unknown';
          final sellerId = data['seller_id'] as String? ?? 'Unknown';
          final productId = data['product_id'] as String? ?? 'Unknown';

          buyerTypeCounts[buyerType] = (buyerTypeCounts[buyerType] ?? 0) + 1;
          sellerProductCounts[sellerId] =
              (sellerProductCounts[sellerId] ?? 0) + 1;
          productCounts[productId] = (productCounts[productId] ?? 0) + 1;
        }

        final smeCount = buyerTypeCounts['SME'] ?? 0;
        final uniqueSellers = sellerProductCounts.length;
        final uniqueProducts = productCounts.length;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Calls',
                      totalCalls.toString(),
                      Icons.phone,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'SME Calls',
                      smeCount.toString(),
                      Icons.business,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Sellers Contacted',
                      uniqueSellers.toString(),
                      Icons.person,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Products Viewed',
                      uniqueProducts.toString(),
                      Icons.shopping_bag,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No call analytics data available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        // Sort based on selected option
        docs = List.from(docs);
        switch (_sortBy) {
          case 'product':
            docs.sort((a, b) {
              final aName = (a.data() as Map)['product_name'] ?? '';
              final bName = (b.data() as Map)['product_name'] ?? '';
              return aName.compareTo(bName);
            });
            break;
          case 'seller':
            docs.sort((a, b) {
              final aName = (a.data() as Map)['seller_name'] ?? '';
              final bName = (b.data() as Map)['seller_name'] ?? '';
              return aName.compareTo(bName);
            });
            break;
          case 'recent':
          default:
            docs.sort((a, b) {
              final aTime = (a.data() as Map)['clicked_at'] as Timestamp?;
              final bTime = (b.data() as Map)['clicked_at'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildAnalyticsCard(data);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final productName = data['product_name'] as String? ?? 'Unknown Product';
    final sellerName = data['seller_name'] as String? ?? 'Unknown Seller';
    final buyerName = data['buyer_name'] as String? ?? 'Unknown Buyer';
    final buyerType = data['buyer_type'] as String? ?? 'Unknown';
    final clickedAt = data['clicked_at'] as Timestamp?;
    final price = data['product_price'] as num? ?? 0;
    final category = data['product_category'] as String? ?? 'Unknown';

    final dateStr = clickedAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(clickedAt.toDate())
        : 'Unknown date';

    Color buyerTypeColor = AppTheme.primaryColor;
    IconData buyerTypeIcon = Icons.person;

    switch (buyerType) {
      case 'SME':
        buyerTypeColor = Colors.blue;
        buyerTypeIcon = Icons.business;
        break;
      case 'SHG':
        buyerTypeColor = Colors.green;
        buyerTypeIcon = Icons.people;
        break;
      case 'PSA':
        buyerTypeColor = Colors.orange;
        buyerTypeIcon = Icons.store;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: buyerTypeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(buyerTypeIcon, size: 16, color: buyerTypeColor),
                      const SizedBox(width: 6),
                      Text(
                        buyerType,
                        style: TextStyle(
                          color: buyerTypeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'UGX ${price.toStringAsFixed(0)} • $category',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sellerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buyerName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Query<Map<String, dynamic>> _getFilteredQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('call_analytics');

    // Apply time filter
    switch (_filterBy) {
      case 'today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        query = query.where(
          'clicked_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        );
        break;
      case 'week':
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        query = query.where(
          'clicked_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
        );
        break;
      case 'month':
        final now = DateTime.now();
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        query = query.where(
          'clicked_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo),
        );
        break;
    }

    return query;
  }
}

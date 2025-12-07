import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/receipt_service.dart';
import '../../models/receipt.dart';
import '../../utils/app_theme.dart';
import 'receipt_detail_screen.dart';

/// Receipts List Screen
/// Shows all receipts for the logged-in user (buyer or seller view)
class ReceiptsListScreen extends StatefulWidget {
  final bool isSellerView; // true = seller receipts, false = buyer receipts

  const ReceiptsListScreen({super.key, this.isSellerView = false});

  @override
  State<ReceiptsListScreen> createState() => _ReceiptsListScreenState();
}

class _ReceiptsListScreenState extends State<ReceiptsListScreen> {
  final ReceiptService _receiptService = ReceiptService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? '';
    final userName = authProvider.currentUser?.name ?? 'Unknown';
    final userRole = authProvider.currentUser?.role ?? 'Unknown';

    // 🔍 Debug logging
    if (kDebugMode) {
      debugPrint('🔍 ReceiptsListScreen Debug Info:');
      debugPrint('   User ID: $userId');
      debugPrint('   User Name: $userName');
      debugPrint('   User Role: $userRole');
      debugPrint('   Is Seller View: ${widget.isSellerView}');
      debugPrint('   Query Type: ${widget.isSellerView ? "streamSellerReceipts" : "streamBuyerReceipts"}');
    }

    // ⚠️ Show error if user ID is empty
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isSellerView ? 'Sales Receipts' : 'Purchase Receipts',
          ),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'User not logged in',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view receipts',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSellerView ? 'Sales Receipts' : 'Purchase Receipts',
        ),
        elevation: 0,
        actions: [
          // Debug info button
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Debug Info'),
                    content: SingleChildScrollView(
                      child: Text(
                        'User ID: $userId\n'
                        'User Name: $userName\n'
                        'Role: $userRole\n'
                        'Is Seller View: ${widget.isSellerView}\n'
                        'Query: ${widget.isSellerView ? "seller_id" : "buyer_id"} = $userId',
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
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Receipt>>(
        stream: widget.isSellerView
            ? _receiptService.streamSellerReceipts(userId)
            : _receiptService.streamBuyerReceipts(userId),
        builder: (context, snapshot) {
          // 🔍 Debug snapshot state
          if (kDebugMode) {
            debugPrint('📊 Stream State: ${snapshot.connectionState}');
            debugPrint('   Has Error: ${snapshot.hasError}');
            debugPrint('   Has Data: ${snapshot.hasData}');
            if (snapshot.hasData) {
              debugPrint('   Receipts Count: ${snapshot.data?.length ?? 0}');
            }
            if (snapshot.hasError) {
              debugPrint('   Error: ${snapshot.error}');
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading receipts',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {}); // Trigger rebuild
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final receipts = snapshot.data ?? [];

          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSellerView
                        ? 'No sales receipts yet'
                        : 'No purchase receipts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isSellerView
                        ? 'Sales receipts will appear here once buyers confirm deliveries'
                        : 'Purchase receipts will appear here once you confirm deliveries',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild to refresh stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _buildReceiptCard(receipt);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(Receipt receipt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptDetailScreen(receipt: receipt),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    receipt.id,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Confirmed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(receipt.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Buyer/Seller Info
              Row(
                children: [
                  Icon(
                    widget.isSellerView ? Icons.shopping_bag : Icons.storefront,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isSellerView
                          ? receipt.buyerName
                          : receipt.sellerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items Summary
              Text(
                '${receipt.items.length} item${receipt.items.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'UGX ${NumberFormat('#,###').format(receipt.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              // Rating (if available)
              if (receipt.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < receipt.rating!
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '${receipt.rating}/5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

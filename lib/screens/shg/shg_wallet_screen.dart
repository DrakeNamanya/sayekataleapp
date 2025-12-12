import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
// Wallet service temporarily disabled - only premium subscription payments are implemented
// General wallet deposits/withdrawals via PawaPay are not yet available
// import '../../services/wallet_service.dart';
// import '../../services/pawapay_service.dart';
// import '../../config/pawapay_config.dart';
import '../../models/wallet.dart' hide Transaction;
import '../../models/transaction.dart' as app_transaction;
import '../../utils/app_theme.dart';

class SHGWalletScreen extends StatefulWidget {
  const SHGWalletScreen({super.key});

  @override
  State<SHGWalletScreen> createState() => _SHGWalletScreenState();
}

class _SHGWalletScreenState extends State<SHGWalletScreen> {
  // NOTE: Wallet screen is VIEW-ONLY - shows transaction history from Firestore
  // Premium subscription payments are handled in subscription_purchase_screen.dart
  // General wallet deposits/withdrawals are not yet implemented
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  // Helper: Get or create wallet (read-only)
  Future<Wallet> getOrCreateWallet(String userId) async {
    final walletDoc = await _firestore.collection('wallets').doc(userId).get();
    if (walletDoc.exists) {
      return Wallet.fromFirestore(walletDoc.data()!, userId);
    }
    // Create empty wallet if it doesn't exist
    final newWallet = Wallet(
      id: userId,
      userId: userId,
      balance: 0.0,
      currency: 'UGX',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore.collection('wallets').doc(userId).set(newWallet.toFirestore());
    return newWallet;
  }

  // Helper: Stream wallet data
  Stream<Wallet> streamWallet(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Wallet.fromFirestore(doc.data()!, userId);
      }
      return Wallet(
        id: userId,
        userId: userId,
        balance: 0.0,
        currency: 'UGX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  // Helper: Stream transactions
  Stream<List<app_transaction.Transaction>> streamTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_transaction.Transaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to access wallet')),
      );
    }

    // ✅ WALLET FEATURE: Coming Soon
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wallet icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              
              // Coming Soon title
              const Text(
                'Wallet Feature',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Coming Soon subtitle
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'We are working on bringing you a secure wallet feature for managing your transactions and payments.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Information card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upcoming Features',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Mobile money integration\n'
                      '• Secure transactions\n'
                      '• Transaction history\n'
                      '• Balance management\n'
                      '• Payment processing',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // OLD CODE - Keep for future reference when wallet feature is implemented
    /*
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<Wallet>(
        // First, ensure wallet exists by calling getOrCreateWallet
        future: getOrCreateWallet(user.id),
        builder: (context, futureSnapshot) {
          // Show loading while creating/fetching wallet
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading wallet...'),
                ],
              ),
            );
          }

          // Show error if wallet creation/fetch failed
          if (futureSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading wallet: ${futureSnapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Wallet now exists, use StreamBuilder for real-time updates
          return StreamBuilder<Wallet>(
            stream: streamWallet(user.id),
            builder: (context, streamSnapshot) {
              // Use futureSnapshot data while stream is loading
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                // Show initial wallet data from future while waiting for stream
                if (futureSnapshot.hasData) {
                  final wallet = futureSnapshot.data!;
                  return _buildWalletContent(
                    wallet,
                    user.id,
                    user.name,
                    user.phone,
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              if (streamSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: ${streamSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Stream has data, use it for real-time updates
              if (streamSnapshot.hasData) {
                final wallet = streamSnapshot.data!;
                return _buildWalletContent(
                  wallet,
                  user.id,
                  user.name,
                  user.phone,
                );
              }

              // Fallback: show future data if stream has no data yet
              if (futureSnapshot.hasData) {
                final wallet = futureSnapshot.data!;
                return _buildWalletContent(
                  wallet,
                  user.id,
                  user.name,
                  user.phone,
                );
              }

              return const Center(child: Text('No wallet data'));
            },
          );
        },
      ),
    );
  }

  Widget _buildWalletContent(
    Wallet wallet,
    String userId,
    String userName,
    String userPhone,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger rebuild to refresh data
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Wallet Balance Card
            _buildBalanceCard(wallet),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(userId, userName, userPhone),

            const SizedBox(height: 24),

            // Recent Transactions
            _buildTransactionsList(userId),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Wallet wallet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'UGX ${NumberFormat('#,###').format(wallet.balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (wallet.pendingBalance > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Pending: UGX ${NumberFormat('#,###').format(wallet.pendingBalance)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(String userId, String userName, String userPhone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.add_circle_outline,
              label: 'Deposit',
              color: Colors.grey,
              onTap: () => _showComingSoonMessage('Deposit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.remove_circle_outline,
              label: 'Withdraw',
              color: Colors.grey,
              onTap: () => _showComingSoonMessage('Withdraw'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.receipt_long,
              label: 'History',
              color: Colors.blue,
              onTap: () => _showTransactionHistory(userId),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon! Currently, only premium subscription payments are available.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTransactionsList(String userId) {
    return StreamBuilder<List<app_transaction.Transaction>>(
      stream: streamTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data!.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _TransactionTile(transaction: transactions[index]);
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _showTransactionHistory(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _TransactionHistoryScreen(
          userId: userId,
        ),
      ),
    );
  }
}

// ============================================================================
// SUPPORTING WIDGETS
// ============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final app_transaction.Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Product purchases are income for SHG
    final isPositive =
        transaction.type == app_transaction.TransactionType.smeToShgProductPurchase;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getTypeColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getTypeIcon(), color: _getTypeColor()),
      ),
      title: Text(
        transaction.type.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _formatDate(transaction.createdAt),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isPositive ? '+' : '-'} UGX ${NumberFormat('#,###').format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          _StatusBadge(status: transaction.status),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (transaction.type) {
      case app_transaction.TransactionType.shgToPsaInputPurchase:
        return Icons.shopping_cart;
      case app_transaction.TransactionType.smeToShgProductPurchase:
        return Icons.shopping_bag;
      case app_transaction.TransactionType.shgPremiumSubscription:
        return Icons.star;
      case app_transaction.TransactionType.psaAnnualSubscription:
        return Icons.card_membership;
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case app_transaction.TransactionType.shgToPsaInputPurchase:
        return Colors.orange;
      case app_transaction.TransactionType.smeToShgProductPurchase:
        return Colors.green;
      case app_transaction.TransactionType.shgPremiumSubscription:
        return Colors.purple;
      case app_transaction.TransactionType.psaAnnualSubscription:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat.jm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat.jm().format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final app_transaction.TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case app_transaction.TransactionStatus.completed:
      case app_transaction.TransactionStatus.confirmed:
        return Colors.green;
      case app_transaction.TransactionStatus.initiated:
      case app_transaction.TransactionStatus.paymentPending:
      case app_transaction.TransactionStatus.paymentHeld:
      case app_transaction.TransactionStatus.deliveryPending:
      case app_transaction.TransactionStatus.deliveredPendingConfirmation:
      case app_transaction.TransactionStatus.disbursementPending:
        return Colors.orange;
      case app_transaction.TransactionStatus.failed:
      case app_transaction.TransactionStatus.refunded:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case app_transaction.TransactionStatus.initiated:
        return 'Initiated';
      case app_transaction.TransactionStatus.paymentPending:
        return 'Payment Pending';
      case app_transaction.TransactionStatus.paymentHeld:
        return 'Payment Held';
      case app_transaction.TransactionStatus.deliveryPending:
        return 'Delivery Pending';
      case app_transaction.TransactionStatus.deliveredPendingConfirmation:
        return 'Awaiting Confirmation';
      case app_transaction.TransactionStatus.confirmed:
        return 'Confirmed';
      case app_transaction.TransactionStatus.disbursementPending:
        return 'Disbursement Pending';
      case app_transaction.TransactionStatus.completed:
        return 'Completed';
      case app_transaction.TransactionStatus.failed:
        return 'Failed';
      case app_transaction.TransactionStatus.refunded:
        return 'Refunded';
    }
  }
}

// ============================================================================
// TRANSACTION HISTORY SCREEN
// ============================================================================

class _TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const _TransactionHistoryScreen({
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<app_transaction.Transaction>>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => app_transaction.Transaction.fromFirestore(doc.data(), doc.id))
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _TransactionTile(transaction: transactions[index]);
            },
          );
        },
      ),
    );
    */ // End of old wallet code
  }
}

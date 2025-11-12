import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/pawapay_service.dart';
import '../../models/wallet.dart';
import '../../utils/app_theme.dart';

class SHGWalletScreen extends StatefulWidget {
  const SHGWalletScreen({super.key});

  @override
  State<SHGWalletScreen> createState() => _SHGWalletScreenState();
}

class _SHGWalletScreenState extends State<SHGWalletScreen> {
  late WalletService _walletService;
  
  @override
  void initState() {
    super.initState();
    // Initialize PawaPay with API token
    final pawaPayService = PawaPayService(
      apiToken: 'eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ'
    );
    _walletService = WalletService(pawaPayService: pawaPayService);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<Wallet>(
        stream: _walletService.streamWallet(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No wallet data'));
          }

          final wallet = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger rebuild
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
                  _buildActionButtons(user.id, user.name, user.phone),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Transactions
                  _buildTransactionsList(user.id),
                ],
              ),
            ),
          );
        },
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
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
              color: Colors.green,
              onTap: () => _showDepositDialog(userId, userName, userPhone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.remove_circle_outline,
              label: 'Withdraw',
              color: Colors.orange,
              onTap: () => _showWithdrawDialog(userId, userName, userPhone),
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

  Widget _buildTransactionsList(String userId) {
    return StreamBuilder<List<Transaction>>(
      stream: _walletService.streamTransactions(userId),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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

  void _showDepositDialog(String userId, String userName, String userPhone) {
    final amountController = TextEditingController();
    String selectedProvider = 'MTN_MOMO_UGA';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Deposit Money'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter amount to deposit',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (UGX)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select payment method',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MTN_MOMO_UGA',
                      child: Text('MTN Mobile Money'),
                    ),
                    DropdownMenuItem(
                      value: 'AIRTEL_OAPI_UGA',
                      child: Text('Airtel Money'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProvider = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You will receive a prompt on your phone to authorize the payment.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      final result = await _walletService.initiateDeposit(
                        userId: userId,
                        amount: amount,
                        phoneNumber: userPhone,
                        provider: selectedProvider,
                        userName: userName,
                      );

                      setDialogState(() {
                        isLoading = false;
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['success']
                                  ? result['message']
                                  : result['error'],
                            ),
                            backgroundColor:
                                result['success'] ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Deposit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(String userId, String userName, String userPhone) {
    final amountController = TextEditingController();
    String selectedProvider = 'MTN_MOMO_UGA';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Withdraw Money'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter amount to withdraw',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (UGX)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Withdraw to',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MTN_MOMO_UGA',
                      child: Text('MTN Mobile Money'),
                    ),
                    DropdownMenuItem(
                      value: 'AIRTEL_OAPI_UGA',
                      child: Text('Airtel Money'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProvider = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Money will be sent to your registered mobile number.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      final result = await _walletService.initiateWithdrawal(
                        userId: userId,
                        amount: amount,
                        phoneNumber: userPhone,
                        provider: selectedProvider,
                        userName: userName,
                      );

                      setDialogState(() {
                        isLoading = false;
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['success']
                                  ? result['message']
                                  : result['error'],
                            ),
                            backgroundColor:
                                result['success'] ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionHistory(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _TransactionHistoryScreen(
          userId: userId,
          walletService: _walletService,
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.earning;
    
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
      case TransactionType.deposit:
        return Icons.add_circle;
      case TransactionType.withdrawal:
        return Icons.remove_circle;
      case TransactionType.payment:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.earning:
        return Icons.attach_money;
      case TransactionType.purchase:
        return Icons.shopping_bag;
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.earning:
        return Colors.green;
      case TransactionType.withdrawal:
      case TransactionType.purchase:
        return Colors.orange;
      case TransactionType.payment:
        return Colors.blue;
      case TransactionType.refund:
        return Colors.purple;
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
  final TransactionStatus status;

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
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return Colors.orange;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// ============================================================================
// TRANSACTION HISTORY SCREEN
// ============================================================================

class _TransactionHistoryScreen extends StatelessWidget {
  final String userId;
  final WalletService walletService;

  const _TransactionHistoryScreen({
    required this.userId,
    required this.walletService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: walletService.streamTransactions(userId),
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
  }
}

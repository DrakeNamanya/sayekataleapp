import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
// import '../../services/wallet_service.dart';
// import '../../services/pawapay_service.dart';
// import '../../config/pawapay_config.dart';
import '../../models/wallet.dart';
import '../../utils/app_theme.dart';
import '../../utils/uganda_phone_validator.dart';

class SHGWalletScreen extends StatefulWidget {
  const SHGWalletScreen({super.key});

  @override
  State<SHGWalletScreen> createState() => _SHGWalletScreenState();
}

class _SHGWalletScreenState extends State<SHGWalletScreen> {
  // NOTE: Wallet functionality is view-only in this screen
  // PawaPay payment integration is handled in subscription_purchase_screen.dart
  // late WalletService _walletService;

  @override
  void initState() {
    super.initState();
    // Initialize PawaPay with API token from config (COMMENTED OUT - not needed for view-only wallet)
    // final pawaPayService = PawaPayService(apiToken: PawaPayConfig.apiToken);
    // _walletService = WalletService(pawaPayService: pawaPayService);
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
      body: FutureBuilder<Wallet>(
        // First, ensure wallet exists by calling getOrCreateWallet
        future: _walletService.getOrCreateWallet(user.id),
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
            stream: _walletService.streamWallet(user.id),
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

  void _showDepositDialog(String userId, String userName, String userPhone) {
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedProvider;
    String? detectedOperator;
    String? phoneError;
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
                // Step 1: Phone Number Input
                const Text(
                  'Step 1: Enter your mobile money number',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '0712 345 678',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                    errorText: phoneError,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      // Validate phone number
                      phoneError = UgandaPhoneValidator.validate(value);

                      if (phoneError == null) {
                        // Detect operator
                        detectedOperator = UgandaPhoneValidator.getOperatorName(
                          value,
                        );

                        // Auto-select provider based on operator
                        if (detectedOperator?.contains('MTN') ?? false) {
                          selectedProvider = 'MTN_MOMO_UGA';
                        } else if (detectedOperator?.contains('Airtel') ??
                            false) {
                          selectedProvider = 'AIRTEL_OAPI_UGA';
                        } else {
                          selectedProvider = null;
                          phoneError =
                              'Only MTN and Airtel are supported for mobile money';
                        }
                      } else {
                        detectedOperator = null;
                        selectedProvider = null;
                      }
                    });
                  },
                ),
                if (detectedOperator != null && phoneError == null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✓ Detected: $detectedOperator',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Step 2: Amount Input
                const Text(
                  'Step 2: Enter amount to deposit',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (UGX)',
                    hintText: '10,000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  enabled: phoneError == null && detectedOperator != null,
                ),
                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'How it works:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Enter your MTN or Airtel number\n'
                        '2. Enter the amount to deposit\n'
                        '3. Click "Initiate Deposit"\n'
                        '4. You will receive a prompt on your phone\n'
                        '5. Enter your PIN to complete the payment',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
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
              onPressed:
                  (isLoading ||
                      phoneError != null ||
                      detectedOperator == null ||
                      selectedProvider == null)
                  ? null
                  : () async {
                      final amount = double.tryParse(
                        amountController.text.replaceAll(',', ''),
                      );
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                        return;
                      }

                      if (amount < 1000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Minimum deposit amount is UGX 1,000',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                      });

                      final result = await _walletService.initiateDeposit(
                        userId: userId,
                        amount: amount,
                        phoneNumber: phoneController.text,
                        provider: selectedProvider!,
                        userName: userName,
                      );

                      setDialogState(() {
                        isLoading = false;
                      });

                      if (mounted) {
                        Navigator.pop(context);

                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Deposit initiated!\n'
                                'Check your phone (${phoneController.text}) for payment prompt.\n'
                                'Enter your PIN to complete the deposit.',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        } else {
                          // Check if it's a CORS/network error
                          final errorMsg = result['error'] ?? '';
                          final isCorsError =
                              errorMsg.contains('ClientException') ||
                              errorMsg.contains('failed to fetch') ||
                              errorMsg.contains('Network error');

                          if (isCorsError) {
                            // Show detailed CORS explanation
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Web Preview Limitation'),
                                  ],
                                ),
                                content: const SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🌐 PawaPay Integration Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'The web preview cannot directly connect to PawaPay API due to browser security restrictions (CORS policy).',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '✅ Solutions:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '1. Android APK (Recommended)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '   Mobile apps work perfectly - no CORS restrictions.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '2. Backend Server',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '   Use Cloud Functions or backend API to proxy PawaPay calls.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        '📱 To test PawaPay:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '• Build Android APK and install on device\n• PawaPay will work fully in the mobile app',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Show regular error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMsg),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Initiate Deposit'),
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
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
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
                            backgroundColor: result['success']
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
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
    final isPositive =
        transaction.type == TransactionType.deposit ||
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

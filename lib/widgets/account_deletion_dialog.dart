import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/account_deletion_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

/// Dialog for account deletion with password confirmation
/// Shows warning, requires password re-authentication, and handles deletion process
class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final AccountDeletionService _deletionService = AccountDeletionService();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isDeleting = false;
  bool _showPassword = false;
  bool _needsReauth = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkReauthRequired();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// Check if re-authentication is required
  Future<void> _checkReauthRequired() async {
    final needsReauth = await _deletionService.needsReauthentication();
    setState(() {
      _needsReauth = needsReauth;
    });
  }

  /// Handle account deletion
  Future<void> _handleDeleteAccount() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Step 1: Re-authenticate if needed
      if (_needsReauth) {
        final reauthSuccess = await _deletionService.reauthenticateUser(
          _passwordController.text,
        );

        if (!reauthSuccess) {
          setState(() {
            _errorMessage = 'Invalid password. Please try again.';
            _isDeleting = false;
          });
          return;
        }
      }

      // Step 2: Delete account and all data
      final success = await _deletionService.deleteAccount(userId);

      if (success && mounted) {
        // Logout and navigate to onboarding
        await authProvider.logout();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding',
            (route) => false,
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your account has been permanently deleted'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Account deletion error: $e');
      }

      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isDeleting = false;
      });
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.contains('requires-recent-login')) {
      return 'For security reasons, please logout and login again before deleting your account.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'An error occurred. Please try again or contact support.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Warning: This action cannot be undone!',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Deleting your account will permanently remove:',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'All your products and listings',
                      'Order history (both as buyer and seller)',
                      'Reviews and ratings',
                      'Messages and conversations',
                      'Profile information and photos',
                      'Verification documents',
                      'Wallet transactions',
                      'Subscription data',
                    ].map((item) => Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Confirmation text
              Text(
                'Are you absolutely sure you want to delete your account, $userName?',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Password field
              if (_needsReauth)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  enabled: !_isDeleting,
                  decoration: InputDecoration(
                    labelText: 'Enter your password to confirm',
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        
        // Delete button
        ElevatedButton.icon(
          onPressed: _isDeleting ? null : _handleDeleteAccount,
          icon: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.delete_forever),
          label: Text(_isDeleting ? 'Deleting...' : 'Delete Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show account deletion dialog
Future<void> showAccountDeletionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AccountDeletionDialog(),
  );
}

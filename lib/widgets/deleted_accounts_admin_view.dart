import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/deleted_accounts_tracking_service.dart';
import '../utils/app_theme.dart';

/// Admin widget to view deleted accounts history
/// Shows audit trail of all account deletions
class DeletedAccountsAdminView extends StatefulWidget {
  const DeletedAccountsAdminView({super.key});

  @override
  State<DeletedAccountsAdminView> createState() =>
      _DeletedAccountsAdminViewState();
}

class _DeletedAccountsAdminViewState extends State<DeletedAccountsAdminView> {
  final DeletedAccountsTrackingService _trackingService =
      DeletedAccountsTrackingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Accounts'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: StreamBuilder<List<DeletedAccount>>(
        stream: _trackingService.getDeletedAccounts(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final deletedAccounts = snapshot.data ?? [];

          if (deletedAccounts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No deleted accounts yet'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Total Deleted',
                          deletedAccounts.length.toString(),
                          Icons.people_outline,
                          Colors.red,
                        ),
                        _buildStatItem(
                          'This Month',
                          _getThisMonthCount(deletedAccounts).toString(),
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'This Week',
                          _getThisWeekCount(deletedAccounts).toString(),
                          Icons.date_range,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Deleted Accounts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: deletedAccounts.length,
                  itemBuilder: (context, index) {
                    final account = deletedAccounts[index];
                    return _buildDeletedAccountCard(account);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedAccountCard(DeletedAccount account) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final deletionDateStr = account.deletionDate != null
        ? dateFormat.format(account.deletionDate!)
        : 'Unknown date';

    Color roleColor;
    switch (account.userRole) {
      case 'shg':
        roleColor = Colors.green;
        break;
      case 'sme':
        roleColor = Colors.blue;
        break;
      case 'psa':
        roleColor = Colors.purple;
        break;
      case 'admin':
        roleColor = Colors.red;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Icon(
            _getRoleIcon(account.userRole),
            color: roleColor,
          ),
        ),
        title: Text(
          account.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${account.roleDisplayName} • Deleted $deletionDateStr',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('User ID', account.userId),
                const SizedBox(height: 8),
                _buildDetailRow('Email', account.userEmail),
                const SizedBox(height: 8),
                _buildDetailRow('Role', account.roleDisplayName),
                const SizedBox(height: 8),
                _buildDetailRow('Deletion Date', deletionDateStr),
                const SizedBox(height: 8),
                _buildDetailRow('Deleted By', account.deletedByDisplayName),
                const SizedBox(height: 8),
                _buildDetailRow('Reason', account.deletionReason),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'shg':
        return Icons.agriculture;
      case 'sme':
        return Icons.shopping_cart;
      case 'psa':
        return Icons.store;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  int _getThisMonthCount(List<DeletedAccount> accounts) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return accounts.where((account) {
      if (account.deletionDate == null) return false;
      return account.deletionDate!.isAfter(startOfMonth);
    }).length;
  }

  int _getThisWeekCount(List<DeletedAccount> accounts) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return accounts.where((account) {
      if (account.deletionDate == null) return false;
      return account.deletionDate!.isAfter(startOfWeekDate);
    }).length;
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/admin_user.dart';
import '../../services/admin_auth_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final AdminUser adminUser;

  const TeamManagementScreen({super.key, required this.adminUser});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuthService _authService = AdminAuthService();

  bool _isLoading = true;
  List<AdminUser> _teamMembers = [];
  List<AdminUser> _filteredMembers = [];

  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await _firestore.collection('admin_users').get();

      final members = <AdminUser>[];
      for (var doc in querySnapshot.docs) {
        members.add(AdminUser.fromFirestore(doc.data(), doc.id));
      }

      // Sort by created date (newest first)
      members.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _teamMembers = members;
        _filteredMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load team members: $e')),
        );
      }
    }
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _teamMembers.where((member) {
        // Filter by role
        if (_selectedRole != 'all' &&
            member.role.toString().split('.').last != _selectedRole) {
          return false;
        }

        // Filter by status
        if (_selectedStatus == 'active' && !member.isActive) return false;
        if (_selectedStatus == 'inactive' && member.isActive) return false;

        // Filter by search query
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final name = member.name.toLowerCase();
          final email = member.email.toLowerCase();
          return name.contains(query) || email.contains(query);
        }

        return true;
      }).toList();
    });
  }

  void _showCreateAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    AdminRole selectedRole = AdminRole.moderator;
    List<String> selectedPermissions = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Admin Account'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      hintText: 'Minimum 8 characters',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Role:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AdminRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: AdminRole.values
                        .where(
                          (role) =>
                              role != AdminRole.superAdmin ||
                              widget.adminUser.role == AdminRole.superAdmin,
                        )
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                          selectedPermissions = List.from(
                            value.defaultPermissions,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPermissionCheckbox(
                          'User Management',
                          AdminPermissions.manageUsers,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'PSA Verification',
                          AdminPermissions.verifyPsa,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'Product Moderation',
                          AdminPermissions.moderateProducts,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'Order Management',
                          AdminPermissions.manageOrders,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'View Analytics',
                          AdminPermissions.viewAnalytics,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'Handle Complaints',
                          AdminPermissions.handleComplaints,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'Suspend Accounts',
                          AdminPermissions.suspendAccounts,
                          selectedPermissions,
                          setDialogState,
                        ),
                        _buildPermissionCheckbox(
                          'Export Data',
                          AdminPermissions.exportData,
                          selectedPermissions,
                          setDialogState,
                        ),
                        if (widget.adminUser.role == AdminRole.superAdmin) ...[
                          _buildPermissionCheckbox(
                            'Manage Team',
                            AdminPermissions.manageAdmins,
                            selectedPermissions,
                            setDialogState,
                          ),
                          _buildPermissionCheckbox(
                            'System Settings',
                            AdminPermissions.systemSettings,
                            selectedPermissions,
                            setDialogState,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${selectedPermissions.length} permissions selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                if (passwordController.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 8 characters'),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createAdmin(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  selectedRole,
                  selectedPermissions,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(
    String label,
    String permission,
    List<String> selectedPermissions,
    StateSetter setDialogState,
  ) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: selectedPermissions.contains(permission),
      onChanged: (value) {
        setDialogState(() {
          if (value == true) {
            if (!selectedPermissions.contains(permission)) {
              selectedPermissions.add(permission);
            }
          } else {
            selectedPermissions.remove(permission);
          }
        });
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _createAdmin(
    String name,
    String email,
    String password,
    AdminRole role,
    List<String> permissions,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create admin account
      await _authService.createAdminAccount(
        email: email,
        password: password,
        name: name,
        role: role,
        permissions: permissions,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Admin account created for $name'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTeamMembers();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create admin account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(AdminUser admin) async {
    final action = admin.isActive ? 'deactivate' : 'activate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Account'),
        content: Text(
          'Are you sure you want to $action ${admin.name}\'s account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: admin.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('admin_users').doc(admin.id).update({
          'is_active': !admin.isActive,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Account ${admin.isActive ? 'deactivated' : 'activated'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadTeamMembers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')),
          );
        }
      }
    }
  }

  void _showAdminDetails(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', admin.email),
              _buildDetailRow('Role', admin.role.displayName),
              _buildDetailRow(
                'Status',
                admin.isActive ? 'Active' : 'Inactive',
                valueColor: admin.isActive ? Colors.green : Colors.red,
              ),
              _buildDetailRow(
                'Created',
                DateFormat('MMM dd, yyyy').format(admin.createdAt),
              ),
              if (admin.lastLoginAt != null)
                _buildDetailRow(
                  'Last Login',
                  DateFormat('MMM dd, yyyy HH:mm').format(admin.lastLoginAt!),
                ),
              const Divider(),
              const Text(
                'Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (admin.permissions.isEmpty)
                const Text(
                  'No permissions assigned',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...admin.permissions.map(
                  (perm) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPermissionLabel(perm),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  String _getPermissionLabel(String permission) {
    const labels = {
      'manage_users': 'User Management',
      'manage_admins': 'Manage Team',
      'verify_psa': 'PSA Verification',
      'moderate_products': 'Product Moderation',
      'manage_orders': 'Order Management',
      'view_analytics': 'View Analytics',
      'system_settings': 'System Settings',
      'suspend_accounts': 'Suspend Accounts',
      'handle_complaints': 'Handle Complaints',
      'process_payments': 'Process Payments',
      'export_data': 'Export Data',
    };
    return labels[permission] ?? permission;
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              style: TextStyle(fontSize: 13, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  //   String _formatDate(DateTime date) {
  //     return DateFormat('MMM dd, yyyy').format(date);
  //   }

  @override
  Widget build(BuildContext context) {
    final activeCount = _teamMembers.where((m) => m.isActive).length;
    final inactiveCount = _teamMembers.length - activeCount;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Team Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeamMembers,
          ),
        ],
      ),
      floatingActionButton:
          widget.adminUser.hasPermission(AdminPermissions.manageAdmins)
          ? FloatingActionButton.extended(
              onPressed: _showCreateAdminDialog,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Team Member'),
            )
          : null,
      body: Column(
        children: [
          // Stats Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Team',
                    _teamMembers.length.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    activeCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Inactive',
                    inactiveCount.toString(),
                    Icons.cancel,
                    Colors.red,
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
                    hintText: 'Search by name or email...',
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Filter by Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Roles'),
                          ),
                          ...AdminRole.values.map(
                            (role) => DropdownMenuItem(
                              value: role.toString().split('.').last,
                              child: Text(role.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                          _filterMembers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
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
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                          _filterMembers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Team Members List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No team members found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTeamMembers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = _filteredMembers[index];
                        return _buildTeamMemberCard(member);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(AdminUser member) {
    final isCurrentUser = member.id == widget.adminUser.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !member.isActive
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAdminDetails(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: member.isActive
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade400,
                child: Text(
                  member.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (!member.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.role.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${member.permissions.length} permissions',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              if (widget.adminUser.hasPermission(
                    AdminPermissions.manageAdmins,
                  ) &&
                  !isCurrentUser)
                IconButton(
                  icon: Icon(
                    member.isActive ? Icons.block : Icons.check_circle,
                    color: member.isActive ? Colors.red : Colors.green,
                  ),
                  onPressed: () => _toggleAdminStatus(member),
                  tooltip: member.isActive ? 'Deactivate' : 'Activate',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

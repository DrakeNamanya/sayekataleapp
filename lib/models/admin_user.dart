/// Admin user model with role-based permissions
class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    this.isActive = true,
    this.mustChangePassword = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUser.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return AdminUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.toString() == 'AdminRole.${data['role']}',
        orElse: () => AdminRole.moderator,
      ),
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : [],
      isActive: data['is_active'] ?? true,
      mustChangePassword: data['must_change_password'] ?? false,
      createdAt: parseDateTime(data['created_at']),
      lastLoginAt: data['last_login_at'] != null
          ? parseDateTime(data['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  /// Check if admin has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission) ||
        role == AdminRole.superAdmin; // Super admin has all permissions
  }
}

enum AdminRole {
  superAdmin, // Full system access
  admin, // Most administrative tasks
  moderator, // Content moderation only
  analyst, // View-only analytics
  finance, // Financial operations - payments to PSA/SHG
  customerRelations, // Handle user complaints and issues
  engineer, // Technical support and maintenance
}

extension AdminRoleExtension on AdminRole {
  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.moderator:
        return 'Moderator';
      case AdminRole.analyst:
        return 'Analyst';
      case AdminRole.finance:
        return 'Finance Officer';
      case AdminRole.customerRelations:
        return 'Customer Relations';
      case AdminRole.engineer:
        return 'Engineer';
    }
  }

  /// Default permissions for each role
  List<String> get defaultPermissions {
    switch (this) {
      case AdminRole.superAdmin:
        return [
          'manage_users',
          'manage_admins',
          'manage_staff',
          'verify_psa',
          'moderate_products',
          'manage_orders',
          'view_analytics',
          'system_settings',
          'suspend_accounts',
          'handle_complaints',
          'process_payments',
          'export_data',
        ];
      case AdminRole.admin:
        return [
          'manage_users',
          'verify_psa',
          'moderate_products',
          'manage_orders',
          'view_analytics',
          'suspend_accounts',
          'handle_complaints',
          'export_data',
        ];
      case AdminRole.moderator:
        return [
          'verify_psa',
          'moderate_products',
          'view_analytics',
          'handle_complaints',
        ];
      case AdminRole.analyst:
        return ['view_analytics', 'export_data'];
      case AdminRole.finance:
        return [
          'view_analytics',
          'manage_orders',
          'process_payments',
          'export_data',
        ];
      case AdminRole.customerRelations:
        return ['view_analytics', 'handle_complaints', 'manage_users'];
      case AdminRole.engineer:
        return ['view_analytics', 'system_settings'];
    }
  }
}

/// Admin permissions constants
class AdminPermissions {
  static const String manageUsers = 'manage_users';
  static const String manageAdmins = 'manage_admins';
  static const String manageStaff = 'manage_staff';
  static const String verifyPsa = 'verify_psa';
  static const String moderateProducts = 'moderate_products';
  static const String manageOrders = 'manage_orders';
  static const String viewAnalytics = 'view_analytics';
  static const String systemSettings = 'system_settings';
  static const String suspendAccounts = 'suspend_accounts';
  static const String handleComplaints = 'handle_complaints';
  static const String processPayments = 'process_payments';
  static const String exportData = 'export_data';
}

/// User complaint/issue model
class UserComplaint {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // shg, psa, customer
  final String subject;
  final String description;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? assignedTo; // Admin ID
  final String? response;
  final String? respondedBy; // Admin ID
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachments; // Image URLs

  UserComplaint({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.subject,
    required this.description,
    required this.category,
    this.status = ComplaintStatus.pending,
    this.priority = ComplaintPriority.medium,
    this.assignedTo,
    this.response,
    this.respondedBy,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  factory UserComplaint.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return UserComplaint(
      id: id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userRole: data['user_role'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      category: ComplaintCategory.values.firstWhere(
        (e) => e.toString() == 'ComplaintCategory.${data['category']}',
        orElse: () => ComplaintCategory.other,
      ),
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == 'ComplaintStatus.${data['status']}',
        orElse: () => ComplaintStatus.pending,
      ),
      priority: ComplaintPriority.values.firstWhere(
        (e) => e.toString() == 'ComplaintPriority.${data['priority']}',
        orElse: () => ComplaintPriority.medium,
      ),
      assignedTo: data['assigned_to'],
      response: data['response'],
      respondedBy: data['responded_by'],
      respondedAt: data['responded_at'] != null
          ? parseDateTime(data['responded_at'])
          : null,
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'subject': subject,
      'description': description,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'assigned_to': assignedTo,
      'response': response,
      'responded_by': respondedBy,
      'responded_at': respondedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments,
    };
  }
}

enum ComplaintCategory { payment, delivery, product, account, technical, other }

enum ComplaintStatus { pending, inProgress, resolved, closed }

enum ComplaintPriority { low, medium, high, urgent }

extension ComplaintCategoryExtension on ComplaintCategory {
  String get displayName {
    switch (this) {
      case ComplaintCategory.payment:
        return 'Payment Issue';
      case ComplaintCategory.delivery:
        return 'Delivery Problem';
      case ComplaintCategory.product:
        return 'Product Quality';
      case ComplaintCategory.account:
        return 'Account Issue';
      case ComplaintCategory.technical:
        return 'Technical Support';
      case ComplaintCategory.other:
        return 'Other';
    }
  }
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }
}

extension ComplaintPriorityExtension on ComplaintPriority {
  String get displayName {
    switch (this) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
      case ComplaintPriority.urgent:
        return 'Urgent';
    }
  }
}

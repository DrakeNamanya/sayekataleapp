class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? actionUrl;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.actionUrl,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    // Helper function to parse DateTime from various formats
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return AppNotification(
      id: id,
      userId: data['user_id'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.general,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      actionUrl: data['action_url'],
      relatedId: data['related_id'],
      isRead: data['is_read'] ?? false,
      createdAt: parseDateTime(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'action_url': actionUrl,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum NotificationType {
  order,
  payment,
  message,
  delivery,
  promotion,
  alert,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.order:
        return 'Order Update';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.message:
        return 'New Message';
      case NotificationType.delivery:
        return 'Delivery';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.general:
        return 'Notification';
    }
  }
}

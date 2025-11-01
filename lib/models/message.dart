class Conversation {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromFirestore(Map<String, dynamic> data, String id) {
    return Conversation(
      id: id,
      participantIds: List<String>.from(data['participant_ids'] ?? []),
      participantNames: Map<String, String>.from(data['participant_names'] ?? {}),
      lastMessage: data['last_message'],
      lastMessageTime: data['last_message_time'] != null
          ? DateTime.parse(data['last_message_time'])
          : null,
      unreadCount: Map<String, int>.from(data['unread_count'] ?? {}),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participant_ids': participantIds,
      'participant_names': participantNames,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      conversationId: data['conversation_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      attachmentUrl: data['attachment_url'],
      isRead: data['is_read'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'attachment_url': attachmentUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
}

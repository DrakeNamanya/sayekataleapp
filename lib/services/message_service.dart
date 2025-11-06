import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';

/// Service for managing conversations and messages
class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // CONVERSATION MANAGEMENT
  // ============================================================================

  /// Get or create a conversation between two users
  Future<Conversation> getOrCreateConversation({
    required String user1Id,
    required String user1Name,
    required String user2Id,
    required String user2Name,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('💬 Getting/Creating conversation between $user1Name and $user2Name');
      }

      // Check if conversation already exists
      final existingQuery = await _firestore
          .collection('conversations')
          .where('participant_ids', arrayContains: user1Id)
          .get();

      // Find conversation with both users
      for (var doc in existingQuery.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participant_ids'] ?? []);
        if (participantIds.contains(user2Id)) {
          if (kDebugMode) {
            debugPrint('✅ Found existing conversation: ${doc.id}');
          }
          return Conversation.fromFirestore(data, doc.id);
        }
      }

      // Create new conversation if not found
      final now = DateTime.now().toIso8601String();
      final conversationData = {
        'participant_ids': [user1Id, user2Id],
        'participant_names': {
          user1Id: user1Name,
          user2Id: user2Name,
        },
        'last_message': null,
        'last_message_time': null,
        'unread_count': {
          user1Id: 0,
          user2Id: 0,
        },
        'created_at': now,
        'updated_at': now,
      };

      final docRef = await _firestore.collection('conversations').add(conversationData);

      if (kDebugMode) {
        debugPrint('✅ Created new conversation: ${docRef.id}');
      }

      // Get the created document to return proper timestamps
      final createdDoc = await docRef.get();
      return Conversation.fromFirestore(createdDoc.data()!, docRef.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting/creating conversation: $e');
      }
      rethrow;
    }
  }

  /// Stream all conversations for a user
  Stream<List<Conversation>> streamUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participant_ids', arrayContains: userId)
        // Removed .orderBy() to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
      // Get conversations
      final conversations = snapshot.docs.map((doc) {
        return Conversation.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      // Sort in memory by updated_at (most recent first)
      conversations.sort((a, b) {
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      return conversations;
    });
  }

  /// Get conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      
      if (doc.exists) {
        return Conversation.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting conversation: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // MESSAGE OPERATIONS
  // ============================================================================

  /// Send a message in a conversation
  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Sending message in conversation: $conversationId');
      }

      // Create message
      final now = DateTime.now().toIso8601String();
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'type': type.toString().split('.').last,
        'attachment_url': attachmentUrl,
        'is_read': false,
        'created_at': now,
      };

      final docRef = await _firestore.collection('messages').add(messageData);

      // Update conversation
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final otherUserId = conversation.participantIds.firstWhere(
          (id) => id != senderId,
        );

        final newUnreadCount = Map<String, int>.from(conversation.unreadCount);
        newUnreadCount[otherUserId] = (newUnreadCount[otherUserId] ?? 0) + 1;

        await _firestore.collection('conversations').doc(conversationId).update({
          'last_message': content.length > 100 ? '${content.substring(0, 100)}...' : content,
          'last_message_time': now,
          'unread_count': newUnreadCount,
          'updated_at': now,
        });
      }

      if (kDebugMode) {
        debugPrint('✅ Message sent with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending message: $e');
      }
      rethrow;
    }
  }

  /// Stream messages in a conversation
  Stream<List<Message>> streamConversationMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversation_id', isEqualTo: conversationId)
        // Removed .orderBy() to avoid composite index requirement
        .snapshots()
        .map((snapshot) {
      // Get messages
      final messages = snapshot.docs.map((doc) {
        return Message.fromFirestore(doc.data(), doc.id);
      }).toList();
      
      // Sort in memory by created_at (oldest first for chat display)
      messages.sort((a, b) {
        return a.createdAt.compareTo(b.createdAt);
      });
      
      return messages;
    });
  }

  /// Mark messages as read for a user in a conversation
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Get all messages in this conversation (removed second .where() to avoid composite index)
      final querySnapshot = await _firestore
          .collection('messages')
          .where('conversation_id', isEqualTo: conversationId)
          .get();

      // Filter unread messages not sent by this user (in memory)
      final messagesToMark = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['is_read'] == false && data['sender_id'] != userId;
      }).toList();

      if (messagesToMark.isEmpty) return;

      // Mark messages as read
      final batch = _firestore.batch();
      for (var doc in messagesToMark) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();

      // Update conversation unread count
      await _firestore.collection('conversations').doc(conversationId).update({
        'unread_count.$userId': 0,
      });

      if (kDebugMode) {
        debugPrint('✅ Marked ${messagesToMark.length} messages as read');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking messages as read: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // UNREAD COUNT
  // ============================================================================

  /// Get total unread message count for a user (across all conversations)
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final conversations = await _firestore
          .collection('conversations')
          .where('participant_ids', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (var doc in conversations.docs) {
        final data = doc.data();
        final unreadCount = Map<String, int>.from(data['unread_count'] ?? {});
        totalUnread += unreadCount[userId] ?? 0;
      }

      return totalUnread;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting total unread count: $e');
      }
      return 0;
    }
  }

  /// Stream total unread count for a user with real-time updates
  Stream<int> streamTotalUnreadCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = Map<String, int>.from(data['unread_count'] ?? {});
        totalUnread += unreadCount[userId] ?? 0;
      }
      return totalUnread;
    });
  }

  // ============================================================================
  // MESSAGE DELETION
  // ============================================================================

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();

      if (kDebugMode) {
        debugPrint('✅ Message $messageId deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting message: $e');
      }
      rethrow;
    }
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('conversation_id', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Conversation $conversationId and ${messagesSnapshot.docs.length} messages deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting conversation: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the other participant in a conversation
  String getOtherParticipantId(Conversation conversation, String currentUserId) {
    return conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get the other participant's name
  String getOtherParticipantName(Conversation conversation, String currentUserId) {
    final otherId = getOtherParticipantId(conversation, currentUserId);
    return conversation.participantNames[otherId] ?? 'Unknown';
  }

  /// Check if user has unread messages in a conversation
  bool hasUnreadMessages(Conversation conversation, String userId) {
    return (conversation.unreadCount[userId] ?? 0) > 0;
  }
}

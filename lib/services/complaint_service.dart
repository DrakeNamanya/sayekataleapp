import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_complaint.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit a new complaint
  Future<String> submitComplaint({
    required String userId,
    required String userName,
    String? userEmail,
    String? userPhone,
    required String subject,
    required String description,
    required ComplaintCategory category,
    required ComplaintPriority priority,
    List<String>? attachmentUrls,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 COMPLAINT SERVICE - submitComplaint called');
        debugPrint('   - user_id: "$userId"');
        debugPrint('   - user_id type: ${userId.runtimeType}');
        debugPrint('   - user_id length: ${userId.length}');
        debugPrint('   - user_name: $userName');
        debugPrint('   - subject: $subject');
      }

      final complaint = {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'subject': subject,
        'description': description,
        'category': category.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'status': 'pending',
        'attachments': attachmentUrls ?? [],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('user_complaints').add(complaint);
      
      if (kDebugMode) {
        debugPrint('✅ COMPLAINT SERVICE - Complaint submitted successfully');
        debugPrint('   - Document ID: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ COMPLAINT SERVICE - ERROR in submitComplaint:');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }
      throw Exception('Failed to submit complaint: $e');
    }
  }

  /// Get user's complaints
  Future<List<Map<String, dynamic>>> getUserComplaints(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 COMPLAINT SERVICE - getUserComplaints called');
        debugPrint('   - Looking for complaints with user_id: "$userId"');
        debugPrint('   - User ID type: ${userId.runtimeType}');
        debugPrint('   - User ID length: ${userId.length}');
      }

      final snapshot = await _firestore
          .collection('user_complaints')
          .where('user_id', isEqualTo: userId)
          .get();

      if (kDebugMode) {
        debugPrint('📊 COMPLAINT SERVICE - Query executed');
        debugPrint('   - Documents found: ${snapshot.docs.length}');
        debugPrint('   - Total size: ${snapshot.size}');
        debugPrint('   - Query metadata: ${snapshot.metadata}');
      }

      // Debug: Print first few documents to see structure
      if (kDebugMode && snapshot.docs.isNotEmpty) {
        debugPrint('📄 COMPLAINT SERVICE - Sample document data:');
        for (var i = 0; i < snapshot.docs.length && i < 3; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          debugPrint('   Document $i:');
          debugPrint('     - ID: ${doc.id}');
          debugPrint('     - user_id: "${data['user_id']}"');
          debugPrint('     - subject: ${data['subject']}');
          debugPrint('     - status: ${data['status']}');
          debugPrint('     - created_at: ${data['created_at']}');
          debugPrint('     - response: ${data['response'] ?? "null"}');
        }
      }

      final complaints = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      
      // Sort in memory to avoid composite index requirement
      complaints.sort((a, b) {
        final aTime = a['created_at']?.toString() ?? '';
        final bTime = b['created_at']?.toString() ?? '';
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      if (kDebugMode) {
        debugPrint('✅ COMPLAINT SERVICE - Returning ${complaints.length} complaints');
      }

      return complaints;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ COMPLAINT SERVICE - ERROR in getUserComplaints:');
        debugPrint('   - Error: $e');
        debugPrint('   - Stack trace: $stackTrace');
      }
      throw Exception('Failed to get complaints: $e');
    }
  }

  /// Get complaint by ID
  Future<Map<String, dynamic>?> getComplaint(String complaintId) async {
    try {
      final doc = await _firestore
          .collection('user_complaints')
          .doc(complaintId)
          .get();

      if (!doc.exists) return null;

      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    } catch (e) {
      throw Exception('Failed to get complaint: $e');
    }
  }
}

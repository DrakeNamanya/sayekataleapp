import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logger/logger.dart';
import '../models/psa_verification.dart';

final _logger = Logger();

class PSAVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'psa_verifications';

  /// Submit a new PSA verification request
  Future<void> submitVerification(PsaVerification verification) async {
    try {
      final data = verification.toFirestore();

      // Debug logging (only in debug mode)
      if (kDebugMode) {
        _logger.i('📝 Submitting verification to Firestore:');
        _logger.i('   PSA ID: ${data['psa_id']}');
        _logger.i('   Business: ${data['business_name']}');
        _logger.i('   Status: ${data['status']}');
        _logger.i(
          '   Business License URL: ${data['business_license_url'] ?? "NULL"}',
        );
        _logger.i(
          '   Tax ID Document URL: ${data['tax_id_document_url'] ?? "NULL"}',
        );
        _logger.i('   National ID URL: ${data['national_id_url'] ?? "NULL"}');
        _logger.i(
          '   Trade License URL: ${data['trade_license_url'] ?? "NULL"}',
        );
      }

      await _firestore.collection(_collection).add(data);

      if (kDebugMode) {
        _logger.i('✅ Verification submitted successfully to Firestore');
      }
    } catch (e, st) {
      // Always log errors (include stack trace)
      _logger.e(
        '❌ Failed to submit verification: $e',
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to submit verification: $e');
    }
  }

  /// Update an existing PSA verification request
  Future<void> updateVerification(PsaVerification verification) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(verification.id)
          .update(verification.toFirestore());
    } catch (e, st) {
      _logger.e('Failed to update verification: $e', error: e, stackTrace: st);
      throw Exception('Failed to update verification: $e');
    }
  }

  /// Get PSA's verification status
  Future<PsaVerification?> getPsaVerification(String psaId) async {
    try {
      // Simple query without orderBy to avoid composite index requirement
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('psa_id', isEqualTo: psaId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Convert all documents to PsaVerification objects
      final verifications = querySnapshot.docs
          .map((doc) => PsaVerification.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort in memory by created_at (most recent first)
      verifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return verifications.first;
    } catch (e, st) {
      _logger.e('Failed to get verification: $e', error: e, stackTrace: st);
      throw Exception('Failed to get verification: $e');
    }
  }

  /// Stream PSA's verification status for real-time updates
  Stream<PsaVerification?> streamPsaVerification(String psaId) {
    // Simple query without orderBy to avoid composite index requirement
    return _firestore
        .collection(_collection)
        .where('psa_id', isEqualTo: psaId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          // Convert all documents to PsaVerification objects
          final verifications = snapshot.docs
              .map((doc) => PsaVerification.fromFirestore(doc.data(), doc.id))
              .toList();

          // Sort in memory by created_at (most recent first)
          verifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return verifications.first;
        });
  }

  /// Check if PSA has submitted verification
  Future<bool> hasSubmittedVerification(String psaId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('psa_id', isEqualTo: psaId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e, st) {
      _logger.w(
        'Error checking submission for psaId=$psaId: $e',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Check if PSA is verified (approved)
  Future<bool> isPsaVerified(String psaId) async {
    try {
      final verification = await getPsaVerification(psaId);
      return verification?.status == PsaVerificationStatus.approved;
    } catch (e, st) {
      _logger.w(
        'Error checking verification status for psaId=$psaId: $e',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Diagnostic utility to debug Firebase Storage permission issues
class FirebaseStorageDiagnostic {
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  /// Run comprehensive diagnostics
  static Future<void> runDiagnostics() async {
    if (kDebugMode) {
      debugPrint('🔍 ==========================================');
      debugPrint('🔍 FIREBASE STORAGE DIAGNOSTICS');
      debugPrint('🔍 ==========================================');
      
      // 1. Check Authentication
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ NOT AUTHENTICATED - User is null!');
        debugPrint('⚠️ This is likely the problem. User must be logged in to upload.');
        return;
      }
      
      debugPrint('✅ User is authenticated');
      debugPrint('   - User ID: ${user.uid}');
      debugPrint('   - Email: ${user.email ?? "No email"}');
      debugPrint('   - Is Anonymous: ${user.isAnonymous}');
      
      // 2. Check Firebase Storage Configuration
      debugPrint('');
      debugPrint('📦 Firebase Storage Configuration:');
      debugPrint('   - Bucket: ${_storage.bucket}');
      debugPrint('   - Max Upload Time: ${_storage.maxUploadRetryTime}');
      
      // 3. Test Storage Path Format
      debugPrint('');
      debugPrint('📁 Expected Storage Paths:');
      debugPrint('   - Profile: profiles/${user.uid}/profile_xxx.jpg');
      debugPrint('   - National ID: national_ids/${user.uid}/national_id_xxx.jpg');
      debugPrint('   - Products: products/${user.uid}/product_xxx.jpg');
      
      // 4. Get ID Token (for debugging auth)
      try {
        final idToken = await user.getIdToken();
        debugPrint('');
        debugPrint('🔑 ID Token Status:');
        debugPrint('   - Token exists: ${idToken != null}');
        debugPrint('   - Token length: ${idToken?.length ?? 0}');
      } catch (e) {
        debugPrint('❌ Error getting ID token: $e');
      }
      
      // 5. Check if Storage Rules are accessible (indirect test)
      debugPrint('');
      debugPrint('🔐 Testing Storage Access...');
      try {
        final testRef = _storage.ref('profiles/${user.uid}/test.txt');
        debugPrint('   - Test reference created successfully');
        debugPrint('   - Full path: ${testRef.fullPath}');
      } catch (e) {
        debugPrint('❌ Error creating storage reference: $e');
      }
      
      debugPrint('🔍 ==========================================');
    }
  }

  /// Check if user can upload to a specific path
  static Future<bool> canUploadToPath(String folder, String userId) async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        if (kDebugMode) {
          debugPrint('❌ Upload check failed: User not authenticated');
        }
        return false;
      }
      
      if (user.uid != userId) {
        if (kDebugMode) {
          debugPrint('❌ Upload check failed: User ID mismatch');
          debugPrint('   - Authenticated user: ${user.uid}');
          debugPrint('   - Requested userId: $userId');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('✅ Upload check passed for: $folder/$userId');
      }
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload check error: $e');
      }
      return false;
    }
  }
}

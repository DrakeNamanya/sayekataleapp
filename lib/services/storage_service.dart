import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


/// Standardized Firebase Storage upload service
/// Uses fixed path conventions matching security rules
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID (throws if not authenticated)
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  /// Upload profile picture
  /// Path: users/{uid}/profile/profile.jpg
  /// Security: Owner-only write, public read
  Future<String> uploadProfilePicture(Uint8List imageBytes) async {
    final uid = _currentUserId;
    
    // Standardized path matching Storage rules
    final ref = _storage.ref().child('users/$uid/profile/profile.jpg');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await ref.getDownloadURL();
  }

  /// Upload product image
  /// Path: products/{uid}/{productId}.jpg
  /// Security: Owner-only write, public read
  Future<String> uploadProductImage(
    Uint8List imageBytes,
    String productId,
  ) async {
    final uid = _currentUserId;
    
    // Standardized path matching Storage rules
    final ref = _storage.ref().child('products/$uid/$productId.jpg');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await ref.getDownloadURL();
  }

  /// Upload verification document (National ID, etc.)
  /// Path: users/{uid}/verification/{fileName}
  /// Security: Owner-only read/write (private)
  Future<String> uploadVerificationDocument(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final uid = _currentUserId;
    
    // Standardized path matching Storage rules
    final ref = _storage.ref().child('users/$uid/verification/$fileName');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await ref.getDownloadURL();
  }

  /// Upload order-related image
  /// Path: orders/{orderId}/{fileName}
  /// Security: Authenticated write, authenticated read
  Future<String> uploadOrderImage(
    Uint8List imageBytes,
    String orderId,
    String fileName,
  ) async {
    _currentUserId; // Ensure authenticated
    
    // Standardized path matching Storage rules
    final ref = _storage.ref().child('orders/$orderId/$fileName');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await ref.getDownloadURL();
  }

  /// Upload group/business document
  /// Path: groups/{groupId}/{fileName}
  /// Security: Authenticated write, authenticated read
  Future<String> uploadGroupDocument(
    Uint8List imageBytes,
    String groupId,
    String fileName,
  ) async {
    _currentUserId; // Ensure authenticated
    
    // Standardized path matching Storage rules
    final ref = _storage.ref().child('groups/$groupId/$fileName');
    
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await ref.getDownloadURL();
  }

  /// Delete a file from Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File may not exist or user may not have permission
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
    }
  }
}

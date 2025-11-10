import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload verification document to Firebase Storage
  /// Returns the download URL of the uploaded file
  /// Uses XFile for web compatibility
  Future<String> uploadVerificationDocument(
    String psaId,
    String documentType,
    XFile file,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Uploading document: $documentType for PSA: $psaId');
      }
      
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final ref = _storage.ref().child('psa_verifications/$psaId/$fileName');

      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      final ext = path.extension(file.path).toLowerCase();
      if (ext == '.pdf') {
        contentType = 'application/pdf';
      } else if (ext == '.jpg' || ext == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == '.png') {
        contentType = 'image/png';
      }

      // Always use putData with bytes from XFile (works on both web and mobile)
      if (kDebugMode) {
        debugPrint('📱 Uploading file with putData method');
      }
      
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: contentType,
      );
      final uploadTask = ref.putData(bytes, metadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Document uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload error: $e');
      }
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload product image to Firebase Storage
  /// Returns the download URL of the uploaded file
  /// Uses XFile for web compatibility
  Future<String> uploadProductImage(
    String farmId,
    String productId,
    XFile file,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Uploading product image for product: $productId');
      }
      
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final ref = _storage.ref().child('products/$farmId/$fileName');

      // Determine content type
      String contentType = 'image/jpeg';
      final ext = path.extension(file.path).toLowerCase();
      if (ext == '.png') {
        contentType = 'image/png';
      } else if (ext == '.gif') {
        contentType = 'image/gif';
      } else if (ext == '.webp') {
        contentType = 'image/webp';
      }

      // Always use putData with bytes from XFile (works on both web and mobile)
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: contentType,
      );
      final uploadTask = ref.putData(bytes, metadata);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Product image uploaded successfully');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload error: $e');
      }
      throw Exception('Failed to upload product image: $e');
    }
  }

  /// Upload multiple product images
  /// Uses XFile for web compatibility
  Future<List<String>> uploadProductImages(
    String farmId,
    String productId,
    List<XFile> files,
  ) async {
    try {
      final urls = <String>[];
      for (final file in files) {
        final url = await uploadProductImage(farmId, productId, file);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload product images: $e');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}

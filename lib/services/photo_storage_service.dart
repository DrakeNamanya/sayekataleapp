import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading and managing review photos in Firebase Storage
class PhotoStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick multiple images from gallery (up to 5 photos)
  Future<List<XFile>> pickImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      // Limit to maxImages
      if (images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      
      return images;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking images: $e');
      }
      rethrow;
    }
  }

  /// Pick single image from camera
  Future<XFile?> takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error taking picture: $e');
      }
      rethrow;
    }
  }

  /// Upload review photos to Firebase Storage
  /// Returns list of download URLs
  Future<List<String>> uploadReviewPhotos({
    required String reviewId,
    required List<XFile> photos,
    Function(int uploaded, int total)? onProgress,
  }) async {
    final List<String> downloadUrls = [];
    
    try {
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final fileName = 'review_${reviewId}_photo_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('reviews/$reviewId/$fileName');
        
        // Upload file
        UploadTask uploadTask;
        if (kIsWeb) {
          // Web platform - upload from bytes
          final bytes = await photo.readAsBytes();
          uploadTask = ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          // Mobile platform - upload from file
          uploadTask = ref.putFile(
            File(photo.path),
            SettableMetadata(contentType: 'image/jpeg'),
          );
        }
        
        // Wait for upload to complete
        final snapshot = await uploadTask;
        
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        // Report progress
        if (onProgress != null) {
          onProgress(i + 1, photos.length);
        }
      }
      
      return downloadUrls;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading photos: $e');
      }
      rethrow;
    }
  }

  /// Delete review photos from Firebase Storage
  Future<void> deleteReviewPhotos({
    required String reviewId,
    required List<String> photoUrls,
  }) async {
    try {
      for (final url in photoUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Continue deleting other photos even if one fails
          if (kDebugMode) {
            debugPrint('Error deleting photo $url: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in deleteReviewPhotos: $e');
      }
      rethrow;
    }
  }

  /// Get file size in KB
  Future<int> getFileSizeKB(XFile file) async {
    try {
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        return (bytes.length / 1024).round();
      } else {
        final fileSize = await File(file.path).length();
        return (fileSize / 1024).round();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting file size: $e');
      }
      return 0;
    }
  }

  /// Validate photo before upload
  Future<bool> validatePhoto(XFile photo, {int maxSizeKB = 5120}) async {
    try {
      final sizeKB = await getFileSizeKB(photo);
      return sizeKB <= maxSizeKB && sizeKB > 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error validating photo: $e');
      }
      return false;
    }
  }
}

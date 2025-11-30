import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'firebase_storage_diagnostic.dart';

/// Service for managing image uploads to Firebase Storage
/// Handles compression, thumbnails, and storage organization
class ImageStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image from XFile (cross-platform)
  Future<String> uploadImageFromXFile({
    required XFile imageFile,
    required String folder,
    required String userId,
    String? customName,
    bool compress = true,
    bool useUserSubfolder = true, // NEW: Control userId subfolder
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '📂 Starting upload: folder=$folder, userId=$userId, path=${imageFile.path}',
        );

        // Run diagnostics to help debug permission issues
        await FirebaseStorageDiagnostic.runDiagnostics();

        // Check if user can upload to this path
        final canUpload = await FirebaseStorageDiagnostic.canUploadToPath(
          folder,
          userId,
        );
        if (!canUpload) {
          throw Exception(
            'Permission check failed. See debug logs for details.',
          );
        }
      }

      // Verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception(
          'User must be logged in to upload images. Please login and try again.',
        );
      }

      // 🔍 DEBUG: Log UID comparison
      if (kDebugMode) {
        debugPrint('🔍 UID COMPARISON:');
        debugPrint('   Firebase Auth UID: ${currentUser.uid}');
        debugPrint('   Provided userId: $userId');
        debugPrint('   Match: ${currentUser.uid == userId}');
      }

      if (currentUser.uid != userId) {
        throw Exception(
          'User ID mismatch. Cannot upload to another user\'s folder. '
          'Current UID: ${currentUser.uid}, Provided: $userId',
        );
      }

      // Read bytes from XFile
      if (kDebugMode) {
        debugPrint('📖 Reading bytes from XFile...');
      }
      final bytes = await imageFile.readAsBytes();
      if (kDebugMode) {
        debugPrint('✅ Read ${bytes.length} bytes from XFile');
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final filename = customName ?? '${userId}_$timestamp$extension';
      if (kDebugMode) {
        debugPrint('📝 Generated filename: $filename');
      }

      // Compress if requested
      Uint8List bytesToUpload = bytes;
      if (compress) {
        if (kDebugMode) {
          debugPrint('🗜️ Compressing image...');
        }
        bytesToUpload = await compressImageBytes(bytes);
        if (kDebugMode) {
          debugPrint('✅ Compressed to ${bytesToUpload.length} bytes');
        }
      }

      // Create storage path
      // For PSA verifications, upload directly to folder without userId subfolder
      final storagePath = useUserSubfolder 
          ? '$folder/$userId/$filename'
          : '$folder/$filename';
      if (kDebugMode) {
        debugPrint('📁 Storage path: $storagePath');
        debugPrint('   Use user subfolder: $useUserSubfolder');
      }
      final storageRef = _storage.ref().child(storagePath);

      // Upload bytes
      if (kDebugMode) {
        debugPrint('☁️ Uploading to Firebase Storage...');
      }
      final uploadTask = await storageRef.putData(bytesToUpload);
      if (kDebugMode) {
        debugPrint('✅ Upload task completed');
      }

      // Get download URL
      if (kDebugMode) {
        debugPrint('🔗 Getting download URL...');
      }
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('✅ Image uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading image: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images from XFiles
  ///
  /// Returns list of download URLs in the same order as input files
  Future<List<String>> uploadMultipleImagesFromXFiles({
    required List<XFile> images,
    required String folder,
    required String userId,
    bool compress = true,
  }) async {
    try {
      final List<String> downloadUrls = [];

      for (int i = 0; i < images.length; i++) {
        final extension = path.extension(images[i].path);
        final url = await uploadImageFromXFile(
          imageFile: images[i],
          folder: folder,
          userId: userId,
          customName:
              '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i$extension',
          compress: compress,
        );
        downloadUrls.add(url);
      }

      if (kDebugMode) {
        debugPrint('✅ Uploaded ${downloadUrls.length} images successfully');
      }

      return downloadUrls;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading multiple images: $e');
      }
      throw Exception('Failed to upload images: $e');
    }
  }

  /// Compress image bytes to reduce file size (cross-platform)
  ///
  /// [bytes] - Original image bytes
  /// [quality] - JPEG quality (0-100, default: 85)
  /// [maxWidth] - Maximum width in pixels (default: 1200)
  ///
  /// Returns compressed image bytes
  Future<Uint8List> compressImageBytes(
    Uint8List bytes, {
    int quality = 85,
    int maxWidth = 1200,
  }) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if larger than maxWidth
      img.Image resized = image;
      if (image.width > maxWidth) {
        resized = img.copyResize(
          image,
          width: maxWidth,
          interpolation: img.Interpolation.linear,
        );
      }

      // Compress as JPEG
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: quality),
      );

      if (kDebugMode) {
        final originalSize = bytes.length / 1024;
        final compressedSize = compressedBytes.length / 1024;
        final reduction = ((1 - compressedSize / originalSize) * 100)
            .toStringAsFixed(1);
        debugPrint(
          '✅ Image compressed: ${originalSize.toStringAsFixed(1)}KB → ${compressedSize.toStringAsFixed(1)}KB ($reduction% reduction)',
        );
      }

      return compressedBytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error compressing image, using original: $e');
      }
      // Return original bytes if compression fails
      return bytes;
    }
  }

  /// Generate thumbnail from image bytes (cross-platform)
  ///
  /// [bytes] - Original image bytes
  /// [width] - Thumbnail width (default: 200)
  /// [quality] - JPEG quality (default: 80)
  ///
  /// Returns thumbnail bytes
  Future<Uint8List> generateThumbnailBytes(
    Uint8List bytes, {
    int width = 200,
    int quality = 80,
  }) async {
    try {
      // Decode image
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize to thumbnail size
      final thumbnail = img.copyResize(
        image,
        width: width,
        interpolation: img.Interpolation.linear,
      );

      // Compress as JPEG
      final thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: quality),
      );

      if (kDebugMode) {
        debugPrint('✅ Thumbnail generated: ${thumbnailBytes.length / 1024}KB');
      }

      return thumbnailBytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating thumbnail: $e');
      }
      throw Exception('Failed to generate thumbnail: $e');
    }
  }

  /// Delete image from Firebase Storage
  ///
  /// [imageUrl] - Full download URL of the image
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract storage path from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      if (kDebugMode) {
        debugPrint('✅ Image deleted: $imageUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting image: $e');
      }
      // Don't throw error on delete failure - image might already be deleted
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }

      if (kDebugMode) {
        debugPrint('✅ Deleted ${imageUrls.length} images');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting images: $e');
      }
    }
  }

  /// Get download URL from storage path
  ///
  /// [storagePath] - Path in Firebase Storage (e.g., 'products/user123/image.jpg')
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting download URL: $e');
      }
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Upload image with both full size and thumbnail from XFile
  ///
  /// Returns map with 'full' and 'thumb' URLs
  Future<Map<String, String>> uploadImageWithThumbnailFromXFile({
    required XFile imageFile,
    required String folder,
    required String userId,
    String? customName,
  }) async {
    try {
      // Read bytes
      final bytes = await imageFile.readAsBytes();

      // Generate thumbnail bytes
      final thumbnailBytes = await generateThumbnailBytes(bytes);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final filename = customName ?? '${userId}_$timestamp$extension';

      // Compress full size
      final compressedBytes = await compressImageBytes(bytes);

      // Create storage refs
      final fullRef = _storage.ref().child('$folder/$userId/$filename');
      final thumbRef = _storage.ref().child(
        '$folder/thumbnails/$userId/thumb_$filename',
      );

      // Upload both
      final fullTask = await fullRef.putData(compressedBytes);
      final thumbTask = await thumbRef.putData(thumbnailBytes);

      // Get URLs
      final fullUrl = await fullTask.ref.getDownloadURL();
      final thumbUrl = await thumbTask.ref.getDownloadURL();

      return {'full': fullUrl, 'thumb': thumbUrl};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading image with thumbnail: $e');
      }
      throw Exception('Failed to upload image with thumbnail: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service for picking images from gallery or camera (cross-platform)
/// Returns XFile for platform-agnostic image handling
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick a single image from gallery
  /// 
  /// Returns XFile if image selected, null if cancelled
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) {
        if (kDebugMode) {
          debugPrint('ℹ️ Image selection cancelled');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ Image selected from gallery: ${image.path}');
      }

      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error picking image from gallery: $e');
      }
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Take a photo with camera
  /// 
  /// Returns XFile if photo taken, null if cancelled
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null) {
        if (kDebugMode) {
          debugPrint('ℹ️ Camera capture cancelled');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ Photo captured: ${image.path}');
      }

      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error taking photo: $e');
      }
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Show dialog to choose image source (camera or gallery)
  /// 
  /// Returns XFile if image selected, null if cancelled
  Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await takePhoto();
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from existing photos'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImageFromGallery();
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Show simple image source bottom sheet
  /// 
  /// Returns XFile if image selected, null if cancelled
  Future<XFile?> showImageSourceBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      context,
                      icon: Icons.photo_camera,
                      label: 'Camera',
                      color: Colors.blue,
                      onTap: () => Navigator.pop(context, 'camera'),
                    ),
                    _buildSourceOption(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: Colors.green,
                      onTap: () => Navigator.pop(context, 'gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == 'camera') {
      return await takePhoto();
    } else if (result == 'gallery') {
      return await pickImageFromGallery();
    }

    return null;
  }

  /// Helper widget for image source option
  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Safe network image widget with error handling and fallback
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported,
    this.fallbackIconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    // If URL is null or empty, show fallback immediately
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        fallbackIcon,
        size: fallbackIconSize,
        color: Colors.grey[400],
      ),
    );
  }
}

/// Circular safe network image (for avatars, profile pictures)
class SafeCircularNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const SafeCircularNetworkImage({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(fallbackIcon, size: radius, color: Colors.grey[600]),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (exception, stackTrace) {
        // Error handled by fallback below
      },
      child: imageUrl!.isEmpty
          ? Icon(fallbackIcon, size: radius, color: Colors.grey[600])
          : null,
    );
  }
}

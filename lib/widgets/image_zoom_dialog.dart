import 'package:flutter/material.dart';

/// Image zoom dialog for viewing product images
class ImageZoomDialog extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageZoomDialog({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: initialIndex);
    
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image viewer
          PageView.builder(
            controller: pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.white54),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          
          // Image counter (if multiple images)
          if (imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: pageController.hasClients
                        ? _PageNotifier(pageController)
                        : ValueNotifier<int>(initialIndex),
                    builder: (context, page, child) {
                      return Text(
                        '${page + 1} / ${imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper class to listen to page changes
class _PageNotifier extends ValueNotifier<int> {
  final PageController pageController;

  _PageNotifier(this.pageController) : super(pageController.initialPage) {
    pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (pageController.hasClients) {
      value = pageController.page?.round() ?? value;
    }
  }

  @override
  void dispose() {
    pageController.removeListener(_onPageChanged);
    super.dispose();
  }
}

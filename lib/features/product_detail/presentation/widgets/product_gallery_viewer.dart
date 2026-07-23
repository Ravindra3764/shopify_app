import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Fullscreen, pinch-to-zoom product image viewer.
///
/// Opened by tapping a gallery image ([open]). Swipe horizontally between
/// images; pinch/pan to zoom each one (double-tap toggles zoom). Tap the close
/// button or system back to dismiss.
class ProductGalleryViewer extends StatefulWidget {
  const ProductGalleryViewer({
    required this.images,
    required this.initialIndex,
    required this.placeholderName,
    super.key,
  });

  final List<ShopifyImage> images;
  final int initialIndex;
  final String placeholderName;

  /// Pushes the viewer as a fullscreen route starting at [initialIndex].
  static Future<void> open(
    BuildContext context, {
    required List<ShopifyImage> images,
    required int initialIndex,
    required String placeholderName,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.black,
        pageBuilder: (_, _, _) => ProductGalleryViewer(
          images: images,
          initialIndex: initialIndex,
          placeholderName: placeholderName,
        ),
      ),
    );
  }

  @override
  State<ProductGalleryViewer> createState() => _ProductGalleryViewerState();
}

class _ProductGalleryViewerState extends State<ProductGalleryViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: images.length,
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CustomCachedImage(
                imageUrl: images[i].url,
                placeholderName: widget.placeholderName,
                backgroundColor: AppColors.black,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: topInset + AppSpacing.sm,
            right: AppSpacing.md,
            child: Material(
              color: AppColors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: SizedBox(
                width: AppDimensions.circleIconButtonSize,
                height: AppDimensions.circleIconButtonSize,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: AppDimensions.iconSm,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: topInset + AppSpacing.lg,
              left: 0,
              right: 0,
              child: Text(
                '${_page + 1} / ${images.length}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.white),
              ),
            ),
        ],
      ),
    );
  }
}

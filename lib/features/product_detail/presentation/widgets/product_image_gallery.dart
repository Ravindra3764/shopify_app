import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/shopify_image.dart';

/// Full-bleed swipeable product gallery with a page-dot indicator and
/// floating back/wishlist actions over the image.
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({
    required this.images,
    required this.placeholderName,
    super.key,
    this.onBack,
    this.isWishlisted = false,
    this.onWishlistToggle,
    this.selectedIndex,
    this.backIcon = Icons.arrow_back,
  });

  final List<ShopifyImage> images;
  final String placeholderName;
  final VoidCallback? onBack;

  /// Leading button glyph — a back arrow on the classic page, a down chevron
  /// in the Blinkit-style sheet.
  final IconData backIcon;

  /// Whether the wishlist heart renders filled. Hidden entirely when
  /// [onWishlistToggle] is `null` (wishlist feature disabled for tenant).
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  /// Page to show, driven by the caller (e.g. the image tied to the
  /// selected color/size variant). `null` leaves the current page alone.
  final int? selectedIndex;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final target = widget.selectedIndex;
    if (target != null && target != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(target);
          setState(() => _page = target);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.selectedIndex;
    if (target != null &&
        target != oldWidget.selectedIndex &&
        target != _page) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: AppDimensions.productGalleryHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: images.isEmpty ? 1 : images.length,
            itemBuilder: (context, i) => CustomCachedImage(
              imageUrl: images.isEmpty ? '' : images[i].url,
              placeholderName: widget.placeholderName,
              backgroundColor: AppColors.surface,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: topInset + AppSpacing.sm,
            left: AppSpacing.md,
            child: _CircleIconButton(
              icon: widget.backIcon,
              onPressed: widget.onBack,
            ),
          ),
          if (widget.onWishlistToggle != null)
            Positioned(
              top: topInset + AppSpacing.sm,
              right: AppSpacing.md,
              child: _CircleIconButton(
                icon: widget.isWishlisted
                    ? Icons.favorite
                    : Icons.favorite_border,
                iconColor: widget.isWishlisted ? AppColors.error : null,
                onPressed: widget.onWishlistToggle,
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: AppSpacing.md,
              left: 0,
              right: 0,
              child: _PageDots(count: images.length, current: _page),
            ),
        ],
      ),
    );
  }
}

/// Circular white-fill icon button used to float over the gallery image.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: SizedBox(
        width: AppDimensions.circleIconButtonSize,
        height: AppDimensions.circleIconButtonSize,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            size: AppDimensions.iconSm,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Dot indicator row for [ProductImageGallery] — the active dot elongates.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: i == current
                ? AppDimensions.galleryDotActiveWidth
                : AppDimensions.galleryDotSize,
            height: AppDimensions.galleryDotSize,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppDimensions.galleryDotSize),
            ),
          ),
      ],
    );
  }
}

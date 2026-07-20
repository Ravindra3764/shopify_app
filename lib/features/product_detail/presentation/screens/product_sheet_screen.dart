import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_detail_providers.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';

/// Blinkit-style product presentation: a peeking card over a dark scrim.
///
/// A product opens as a rounded card below the status bar (scrim shows above
/// and at the sides, with the neighbouring products peeking in); swiping
/// horizontally moves between the siblings it was opened with. The card's own
/// floating buttons (close chevron + wishlist) scroll away with the image, and
/// a sticky title header fades in as the content scrolls. Each card is a
/// [ProductDetailScreen].
class ProductSheetScreen extends StatefulWidget {
  const ProductSheetScreen({required this.peek, super.key});

  final ProductPeekArgs peek;

  @override
  State<ProductSheetScreen> createState() => _ProductSheetScreenState();
}

class _ProductSheetScreenState extends State<ProductSheetScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.peek.initialIndex,
    // <1 so the neighbouring cards peek in at the edges.
    viewportFraction: 0.9,
  );

  /// 0 = at the top (title in the image), 1 = scrolled (sticky title header
  /// shown). Drives the header crossfade and the horizontal-swipe lock.
  final ValueNotifier<double> _scrolled = ValueNotifier(0);

  late int _currentIndex = widget.peek.initialIndex;

  /// Scroll distance (px) over which the sticky header fades in.
  static const _fadeOver = 120.0;

  bool get _locked => _scrolled.value >= 0.999;

  @override
  void dispose() {
    HapticFeedback.lightImpact(); // haptic on close
    _pageController.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    context.pop();
  }

  bool _onScroll(ScrollNotification n) {
    // Only the card's vertical content scroll drives the header, not the
    // horizontal PageView.
    if (n.metrics.axis != Axis.vertical) return false;
    final wasLocked = _locked;
    _scrolled.value = (n.metrics.pixels / _fadeOver).clamp(0.0, 1.0);
    if (_locked != wasLocked) {
      if (_locked) HapticFeedback.mediumImpact();
      setState(() {}); // toggle the horizontal-swipe lock
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                physics: _locked
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.peek.handles.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLg),
                    ),
                    // The card sits below the status bar, so strip the top
                    // inset — the image is full-bleed to the card top.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ColoredBox(
                        color: AppColors.background,
                        child: ProductDetailScreen(
                          handle: widget.peek.handles[i],
                          sheetMode: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Sticky title header: hidden at the top (the gallery's own
              // buttons show over the image), fades in as the content scrolls.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrolled,
                  builder: (context, t, child) => IgnorePointer(
                    ignoring: t < 0.5,
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: _StickyHeader(
                    handle: widget.peek.handles[_currentIndex],
                    onClose: _close,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky header shown as a card scrolls: close chevron, product title, and
/// wishlist / search / share actions for the active product.
class _StickyHeader extends ConsumerWidget {
  const _StickyHeader({required this.handle, required this.onClose});

  final String handle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(handle)).valueOrNull;
    final wishlistEnabled = ref.watch(featureFlagsProvider).wishlistEnabled;
    final isWishlisted =
        detail != null && ref.watch(isInWishlistProvider(detail.id));

    return Material(
      color: AppColors.surface,
      elevation: AppSpacing.xs / 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _CircleButton(icon: Icons.keyboard_arrow_down, onPressed: onClose),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                detail?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (wishlistEnabled)
              _CircleButton(
                icon: isWishlisted ? Icons.favorite : Icons.favorite_border,
                iconColor: isWishlisted ? AppColors.error : null,
                onPressed: detail == null
                    ? null
                    : () => ref
                          .read(wishlistProvider.notifier)
                          .toggle(_productOf(detail)),
              ),
            const SizedBox(width: AppSpacing.sm),
            _CircleButton(
              icon: Icons.search,
              onPressed: () => context.push(AppRoutes.search),
            ),
            const SizedBox(width: AppSpacing.sm),
            _CircleButton(
              icon: Icons.ios_share,
              onPressed: () =>
                  showAppSnackBar(context, 'Sharing is coming soon.'),
            ),
          ],
        ),
      ),
    );
  }

  Product _productOf(ProductDetail detail) => Product(
    id: detail.id,
    title: detail.title,
    handle: detail.handle,
    availableForSale: detail.availableForSale,
    price: detail.price,
    featuredImage: detail.images.isEmpty ? null : detail.images.first,
    compareAtPrice: detail.compareAtPrice,
  );
}

/// Small circular white button used in the sticky header.
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onPressed, this.iconColor});

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: AppSpacing.xs / 2,
      child: InkResponse(
        onTap: onPressed,
        radius: AppDimensions.circleIconButtonSize / 2,
        child: SizedBox(
          width: AppDimensions.circleIconButtonSize,
          height: AppDimensions.circleIconButtonSize,
          child: Icon(
            icon,
            size: AppDimensions.iconMd,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

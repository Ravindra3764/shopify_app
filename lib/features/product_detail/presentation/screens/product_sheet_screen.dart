import 'dart:ui' show lerpDouble;

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

/// Blinkit-style product presentation.
///
/// A product opens as a rounded **card** below the status bar (scrim above),
/// with circular buttons — close chevron on the left, wishlist / search /
/// share on the right — pinned over the top. Swiping horizontally moves
/// between the siblings it was opened with. Scrolling the content up slides the
/// card up to cover the status bar and squares its corners — a **complete
/// full-screen** page — while the buttons stay pinned and the image scrolls
/// behind them; scrolling back to the top restores the card. Each card is a
/// [ProductDetailScreen].
class ProductSheetScreen extends StatefulWidget {
  const ProductSheetScreen({required this.peek, super.key});

  final ProductPeekArgs peek;

  @override
  State<ProductSheetScreen> createState() => _ProductSheetScreenState();
}

class _ProductSheetScreenState extends State<ProductSheetScreen> {
  /// Viewport fraction at card state so the sibling cards peek at both edges;
  /// snaps to 1.0 (full bleed) once expanded to full screen.
  static const double _peekFraction = 0.92;

  late PageController _pageController = PageController(
    initialPage: widget.peek.initialIndex,
    viewportFraction: _peekFraction,
  );

  /// 0 = card (below the status bar), 1 = full screen. Driven continuously by
  /// the active card's vertical scroll offset.
  final ValueNotifier<double> _fullness = ValueNotifier(0);

  late int _currentIndex = widget.peek.initialIndex;

  /// `true` once expanded into full screen — locks the horizontal swipe.
  bool _full = false;

  /// Scroll distance (px) over which the card morphs into a full page.
  static const _morphOver = 140.0;

  /// Downward pull past the top (px) that dismisses a peek card on release.
  static const _dismissPull = 120.0;

  /// How far the card is currently pulled down from the top (px). Mirrors the
  /// content's top over-scroll so the whole card follows the finger both ways
  /// within one drag; the bounce springs it back on release for free.
  final ValueNotifier<double> _dragOffset = ValueNotifier(0);

  /// Guards against popping twice once a dismiss is triggered.
  bool _closing = false;

  @override
  void dispose() {
    HapticFeedback.lightImpact(); // haptic on close
    _pageController.dispose();
    _fullness.dispose();
    _dragOffset.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    context.pop();
  }

  /// On finger lift, a pull past [_dismissPull] closes the card; anything less
  /// lets the content's bounce spring it back to the top.
  void _onPointerUp(PointerUpEvent event) {
    if (_closing) return;
    if (_dragOffset.value > _dismissPull) {
      _closing = true;
      _close();
    }
  }

  bool _onScroll(ScrollNotification n) {
    // Only the card's vertical content scroll drives the morph, not the
    // horizontal PageView.
    if (n.metrics.axis != Axis.vertical) return false;

    // At the top of a peek card, the content's top over-scroll (negative
    // pixels) tracks the finger both ways in one drag — mirror it onto the
    // whole card so the card follows. Release is handled on pointer-up.
    if (!_full && !_closing) {
      final pixels = n.metrics.pixels;
      _dragOffset.value = pixels < 0 ? -pixels : 0;
    }

    _fullness.value = (n.metrics.pixels / _morphOver).clamp(0.0, 1.0);
    final full = _fullness.value >= 0.999;
    if (full != _full) {
      if (full) HapticFeedback.mediumImpact();
      // Swap the controller so the peek gap closes to full bleed when expanded
      // and reopens when collapsed. viewportFraction is final, so recreate it —
      // the horizontal swipe is idle here (a vertical scroll), so it's safe.
      final page = _currentIndex;
      _pageController.dispose();
      _pageController = PageController(
        initialPage: page,
        viewportFraction: full ? 1.0 : _peekFraction,
      );
      setState(() => _full = full); // toggle the horizontal-swipe lock
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerUp: _onPointerUp,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          // The whole card (and its pinned buttons) follows the pull down.
          child: ValueListenableBuilder<double>(
            valueListenable: _dragOffset,
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: Stack(
              children: [
                // The card slides up to cover the status bar as it expands.
                ValueListenableBuilder<double>(
                  valueListenable: _fullness,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    physics: _full
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: widget.peek.handles.length,
                    itemBuilder: (context, i) => _MorphCard(
                      fullness: _fullness,
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: ProductDetailScreen(
                          handle: widget.peek.handles[i],
                          sheetMode: true,
                          // Cancels the content bounce so a top over-scroll
                          // moves the whole card, not just the image.
                          sheetPull: _dragOffset,
                        ),
                      ),
                    ),
                  ),
                  builder: (context, t, child) => Padding(
                    padding: EdgeInsets.only(top: lerpDouble(topInset, 0, t)!),
                    child: child,
                  ),
                ),
                // Pinned buttons over the card, always visible.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _PinnedActions(
                    handle: widget.peek.handles[_currentIndex],
                    onClose: _close,
                    fullness: _fullness,
                    // Blank strip the PageView leaves at each edge; the card's
                    // outer edge sits here at peek state.
                    peekEdge:
                        (1 - _peekFraction) /
                        2 *
                        MediaQuery.of(context).size.width,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a card's content and morphs its side margins + corner radius from the
/// inset card look to a flush full page as [fullness] goes 0 → 1.
class _MorphCard extends StatelessWidget {
  const _MorphCard({required this.fullness, required this.child});

  final ValueNotifier<double> fullness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fullness,
      child: child,
      builder: (context, t, child) => Container(
        // Float the card off every edge at peek (bottom included, so the
        // sticky action bar sits inside the rounded card); flush when full.
        margin: EdgeInsets.only(
          left: lerpDouble(AppSpacing.sm, 0, t)!,
          right: lerpDouble(AppSpacing.sm, 0, t)!,
          bottom: lerpDouble(AppSpacing.sm, 0, t)!,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(
            lerpDouble(AppDimensions.radiusLg, 0, t)!,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Buttons pinned over the card top: close chevron on the left, wishlist /
/// search / share on the right, for the active product.
class _PinnedActions extends ConsumerWidget {
  const _PinnedActions({
    required this.handle,
    required this.onClose,
    required this.fullness,
    required this.peekEdge,
  });

  final String handle;
  final VoidCallback onClose;
  final ValueNotifier<double> fullness;

  /// Width of the blank peek strip on each side of the card at peek state.
  final double peekEdge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(handle)).valueOrNull;
    final flags = ref.watch(featureFlagsProvider);
    final wishlistEnabled = flags.wishlistEnabled;
    final searchEnabled = flags.searchEnabled;
    final isWishlisted =
        detail != null && ref.watch(isInWishlistProvider(detail.id));

    return SafeArea(
      bottom: false,
      child: ValueListenableBuilder<double>(
        valueListenable: fullness,
        builder: (context, t, child) {
          // Keep the buttons inset from the card's outer edge by AppSpacing.md,
          // so they track the card as it morphs from peek to full bleed.
          final cardEdge =
              (t >= 0.999 ? 0.0 : peekEdge) + lerpDouble(AppSpacing.sm, 0, t)!;
          return Padding(
            padding: EdgeInsets.only(
              left: cardEdge + AppSpacing.md,
              right: cardEdge + AppSpacing.md,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: child,
          );
        },
        child: Row(
          children: [
            _CircleButton(icon: Icons.keyboard_arrow_down, onPressed: onClose),
            const Spacer(),
            if (wishlistEnabled) ...[
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
            ],
            if (searchEnabled) ...[
              _CircleButton(
                icon: Icons.search,
                onPressed: () => context.push(AppRoutes.search),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
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

/// Small circular white button used for the pinned card actions.
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

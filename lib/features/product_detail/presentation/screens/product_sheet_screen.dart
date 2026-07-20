import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_detail_screen.dart';

/// Blinkit-style product presentation over a dark scrim.
///
/// A product opens as a full-height card inset with side margins and rounded
/// corners (the scrim shows at the edges); swiping horizontally moves between
/// the siblings it was opened with. Scrolling a card's content **up** expands
/// it into a normal full page — the side margins and corner radius shrink to
/// zero and horizontal swipe locks; scrolling back to the top restores the
/// carousel. Each card is a [ProductDetailScreen] whose own floating buttons
/// (close chevron + wishlist) scroll away with the image.
class ProductSheetScreen extends StatefulWidget {
  const ProductSheetScreen({required this.peek, super.key});

  final ProductPeekArgs peek;

  @override
  State<ProductSheetScreen> createState() => _ProductSheetScreenState();
}

class _ProductSheetScreenState extends State<ProductSheetScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.peek.initialIndex,
  );

  /// 0 = collapsed carousel card, 1 = expanded full page. Driven by the active
  /// card's vertical scroll offset.
  final ValueNotifier<double> _fullness = ValueNotifier(0);

  /// Scroll distance (px) over which a card expands from card to full page.
  static const _expandOver = 120.0;

  bool get _expanded => _fullness.value >= 0.999;

  @override
  void dispose() {
    // Haptic on close, mirroring the one when entering full-screen.
    HapticFeedback.lightImpact();
    _pageController.dispose();
    _fullness.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    // Only the card's vertical content scroll drives expansion, not the
    // horizontal PageView.
    if (n.metrics.axis != Axis.vertical) return false;
    final wasExpanded = _expanded;
    _fullness.value = (n.metrics.pixels / _expandOver).clamp(0.0, 1.0);
    if (_expanded != wasExpanded) {
      if (_expanded) HapticFeedback.mediumImpact();
      setState(() {}); // toggle the horizontal-swipe lock
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ValueListenableBuilder<double>(
          valueListenable: _fullness,
          builder: (context, t, _) {
            // Collapsed = full-height card inset from the edges with rounded
            // corners; expanded = edge-to-edge full page.
            final sideMargin = lerpDouble(AppSpacing.md, 0, t)!;
            final radius = lerpDouble(AppDimensions.radiusLg, 0, t)!;
            return PageView.builder(
              controller: _pageController,
              physics: _expanded
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.peek.handles.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: sideMargin),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(radius)),
                  child: ColoredBox(
                    color: AppColors.background,
                    child: ProductDetailScreen(
                      handle: widget.peek.handles[i],
                      sheetMode: true,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

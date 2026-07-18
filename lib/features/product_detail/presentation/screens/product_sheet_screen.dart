import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_detail_screen.dart';

/// Blinkit-style product presentation: a full-height peeking carousel over a
/// dark scrim. Each product is a rounded card that fills the screen (minus a
/// small top gap), with the previous/next products peeking at the left/right
/// edges; swiping horizontally moves between the siblings it was opened with.
/// Each card reuses [ProductDetailScreen] for its content.
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
    viewportFraction: 0.94,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          // Small gap below the status bar so the scrim shows above the card.
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.peek.handles.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLg),
                ),
                child: ColoredBox(
                  color: AppColors.background,
                  child: ProductDetailScreen(handle: widget.peek.handles[i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

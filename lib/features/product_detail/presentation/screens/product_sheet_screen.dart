import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/domain/product_peek_args.dart';
import 'package:shopify_app/features/product_detail/presentation/screens/product_detail_screen.dart';

/// Blinkit-style product presentation: a draggable sheet that opens partial
/// over the previous screen, expands to full on drag/scroll-up, and — while
/// collapsed — swipes horizontally between the sibling products it was opened
/// with. Reuses [ProductDetailScreen] for each page's content.
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

  /// Height fraction below which a page counts as "collapsed" (horizontal
  /// swipe allowed) and above which it's "expanded" (swipe locked).
  static const _collapsedExtent = 0.72;
  static const _expandThreshold = 0.9;

  bool _expanded = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _onSheetNotification(DraggableScrollableNotification n) {
    final expanded = n.extent >= _expandThreshold;
    if (expanded != _expanded) setState(() => _expanded = expanded);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap the exposed area above the sheet to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pop(),
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: _onSheetNotification,
            child: PageView.builder(
              controller: _pageController,
              physics: _expanded
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.peek.handles.length,
              itemBuilder: (context, i) =>
                  _SheetPage(handle: widget.peek.handles[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// One product rendered inside a draggable sheet.
class _SheetPage extends StatelessWidget {
  const _SheetPage({required this.handle});

  final String handle;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _ProductSheetScreenState._collapsedExtent,
      minChildSize: _ProductSheetScreenState._collapsedExtent,
      snap: true,
      snapSizes: const [_ProductSheetScreenState._collapsedExtent, 1],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLg),
          ),
          child: ColoredBox(
            color: AppColors.background,
            child: Column(
              children: [
                const _DragHandle(),
                Expanded(
                  child: ProductDetailScreen(
                    handle: handle,
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The grab bar at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.sheetHandleWidth,
      height: AppDimensions.sheetHandleHeight,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppDimensions.sheetHandleHeight),
      ),
    );
  }
}

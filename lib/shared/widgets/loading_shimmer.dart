import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Skeleton placeholders that mirror real content while it loads.
///
/// Use the layout-specific constructor that matches the screen — e.g.
/// [LoadingShimmer.home] for the home screen. A skeleton must mirror the real
/// layout (not a generic box), per the state-management rules.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer._(this._builder, {super.key});

  /// Home screen skeleton: hero banner + two product rows.
  const LoadingShimmer.home({Key? key}) : this._(_homeLayout, key: key);

  /// Product grid skeleton: a 2-column grid of card placeholders.
  const LoadingShimmer.grid({Key? key}) : this._(_gridLayout, key: key);

  /// Product-detail skeleton: gallery + title/price/options blocks.
  const LoadingShimmer.productDetail({Key? key})
    : this._(_productDetailLayout, key: key);

  /// A single horizontal row of product-card placeholders, with no title —
  /// for reuse under a real section header (e.g. related products).
  const LoadingShimmer.row({Key? key}) : this._(_cardsRowLayout, key: key);

  /// Cart skeleton: header lines, a few item rows, and a totals card.
  const LoadingShimmer.cart({Key? key}) : this._(_cartLayout, key: key);

  /// Long-form content skeleton: a title line followed by paragraph lines —
  /// mirrors a policy / about / help page.
  const LoadingShimmer.article({Key? key}) : this._(_articleLayout, key: key);

  final Widget Function(BuildContext) _builder;

  @override
  Widget build(BuildContext context) => _Shimmer(child: _builder(context));

  static Widget _homeLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        const _Box(
          height: AppDimensions.bannerHeight,
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          radius: AppDimensions.radiusLg,
        ),
        const SizedBox(height: AppSpacing.xl),
        _row(),
        const SizedBox(height: AppSpacing.xl),
        _row(),
      ],
    );
  }

  static Widget _gridLayout(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: AppDimensions.productCardHeight,
      ),
      itemBuilder: (_, _) => const _Box(),
    );
  }

  static Widget _productDetailLayout(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _Box(height: AppDimensions.productGalleryHeight, radius: 0),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Box(
                height: AppSpacing.md,
                width: AppDimensions.shimmerShortWidth,
                radius: AppDimensions.radiusSm,
              ),
              const SizedBox(height: AppSpacing.md),
              const _Box(
                height: AppSpacing.lg,
                width: AppDimensions.shimmerTitleWidth,
                radius: AppDimensions.radiusSm,
              ),
              const SizedBox(height: AppSpacing.md),
              const _Box(
                height: AppSpacing.md,
                width: AppDimensions.shimmerShortWidth,
                radius: AppDimensions.radiusSm,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: _Box(
                        height: AppDimensions.swatchSize,
                        width: AppDimensions.swatchSize,
                        radius: AppDimensions.swatchSize,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: _Box(
                        height: AppDimensions.optionChipHeight,
                        width: AppDimensions.swatchSize,
                        radius: AppDimensions.radiusSm,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _cartLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const _Box(
          height: AppSpacing.lg,
          width: AppDimensions.shimmerTitleWidth,
          radius: AppDimensions.radiusSm,
        ),
        const SizedBox(height: AppSpacing.md),
        const _Box(
          height: AppSpacing.md,
          width: AppDimensions.shimmerShortWidth,
          radius: AppDimensions.radiusSm,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < 3; i++) ...[
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Box(
                height: AppDimensions.cartThumbSize,
                width: AppDimensions.cartThumbSize,
                radius: AppDimensions.radiusSm,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(height: AppSpacing.md, radius: AppDimensions.radiusSm),
                    SizedBox(height: AppSpacing.sm),
                    _Box(
                      height: AppSpacing.sm,
                      width: AppDimensions.shimmerShortWidth,
                      radius: AppDimensions.radiusSm,
                    ),
                    SizedBox(height: AppSpacing.md),
                    _Box(
                      height: AppDimensions.optionChipHeight,
                      width: AppDimensions.quantityStepperWidth,
                      radius: AppDimensions.radiusSm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const _Box(height: AppDimensions.cartSummaryShimmerHeight),
      ],
    );
  }

  static Widget _articleLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _Box(
          height: AppSpacing.lg,
          width: AppDimensions.shimmerTitleWidth,
          radius: AppDimensions.radiusSm,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < 12; i++) ...[
          _Box(
            height: AppSpacing.sm,
            // Every fourth line is short, mimicking a paragraph break.
            width: i.isOdd && i % 4 == 3
                ? AppDimensions.shimmerShortWidth
                : null,
            radius: AppDimensions.radiusSm,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static Widget _cardsRowLayout(BuildContext context) => _cardsRow();

  static Widget _cardsRow() {
    return SizedBox(
      height: AppDimensions.productImageHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, _) =>
            const _Box(width: AppDimensions.productCardWidth),
      ),
    );
  }

  static Widget _row() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _Box(
            height: AppSpacing.md,
            width: AppDimensions.retryButtonWidth,
            radius: AppDimensions.radiusSm,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _cardsRow(),
      ],
    );
  }
}

/// A grey rounded box used as a skeleton element.
class _Box extends StatelessWidget {
  const _Box({
    this.height,
    this.width,
    this.radius = AppDimensions.radiusMd,
    this.margin = EdgeInsets.zero,
  });

  final double? height;
  final double? width;
  final double radius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Animates a subtle opacity pulse across its [child] skeleton tree.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

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
        SizedBox(
          height: AppDimensions.productImageHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, _) =>
                const _Box(width: AppDimensions.productCardWidth),
          ),
        ),
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

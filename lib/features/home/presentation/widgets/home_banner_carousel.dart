import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_cached_image.dart';
import 'package:shopify_app/shopify/models/home_banner_model.dart';

/// Swipeable hero banners with an image, overlaid copy, and a CTA.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({required this.banners, super.key, this.onCta});

  final List<HomeBannerModel> banners;

  final void Function(HomeBannerModel banner)? onCta;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        SizedBox(
          height: AppDimensions.bannerHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) =>
                _BannerSlide(banner: banners[i], onCta: widget.onCta),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _Dots(count: banners.length, index: _index),
        ],
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner, this.onCta});

  final HomeBannerModel banner;
  final void Function(HomeBannerModel banner)? onCta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomCachedImage(
              imageUrl: banner.image?.url ?? '',
              placeholderName: banner.title,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.scrim],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.eyebrow.isNotEmpty)
                    Text(
                      banner.eyebrow.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        letterSpacing: AppSpacing.xs / 2,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    banner.title,
                    style: textTheme.headlineLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  if (banner.ctaLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    CustomButton.secondary(
                      label: banner.ctaLabel,
                      width: AppDimensions.retryButtonWidth,
                      onPressed: onCta == null ? null : () => onCta!(banner),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
          height: AppSpacing.sm,
          width: active ? AppSpacing.lg : AppSpacing.sm,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
        );
      }),
    );
  }
}

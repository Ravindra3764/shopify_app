import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/config/feature_flags.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_detail_providers.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_selection.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_detail_tabs.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_image_gallery.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_option_selector.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/quantity_stepper.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/related_products_section.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/error_view.dart';
import 'package:shopify_app/shared/widgets/loading_shimmer.dart';
import 'package:shopify_app/shared/widgets/price_tag.dart';
import 'package:shopify_app/shared/widgets/rating_stars.dart';
import 'package:shopify_app/shopify/models/product.dart';
import 'package:shopify_app/shopify/models/product_detail.dart';
import 'package:shopify_app/shopify/models/product_variant.dart';

/// Product-detail screen, common to every product across the catalog.
///
/// Shows the gallery, options, description/reviews/shipping tabs, and
/// related products, with a sticky Add to Cart / Buy Now bar pinned to the
/// bottom.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.handle, super.key});

  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(handle));

    return CustomBackground(
      showAppBar: false,
      applyBottomInset: false,
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: async.when(
        data: (detail) => _ProductDetailContent(handle: handle, detail: detail),
        loading: () => const LoadingShimmer.productDetail(),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Something went wrong.',
          onRetry: () => ref.invalidate(productDetailProvider(handle)),
        ),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerStatefulWidget {
  const _ProductDetailContent({required this.handle, required this.detail});

  final String handle;
  final ProductDetail detail;

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState extends ConsumerState<_ProductDetailContent> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final featureFlags = ref.watch(featureFlagsProvider);
    final selection = ref.watch(productSelectionProvider(widget.handle));
    final selectionNotifier = ref.read(
      productSelectionProvider(widget.handle).notifier,
    );
    final variant = detail.variantFor(selection.selectedOptions);
    final canPurchase =
        detail.availableForSale && (variant?.availableForSale ?? true);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageGallery(
                  images: detail.images,
                  placeholderName: detail.title,
                  selectedIndex: detail.indexOfImage(variant?.image),
                  onBack: () => context.pop(),
                  isWishlisted: _isWishlisted,
                  onWishlistToggle: featureFlags.wishlistEnabled
                      ? () => setState(() => _isWishlisted = !_isWishlisted)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _ProductInfo(
                    detail: detail,
                    variant: variant,
                    selection: selection,
                    featureFlags: featureFlags,
                    onSelectOption: selectionNotifier.selectOption,
                    onIncrementQuantity: selectionNotifier.incrementQuantity,
                    onDecrementQuantity: selection.quantity > 1
                        ? selectionNotifier.decrementQuantity
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RelatedProducts(productId: detail.id),
              ],
            ),
          ),
        ),
        _StickyActionBar(
          canPurchase: canPurchase,
          quantity: selection.quantity,
        ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.detail,
    required this.variant,
    required this.selection,
    required this.featureFlags,
    required this.onSelectOption,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
  });

  final ProductDetail detail;
  final ProductVariant? variant;
  final ProductSelection selection;
  final FeatureFlags featureFlags;
  final void Function(String name, String value) onSelectOption;
  final VoidCallback onIncrementQuantity;
  final VoidCallback? onDecrementQuantity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayPrice = variant?.price ?? detail.price;
    final displayCompareAt = variant?.compareAtPrice ?? detail.compareAtPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.vendor != null && detail.vendor!.isNotEmpty)
          Text(
            detail.vendor!.toUpperCase(),
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          detail.title,
          style: textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (detail.averageRating != null) ...[
          const SizedBox(height: AppSpacing.sm),
          RatingStars(
            rating: detail.averageRating!,
            reviewCount: detail.reviewsCount,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PriceTag(price: displayPrice, compareAtPrice: displayCompareAt),
        for (final option in detail.options) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${option.name}${_selectedSuffix(option.name)}',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ProductOptionSelector(
            option: option,
            selectedValue: selection.selectedOptions[option.name],
            onSelected: (value) => onSelectOption(option.name, value),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Quantity',
          style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        QuantityStepper(
          quantity: selection.quantity,
          onIncrement: onIncrementQuantity,
          onDecrement: onDecrementQuantity,
        ),
        const SizedBox(height: AppSpacing.xl),
        ProductDetailTabs(
          description: detail.description ?? '',
          showReviewsTab: featureFlags.reviewsEnabled,
          averageRating: detail.averageRating,
          reviewsCount: detail.reviewsCount,
        ),
      ],
    );
  }

  String _selectedSuffix(String optionName) {
    final value = selection.selectedOptions[optionName];
    return value == null || value.isEmpty ? '' : ': $value';
  }
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productRecommendationsProvider(productId));
    return async.when(
      data: (products) => RelatedProductsSection(
        products: products,
        onProductTap: (Product product) =>
            context.push(AppRoutes.productDetailPath(product.handle)),
      ),
      loading: () => const LoadingShimmer.row(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({required this.canPurchase, required this.quantity});

  final bool canPurchase;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: CustomButton.outline(
                  label: canPurchase ? 'Add to Cart' : 'Sold Out',
                  onPressed: canPurchase
                      ? () => _notify(context, 'Added $quantity to cart')
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton.primary(
                  label: 'Buy Now',
                  onPressed: canPurchase
                      ? () => _notify(context, 'Proceeding to checkout')
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

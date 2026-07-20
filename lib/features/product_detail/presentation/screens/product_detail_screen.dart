import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/config/feature_flags.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/cart/presentation/providers/cart_providers.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_detail_providers.dart';
import 'package:shopify_app/features/product_detail/presentation/providers/product_selection.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_detail_tabs.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_image_gallery.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/product_option_selector.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/quantity_stepper.dart';
import 'package:shopify_app/features/product_detail/presentation/widgets/related_products_section.dart';
import 'package:shopify_app/features/wishlist/presentation/providers/wishlist_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
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
  const ProductDetailScreen({
    required this.handle,
    super.key,
    this.sheetMode = false,
    this.sheetPull,
  });

  final String handle;

  /// `true` when embedded in the Blinkit-style sheet — hides the gallery's
  /// floating back/wishlist buttons since the sheet provides its own header.
  final bool sheetMode;

  /// Sheet pull-down distance (px). When set, the content scroll bounces and
  /// counter-translates by this amount so a top over-scroll moves the whole
  /// card instead of just the image.
  final ValueNotifier<double>? sheetPull;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(handle));

    return CustomBackground(
      showAppBar: false,
      applyBottomInset: false,
      horizontalPadding: 0,
      contentTopPadding: 0,
      child: async.when(
        data: (detail) => _ProductDetailContent(
          handle: handle,
          detail: detail,
          sheetMode: sheetMode,
          sheetPull: sheetPull,
        ),
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
  const _ProductDetailContent({
    required this.handle,
    required this.detail,
    this.sheetMode = false,
    this.sheetPull,
  });

  final String handle;
  final ProductDetail detail;
  final bool sheetMode;
  final ValueNotifier<double>? sheetPull;

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState extends ConsumerState<_ProductDetailContent> {
  /// Product summary saved to / read from the wishlist for this detail page.
  Product get _asProduct => Product(
    id: widget.detail.id,
    title: widget.detail.title,
    handle: widget.detail.handle,
    availableForSale: widget.detail.availableForSale,
    price: widget.detail.price,
    featuredImage: widget.detail.images.isEmpty
        ? null
        : widget.detail.images.first,
    compareAtPrice: widget.detail.compareAtPrice,
  );

  /// Counter-translates the scroll content up by the sheet's pull distance so
  /// its top over-scroll (bounce) cancels out — the sheet moves the whole card
  /// instead, while the sticky bar (outside this scroll) also rides the card.
  Widget _wrapSheetPull(Widget child) {
    final pull = widget.sheetPull;
    if (pull == null) return child;
    return ValueListenableBuilder<double>(
      valueListenable: pull,
      child: child,
      builder: (context, offset, child) =>
          Transform.translate(offset: Offset(0, -offset), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final featureFlags = ref.watch(featureFlagsProvider);
    final isWishlisted = ref.watch(isInWishlistProvider(detail.id));
    final shippingReturnCopy = ref
        .watch(shopPoliciesProvider)
        .valueOrNull
        ?.combinedCopy;
    final selection = ref.watch(productSelectionProvider(widget.handle));
    final selectionNotifier = ref.read(
      productSelectionProvider(widget.handle).notifier,
    );
    final variant = detail.variantFor(selection.selectedOptions);
    final canPurchase =
        detail.availableForSale && (variant?.availableForSale ?? true);
    // Cap the quantity stepper at available stock; `null` = untracked/unlimited.
    final stock = variant?.quantityAvailable;
    final canIncreaseQty = stock == null || selection.quantity < stock;
    // Products with no real options have a single default variant that
    // `variantFor` can't match (empty selection), so fall back to the first.
    final merchandiseId =
        (variant ?? (detail.variants.isEmpty ? null : detail.variants.first))
            ?.id;

    return Column(
      children: [
        Expanded(
          child: _wrapSheetPull(
            SingleChildScrollView(
              physics: widget.sheetMode
                  ? const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    )
                  : null,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImageGallery(
                    images: detail.images,
                    placeholderName: detail.title,
                    selectedIndex: detail.indexOfImage(variant?.image),
                    showFloatingActions: !widget.sheetMode,
                    onBack: () => context.pop(),
                    isWishlisted: isWishlisted,
                    onWishlistToggle: featureFlags.wishlistEnabled
                        ? () => ref
                              .read(wishlistProvider.notifier)
                              .toggle(_asProduct)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProductInfo(
                    detail: detail,
                    variant: variant,
                    selection: selection,
                    featureFlags: featureFlags,
                    shippingReturnCopy: shippingReturnCopy ?? '',
                    onSelectOption: selectionNotifier.selectOption,
                    onIncrementQuantity: canIncreaseQty
                        ? selectionNotifier.incrementQuantity
                        : null,
                    onDecrementQuantity: selection.quantity > 1
                        ? selectionNotifier.decrementQuantity
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RelatedProducts(productId: detail.id),
                ],
              ),
            ),
          ),
        ),
        _StickyActionBar(
          canPurchase: canPurchase,
          quantity: selection.quantity,
          merchandiseId: merchandiseId,
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
    required this.shippingReturnCopy,
    required this.onSelectOption,
    required this.onIncrementQuantity,
    required this.onDecrementQuantity,
  });

  final ProductDetail detail;
  final ProductVariant? variant;
  final ProductSelection selection;
  final FeatureFlags featureFlags;
  final String shippingReturnCopy;
  final void Function(String name, String value) onSelectOption;

  /// `null` disables `+` — e.g. once quantity reaches available stock.
  final VoidCallback? onIncrementQuantity;
  final VoidCallback? onDecrementQuantity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayPrice = variant?.price ?? detail.price;
    final displayCompareAt = variant?.compareAtPrice ?? detail.compareAtPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1 — title block: vendor, title, rating, price.
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detail.vendor != null && detail.vendor!.isNotEmpty) ...[
                Text(
                  detail.vendor!.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
            ],
          ),
        ),
        // Card 2 — options + quantity selectors.
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final option in detail.options) ...[
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
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                'Quantity',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              QuantityStepper(
                quantity: selection.quantity,
                onIncrement: onIncrementQuantity,
                onDecrement: onDecrementQuantity,
              ),
            ],
          ),
        ),
        // Card 3 — description / reviews / shipping tabs.
        const SizedBox(height: AppSpacing.sm),
        _SectionCard(
          child: ProductDetailTabs(
            description: detail.description ?? '',
            showReviewsTab: featureFlags.reviewsEnabled,
            averageRating: detail.averageRating,
            reviewsCount: detail.reviewsCount,
            shippingReturnCopy: shippingReturnCopy,
          ),
        ),
      ],
    );
  }

  String _selectedSuffix(String optionName) {
    final value = selection.selectedOptions[optionName];
    return value == null || value.isEmpty ? '' : ': $value';
  }
}

/// White rounded panel floating on the page background, with a gap around it —
/// the Blinkit-style "card" that groups a section of product detail.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: child,
    );
  }
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productRecommendationsProvider(productId));
    return async.when(
      data: (products) => RelatedProductsSection(products: products),
      loading: () => const LoadingShimmer.row(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _StickyActionBar extends ConsumerStatefulWidget {
  const _StickyActionBar({
    required this.canPurchase,
    required this.quantity,
    required this.merchandiseId,
  });

  final bool canPurchase;
  final int quantity;
  final String? merchandiseId;

  @override
  ConsumerState<_StickyActionBar> createState() => _StickyActionBarState();
}

class _StickyActionBarState extends ConsumerState<_StickyActionBar> {
  bool _isAdding = false;
  bool _justAdded = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final variantId = widget.merchandiseId;
    if (variantId == null) return;

    setState(() => _isAdding = true);
    await ref
        .read(cartProvider.notifier)
        .addVariant(variantId, quantity: widget.quantity);
    if (!mounted) return;

    final failed = ref.read(cartProvider).hasError;
    setState(() {
      _isAdding = false;
      _justAdded = !failed;
    });

    if (failed) {
      showAppSnackBar(
        context,
        'Could not add to cart. Please try again.',
        icon: Icons.error_outline,
      );
      return;
    }
    // Revert the confirmation label after a beat so the user can add more.
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = widget.canPurchase && widget.merchandiseId != null;
    final addLabel = _justAdded
        ? 'Added to Cart'
        : (widget.canPurchase ? 'Add to Cart' : 'Sold Out');

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
                  label: addLabel,
                  isLoading: _isAdding,
                  leadingIcon: _justAdded
                      ? Icon(
                          Icons.check_circle_outline,
                          size: AppDimensions.iconSm,
                          color: AppColors.primary,
                        )
                      : null,
                  onPressed: canAdd ? _addToCart : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton.primary(
                  label: 'Buy Now',
                  onPressed: widget.canPurchase
                      ? () => showAppSnackBar(
                          context,
                          'Express checkout is on the way.',
                          icon: Icons.bolt_outlined,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

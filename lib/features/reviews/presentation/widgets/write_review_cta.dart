import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/features/reviews/presentation/providers/purchased_products_provider.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';

/// "Write a review" action.
///
/// Renders only when the tenant enables review submission
/// (`FeatureFlags.reviewSubmissionEnabled`). When `reviewOnlyPurchased` is on,
/// it's offered only for products the signed-in customer has bought; otherwise
/// any signed-in shopper can review. Prompts sign-in when signed out.
///
/// ```dart
/// WriteReviewCta(args: reviewsArgs);
/// ```
class WriteReviewCta extends ConsumerWidget {
  const WriteReviewCta({required this.args, super.key});

  final ProductReviewsArgs args;

  void _open(BuildContext context, WidgetRef ref) {
    if (ref.read(isAuthenticatedProvider)) {
      context.push(AppRoutes.productReviewWrite, extra: args);
    } else {
      showAppSnackBar(context, 'Sign in to write a review.');
      context.push(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    if (!flags.reviewSubmissionEnabled) return const SizedBox.shrink();

    Widget button({required bool enabled}) => CustomButton.outline(
      label: 'Write a review',
      leadingIcon: const Icon(Icons.rate_review_outlined),
      onPressed: enabled ? () => _open(context, ref) : null,
    );

    // Any signed-in shopper can review anything.
    if (!flags.reviewOnlyPurchased) return button(enabled: true);

    // Purchase-gated: signed-out shoppers still get a button that routes to
    // sign-in; signed-in shoppers only see it for products they've purchased.
    if (!ref.watch(isAuthenticatedProvider)) return button(enabled: true);

    return ref
        .watch(purchasedProductIdsProvider)
        .when(
          loading: () => button(enabled: false),
          error: (_, _) => const SizedBox.shrink(),
          data: (ids) => ids.contains(args.productId)
              ? button(enabled: true)
              : const _PurchaseGateNote(),
        );
  }
}

/// Shown in place of the CTA when purchase-gated reviews are on and the
/// customer hasn't bought this product.
class _PurchaseGateNote extends StatelessWidget {
  const _PurchaseGateNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.lock_outline,
          size: AppDimensions.iconSm,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Only customers who bought this product can review it.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

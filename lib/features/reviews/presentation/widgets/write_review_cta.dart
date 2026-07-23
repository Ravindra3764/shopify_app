import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/routing/app_routes.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';

/// "Write a review" action for product surfaces (product-detail Reviews tab and
/// the full reviews screen).
///
/// Hidden entirely when `reviewOnlyPurchased` is on — in that mode reviewing is
/// offered only from **My orders** (order detail), where the purchase is
/// implicit. Otherwise any signed-in shopper can review; signed-out shoppers
/// are routed to sign-in.
///
/// ```dart
/// WriteReviewCta(args: reviewsArgs);
/// ```
class WriteReviewCta extends ConsumerWidget {
  const WriteReviewCta({required this.args, super.key});

  final ProductReviewsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(featureFlagsProvider);
    // Only show on product surfaces when submission is on AND reviews aren't
    // restricted to purchases (those go through My orders instead).
    if (!flags.reviewSubmissionEnabled || flags.reviewOnlyPurchased) {
      return const SizedBox.shrink();
    }

    return CustomButton.outline(
      label: 'Write a review',
      leadingIcon: const Icon(Icons.rate_review_outlined),
      onPressed: () {
        if (ref.read(isAuthenticatedProvider)) {
          context.push(AppRoutes.productReviewWrite, extra: args);
        } else {
          showAppSnackBar(context, 'Sign in to write a review.');
          context.push(AppRoutes.login);
        }
      },
    );
  }
}

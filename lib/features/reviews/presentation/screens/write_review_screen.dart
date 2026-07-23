import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shopify_app/core/error/failure.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:shopify_app/features/reviews/domain/product_reviews_args.dart';
import 'package:shopify_app/features/reviews/domain/review_draft.dart';
import 'package:shopify_app/features/reviews/presentation/providers/purchased_products_provider.dart';
import 'package:shopify_app/features/reviews/presentation/providers/write_review_providers.dart';
import 'package:shopify_app/providers/config_providers.dart';
import 'package:shopify_app/shared/widgets/app_snack_bar.dart';
import 'package:shopify_app/shared/widgets/custom_background.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';
import 'package:shopify_app/shared/widgets/custom_text_box.dart';
import 'package:shopify_app/shared/widgets/rating_stars.dart';

/// Form for submitting a review of a product. Requires a signed-in customer
/// (the write provider needs a reviewer name + email).
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({required this.args, super.key});

  final ProductReviewsArgs args;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  double _rating = 0;
  bool _showErrors = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final customer = ref.read(currentCustomerProvider);
    final bodyValid = _bodyController.text.trim().isNotEmpty;
    if (_rating < 1 || !bodyValid || customer == null) {
      setState(() => _showErrors = true);
      return;
    }

    // Defense-in-depth: the CTA already hides for non-purchasers, but a deep
    // link could reach here — re-check the purchase gate before submitting.
    if (ref.read(featureFlagsProvider).reviewOnlyPurchased) {
      final purchased =
          ref.read(purchasedProductIdsProvider).valueOrNull ?? const {};
      if (!purchased.contains(widget.args.productId)) {
        showAppSnackBar(
          context,
          'You can only review products you have purchased.',
          icon: Icons.lock_outline,
        );
        return;
      }
    }

    final ok = await ref
        .read(writeReviewProvider.notifier)
        .submit(
          ReviewDraft(
            productId: widget.args.productId,
            rating: _rating,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            reviewerName: customer.displayName,
            reviewerEmail: customer.email,
          ),
        );

    if (!mounted) return;
    if (ok) {
      showAppSnackBar(
        context,
        'Review submitted — it will appear once approved.',
        icon: Icons.check_circle_outline,
      );
      context.pop();
    } else {
      final error = ref.read(writeReviewProvider).error;
      showAppSnackBar(
        context,
        error is Failure ? error.message : 'Could not submit your review.',
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final submitting = ref.watch(writeReviewProvider).isLoading;
    final ratingError = _showErrors && _rating < 1;
    final bodyError = _showErrors && _bodyController.text.trim().isEmpty;

    return CustomBackground(
      title: 'Write a review',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            widget.args.productTitle,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your rating',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RatingStars(
            rating: _rating,
            size: AppDimensions.iconLg,
            onChanged: (value) => setState(() => _rating = value),
          ),
          if (ratingError) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap to pick a rating.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CustomTextBox(
            label: 'Title (optional)',
            hintText: 'Sum it up in a few words',
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextBox(
            label: 'Your review',
            hintText: 'What did you like or dislike?',
            controller: _bodyController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            errorText: bodyError ? 'Please write your review.' : null,
            onChanged: (_) {
              if (_showErrors) setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomButton.primary(
            label: 'Submit review',
            isLoading: submitting,
            onPressed: submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/shared/widgets/custom_button.dart';

/// Centered empty-state: an [icon], a [message], and an optional CTA.
///
/// ```dart
/// EmptyStateView(
///   icon: Icons.shopping_bag_outlined,
///   message: 'Your cart is empty.',
///   actionLabel: 'Shop now',
///   onAction: openHome,
/// );
/// ```
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxl, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CustomButton.outline(
                label: actionLabel!,
                onPressed: onAction,
                width: AppDimensions.retryButtonWidth,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

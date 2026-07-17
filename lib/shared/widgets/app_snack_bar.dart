import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Shows a modern floating snackbar: rounded, dark pill, optional leading
/// [icon]. Replaces Flutter's default edge-to-edge grey bar for a consistent,
/// on-brand toast across the app.
///
/// ```dart
/// showAppSnackBar(context, 'Added to cart', icon: Icons.check_circle_outline);
/// ```
void showAppSnackBar(BuildContext context, String message, {IconData? icon}) {
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        elevation: 6,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.white, size: AppDimensions.iconMd),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

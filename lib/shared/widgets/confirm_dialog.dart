import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Shows a themed yes/no confirmation dialog and resolves to `true` only when
/// the shopper confirms (dismissing resolves to `false`).
///
/// Set [isDestructive] to tint the confirm action red (e.g. sign out, delete).
///
/// ```dart
/// final ok = await showConfirmDialog(context, title: 'Sign out',
///     message: 'Sign out of your account?', confirmLabel: 'Sign out');
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final textTheme = Theme.of(context).textTheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
      ),
      content: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: textTheme.labelLarge?.copyWith(
              color: isDestructive ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

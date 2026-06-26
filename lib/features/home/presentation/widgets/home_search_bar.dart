import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Tappable search affordance shown above the home content.
///
/// Visual only for now; [onTap] will route to the search screen once added.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, this.onTap, this.hintText = 'Search'});

  final VoidCallback? onTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.boxFill,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: AppDimensions.iconMd,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              hintText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

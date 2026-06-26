import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';

/// Row with a section [title] and an optional trailing "See all" action.
///
/// ```dart
/// SectionHeader(title: 'New Arrivals', onSeeAll: openCollection);
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.onSeeAll,
    this.seeAllLabel = 'View All',
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              seeAllLabel,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

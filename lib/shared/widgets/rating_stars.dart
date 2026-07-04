import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Five-star rating row, optionally followed by a review count.
///
/// Read-only by default; pass [onChanged] to make it an interactive picker
/// (e.g. a "leave a review" form).
///
/// ```dart
/// RatingStars(rating: 4.6, reviewCount: 42);
/// RatingStars(rating: draftRating, onChanged: (r) => draftRating = r);
/// ```
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    super.key,
    this.reviewCount,
    this.size = AppDimensions.iconSm,
    this.onChanged,
  });

  /// Rating on a 0-5 scale.
  final double rating;

  /// Shown as `(count Reviews)` when provided.
  final int? reviewCount;

  /// Star icon size.
  final double size;

  /// When set, taps on a star report the tapped value and the widget renders
  /// as interactive; when `null` (default) the row is read-only.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onChanged != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: isInteractive
                ? GestureDetector(
                    onTap: () => onChanged!(i.toDouble()),
                    child: _star(i),
                  )
                : _star(i),
          ),
        if (reviewCount != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($reviewCount Reviews)',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }

  Widget _star(int position) {
    final filled = rating >= position;
    final half = !filled && rating > position - 1;
    final icon = filled
        ? Icons.star
        : half
        ? Icons.star_half
        : Icons.star_border;
    return Icon(icon, size: size, color: AppColors.rating);
  }
}

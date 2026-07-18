import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';
import 'package:shopify_app/features/checkout/presentation/providers/checkout_state.dart';

/// Horizontal 3-step progress indicator for the checkout wizard: Address →
/// Shipping → Review. The [current] step and any completed steps are filled
/// with the brand primary color; upcoming steps are muted.
class CheckoutStepHeader extends StatelessWidget {
  const CheckoutStepHeader({required this.current, super.key});

  final CheckoutStep current;

  static const _labels = <CheckoutStep, String>{
    CheckoutStep.address: 'Address',
    CheckoutStep.delivery: 'Shipping',
    CheckoutStep.review: 'Review',
  };

  @override
  Widget build(BuildContext context) {
    const steps = CheckoutStep.values;
    final currentIndex = current.index;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepDot(
            index: i + 1,
            label: _labels[steps[i]] ?? '',
            done: i < currentIndex,
            active: i == currentIndex,
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: AppDimensions.swatchRingWidth,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: i < currentIndex ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filled = done || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimensions.circleIconButtonSize,
          height: AppDimensions.circleIconButtonSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.boxFill,
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.border,
            ),
          ),
          child: done
              ? const Icon(
                  Icons.check,
                  size: AppDimensions.iconSm,
                  color: AppColors.white,
                )
              : Text(
                  '$index',
                  style: textTheme.labelLarge?.copyWith(
                    color: active ? AppColors.white : AppColors.textTertiary,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: filled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

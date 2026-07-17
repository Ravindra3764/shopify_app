import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Bordered `- qty +` stepper. [onDecrement] is `null` at [quantity] `1`, so
/// the button disables itself instead of going below one. Pass a `null`
/// [onIncrement] to disable `+` — e.g. when the quantity has reached stock.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.quantityStepperWidth,
      height: AppDimensions.optionChipHeight,
      decoration: BoxDecoration(
        color: AppColors.boxFill,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(icon: Icons.remove, onTap: onDecrement),
          Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          _StepButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: AppDimensions.iconSm,
          color: isEnabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

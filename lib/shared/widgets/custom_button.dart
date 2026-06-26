import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

/// Button visual style.
enum _ButtonVariant { primary, secondary, outline }

/// Themed call-to-action button.
///
/// Three variants via named constructors — [CustomButton.primary],
/// [CustomButton.secondary], [CustomButton.outline]. Shows a spinner and
/// blocks taps while [isLoading]; pass `onPressed: null` to disable. Each
/// variant supplies sensible theme colors and an [AppDimensions.radiusMd]
/// corner, but [backgroundColor], [foregroundColor], and [borderRadius] can
/// override them per call site (overrides apply only while enabled).
///
/// ```dart
/// CustomButton.primary(
///   label: 'Add to cart',
///   isLoading: adding,
///   onPressed: addToCart,
/// );
///
/// // White pill with dark text, fully rounded (e.g. over a banner photo).
/// CustomButton.secondary(
///   label: 'Shop Now',
///   backgroundColor: AppColors.white,
///   foregroundColor: AppColors.textPrimary,
///   borderRadius: AppDimensions.buttonHeight / 2,
///   onPressed: shop,
/// );
/// ```
class CustomButton extends StatelessWidget {
  /// Filled brand-primary button (default CTA).
  const CustomButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  }) : _variant = _ButtonVariant.primary;

  /// Filled secondary-brand button.
  const CustomButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  }) : _variant = _ButtonVariant.secondary;

  /// Outlined button with a transparent fill.
  const CustomButton.outline({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  }) : _variant = _ButtonVariant.outline;

  /// Button label.
  final String label;

  /// Tap handler. `null` disables the button.
  final VoidCallback? onPressed;

  /// Replaces the label with a spinner and blocks taps while `true`.
  final bool isLoading;

  /// Optional icon before the label.
  final Widget? leadingIcon;

  /// Optional icon after the label.
  final Widget? trailingIcon;

  /// Fixed width. Defaults to full available width.
  final double? width;

  /// Button height.
  final double height;

  /// Overrides the variant's fill (enabled state only).
  final Color? backgroundColor;

  /// Overrides the variant's label/icon color (enabled state only).
  final Color? foregroundColor;

  /// Corner radius. Defaults to [AppDimensions.radiusMd].
  final double? borderRadius;

  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    // Overrides win over variant defaults, but only while enabled — disabled
    // buttons keep their muted styling for a consistent affordance.
    final fillColor = isEnabled
        ? (backgroundColor ?? _backgroundColor(isEnabled))
        : _backgroundColor(isEnabled);
    final labelColor = isEnabled
        ? (foregroundColor ?? _foregroundColor(isEnabled))
        : _foregroundColor(isEnabled);
    final borderColor = _borderColor(isEnabled);
    final radius = BorderRadius.all(
      Radius.circular(borderRadius ?? AppDimensions.radiusMd),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: fillColor,
        borderRadius: radius,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: borderColor != null
                  ? Border.all(color: borderColor)
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: AppDimensions.iconMd,
                      height: AppDimensions.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: _spinnerStroke,
                        valueColor: AlwaysStoppedAnimation<Color>(labelColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leadingIcon != null) ...[
                          leadingIcon!,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: labelColor),
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          trailingIcon!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(bool isEnabled) {
    if (!isEnabled) {
      return _variant == _ButtonVariant.outline
          ? AppColors.white
          : AppColors.disabled;
    }
    return switch (_variant) {
      _ButtonVariant.primary => AppColors.primary,
      _ButtonVariant.secondary => AppColors.secondary,
      _ButtonVariant.outline => AppColors.white,
    };
  }

  Color _foregroundColor(bool isEnabled) {
    if (!isEnabled) return AppColors.textTertiary;
    return switch (_variant) {
      _ButtonVariant.primary || _ButtonVariant.secondary => AppColors.white,
      _ButtonVariant.outline => AppColors.primary,
    };
  }

  Color? _borderColor(bool isEnabled) {
    if (_variant != _ButtonVariant.outline) return null;
    return isEnabled ? AppColors.primary : AppColors.border;
  }
}

/// Stroke width of the in-button loading spinner.
const double _spinnerStroke = 2.5;

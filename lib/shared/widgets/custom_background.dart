import 'package:flutter/material.dart';
import 'package:shopify_app/core/theme/app_colors.dart';
import 'package:shopify_app/core/theme/app_spacing.dart';

class CustomBackground extends StatelessWidget {
  const CustomBackground({
    required this.child,
    super.key,
    this.showAppBar = true,
    this.showBackButton = true,
    this.applyBottomInset = true,
    this.backgroundColor,
    this.appBarColor,
    this.horizontalPadding = AppSpacing.md,
    this.contentTopPadding = AppSpacing.md,
    this.title,
    this.titleColor,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.appBarHeight = kToolbarHeight,
    this.showAppBarShadow = false,
    this.backIconColor,
  });

  /// Page content rendered below the app bar.
  final Widget child;

  /// Whether the inline app bar is rendered.
  final bool showAppBar;

  /// Whether the default back button is shown (ignored when [leading] is set).
  final bool showBackButton;

  /// Pads the content bottom by the system inset (gesture / nav bar).
  final bool applyBottomInset;

  /// Background fill. Defaults to [AppColors.background].
  final Color? backgroundColor;

  /// App bar fill. Defaults to [AppColors.surface].
  final Color? appBarColor;

  /// Horizontal padding applied to [child].
  final double horizontalPadding;

  /// Top padding applied to [child].
  final double contentTopPadding;

  /// Optional app bar title.
  final String? title;

  /// Title color override. Defaults to [AppColors.textPrimary].
  final Color? titleColor;

  /// Back action override. Defaults to `Navigator.maybePop`.
  final VoidCallback? onBackPressed;

  /// Replaces the default back button entirely.
  final Widget? leading;

  /// Trailing app bar actions.
  final List<Widget>? actions;

  /// App bar content height (excludes the top safe-area inset).
  final double appBarHeight;

  /// Draws a subtle drop shadow under the app bar.
  final bool showAppBarShadow;

  /// Back icon color override. Defaults to [AppColors.textPrimary].
  final Color? backIconColor;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      color: backgroundColor ?? AppColors.background,
      child: Column(
        children: [
          if (showAppBar)
            _AppBar(
              topInset: topInset,
              height: appBarHeight,
              backgroundColor: appBarColor ?? AppColors.surface,
              showShadow: showAppBarShadow,
              showBackButton: showBackButton,
              leading: leading,
              onBackPressed: onBackPressed,
              backIconColor: backIconColor,
              title: title,
              titleColor: titleColor,
              actions: actions,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                contentTopPadding,
                horizontalPadding,
                applyBottomInset ? bottomInset : 0,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline app bar used by [CustomBackground].
class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.topInset,
    required this.height,
    required this.backgroundColor,
    required this.showShadow,
    required this.showBackButton,
    required this.leading,
    required this.onBackPressed,
    required this.backIconColor,
    required this.title,
    required this.titleColor,
    required this.actions,
  });

  final double topInset;
  final double height;
  final Color? backgroundColor;
  final bool showShadow;
  final bool showBackButton;
  final Widget? leading;
  final VoidCallback? onBackPressed;
  final Color? backIconColor;
  final String? title;
  final Color? titleColor;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: topInset + height,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: AppSpacing.xs,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          SizedBox(height: topInset),
          SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  if (showBackButton)
                    leading ??
                        CustomBackButton(
                          color: backIconColor,
                          onPressed: onBackPressed,
                        ),
                  if (showBackButton && title != null)
                    const SizedBox(width: AppSpacing.md),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: titleColor ?? AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (actions != null)
                    Row(mainAxisSize: MainAxisSize.min, children: actions!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Leading back button for [CustomBackground].
///
/// Pops the current route via [onPressed] (defaults to `Navigator.maybePop`).
class CustomBackButton extends StatelessWidget {
  const CustomBackButton({
    super.key,
    this.title,
    this.onPressed,
    this.iconSize = AppDimensions.iconMd,
    this.color,
  });

  /// Optional label rendered next to the icon.
  final String? title;

  /// Tap handler. Defaults to popping the current route.
  final VoidCallback? onPressed;

  /// Icon dimensions.
  final double iconSize;

  /// Icon and label color. Defaults to [AppColors.textPrimary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? AppColors.textPrimary;
    return InkWell(
      splashColor: Colors.transparent,
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_ios_new, size: iconSize, color: tint),
            if (title != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(color: tint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
